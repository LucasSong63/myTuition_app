import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/utils/student_id_validator.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';
import 'package:mytuition/features/attendance/presentation/widgets/qr_scanner_overlay.dart';
import 'package:mytuition/features/attendance/presentation/widgets/scanned_student_card.dart';

class QRScannerPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> enrolledStudents;
  final Map<String, AttendanceStatus> initialAttendances;

  const QRScannerPage({
    Key? key,
    required this.enrolledStudents,
    required this.initialAttendances,
  }) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();

  // Scanning animation
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  // Tracking scanned students
  final Map<String, AttendanceStatus> _scannedStudents = {};
  String? _lastScannedId;
  String? _lastErrorMessage;
  Timer? _feedbackTimer;
  bool _isProcessing = false;
  bool _showingError = false;

  // Flashlight state
  bool _isTorchOn = false;

  // Statistics
  int _totalScanned = 0;
  int _successfulScans = 0;
  int _errorScans = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with existing attendances
    _scannedStudents.addAll(widget.initialAttendances);
    _totalScanned = widget.initialAttendances.length;
    _successfulScans = widget.initialAttendances.length;

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Student QR Codes'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetectCode,
          ),

          // Scanning overlay with animation
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: QRScannerOverlay(
                  borderColor:
                      _showingError ? AppColors.error : AppColors.primaryBlue,
                  scanLineColor:
                      _showingError ? AppColors.error : AppColors.accentTeal,
                  scanLinePosition: _scanLineAnimation.value,
                  showScanLine: !_isProcessing,
                ),
                child: Container(),
              );
            },
          ),

          // Scanning instructions overlay
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black.withOpacity(0.7),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Position student QR code in the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scanned: $_successfulScans | Errors: $_errorScans',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Last scanned student feedback (success)
          if (_lastScannedId != null && !_showingError)
            _buildLastScannedFeedback(),

          // Error feedback
          if (_lastErrorMessage != null && _showingError) _buildErrorFeedback(),

          // Scanned students list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scanned Students (${_scannedStudents.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Success: $_successfulScans | Errors: $_errorScans',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset'),
                              onPressed: _resetScannedStudents,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Students list
                  Expanded(
                    child: _scannedStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No students scanned yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Point camera at student QR codes',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: _scannedStudents.entries.map((entry) {
                              final studentId = entry.key;
                              final studentData =
                                  widget.enrolledStudents[studentId];
                              final studentName =
                                  studentData?['name'] as String?;

                              return ScannedStudentCard(
                                studentId: studentId,
                                studentName: studentName,
                                status: entry.value,
                                onDismiss: () =>
                                    _removeScannedStudent(studentId),
                                onChangeStatus: () =>
                                    _cycleStudentStatus(studentId),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _completeScanning,
        label: Text('Done (${_scannedStudents.length})'),
        icon: const Icon(Icons.check),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  void _onDetectCode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        _processScannedCode(code);
        break;
      }
    }
  }

  ValidationResult _validateStudentId(String code) {
    // Basic format check
    if (!StudentIdValidator.isValidFormat(code)) {
      return ValidationResult.invalid(
        'Invalid ID format\nExpected: MT[YY]-[NNNN]',
      );
    }

    // Year range check
    if (!StudentIdValidator.isValidWithYearCheck(code,
        minYear: 2020, maxYear: 2030)) {
      final year = StudentIdValidator.extractYear(code);
      return ValidationResult.invalid(
        'Invalid year batch: $year\nExpected: 2020-2030',
      );
    }

    // Enrollment check
    final enrolledStudentsList = widget.enrolledStudents.values.toList();
    if (!StudentIdValidator.existsInList(code, enrolledStudentsList)) {
      return ValidationResult.invalid(
        'Student not enrolled\nin this course',
      );
    }

    // Check if already scanned
    if (_scannedStudents.containsKey(code)) {
      return ValidationResult.invalid(
        'Student already scanned\nTap to change status',
      );
    }

    return ValidationResult.valid(code);
  }

  Future<void> _processScannedCode(String studentId) async {
    setState(() {
      _isProcessing = true;
      _showingError = false;
      _lastScannedId = null;
      _lastErrorMessage = null;
    });

    // Perform detailed validation
    final validationResult = _validateStudentId(studentId);
    _totalScanned++;

    if (!validationResult.isValid) {
      // Handle error case
      setState(() {
        _lastErrorMessage = validationResult.errorMessage;
        _showingError = true;
        _errorScans++;
      });

      // Vibrate for error feedback
      HapticFeedback.lightImpact();

      // Show error for longer duration
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _lastErrorMessage = null;
            _showingError = false;
            _isProcessing = false;
          });
        }
      });

      return;
    }

    // Handle success case
    setState(() {
      _lastScannedId = studentId;
      _showingError = false;
      _successfulScans++;

      // Set status to present for new scan
      _scannedStudents[studentId] = AttendanceStatus.present;
    });

    // Vibrate for success feedback
    HapticFeedback.mediumImpact();

    // Cancel any existing feedback timer
    _feedbackTimer?.cancel();

    // Set timer to clear feedback and allow next scan
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _lastScannedId = null;
          _isProcessing = false;
        });
      }
    });
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _resetScannedStudents() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Scanned Students'),
        content: const Text(
            'Are you sure you want to clear all scanned students? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scannedStudents.clear();
                _totalScanned = 0;
                _successfulScans = 0;
                _errorScans = 0;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All scanned students cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _removeScannedStudent(String studentId) {
    setState(() {
      _scannedStudents.remove(studentId);
      if (_successfulScans > 0) _successfulScans--;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $studentId from scan list'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _scannedStudents[studentId] = AttendanceStatus.present;
              _successfulScans++;
            });
          },
        ),
      ),
    );
  }

  void _cycleStudentStatus(String studentId) {
    final currentStatus =
        _scannedStudents[studentId] ?? AttendanceStatus.present;

    AttendanceStatus nextStatus;
    switch (currentStatus) {
      case AttendanceStatus.present:
        nextStatus = AttendanceStatus.late;
        break;
      case AttendanceStatus.late:
        nextStatus = AttendanceStatus.excused;
        break;
      case AttendanceStatus.excused:
        nextStatus = AttendanceStatus.absent;
        break;
      case AttendanceStatus.absent:
        nextStatus = AttendanceStatus.present;
        break;
    }

    setState(() {
      _scannedStudents[studentId] = nextStatus;
    });

    // Light haptic feedback for status change
    HapticFeedback.selectionClick();
  }

  void _completeScanning() {
    if (_scannedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students scanned yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, _scannedStudents);
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanner Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📱 Scanning:'),
              Text('• Position student QR code in the square frame'),
              Text('• Hold device steady until confirmation'),
              Text('• Green feedback = successful scan'),
              Text('• Red feedback = error (check message)'),
              SizedBox(height: 12),
              Text('✨ Features:'),
              Text('• Tap flashlight icon to toggle light'),
              Text('• View scanned students in bottom panel'),
              Text('• Tap student cards to change status'),
              Text('• Tap "Reset" to clear all scans'),
              SizedBox(height: 12),
              Text('🎯 Expected QR Format:'),
              Text('• MT[YY]-[NNNN] (e.g., MT25-0001)'),
              Text('• Must be enrolled in this course'),
              Text('• Year range: 2020-2030'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScannedFeedback() {
    final studentId = _lastScannedId!;
    final studentData = widget.enrolledStudents[studentId];
    final studentName = studentData?['name'] as String? ?? 'Student';
    final status = _scannedStudents[studentId] ?? AttendanceStatus.present;
    final year = StudentIdValidator.extractYear(studentId);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case AttendanceStatus.present:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Marked Present';
        break;
      case AttendanceStatus.late:
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
        statusText = 'Marked Late';
        break;
      case AttendanceStatus.excused:
        statusColor = AppColors.accentTeal;
        statusIcon = Icons.assignment_late;
        statusText = 'Marked Excused';
        break;
      case AttendanceStatus.absent:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Marked Absent';
        break;
    }

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Card(
        color: statusColor,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$studentId${year != null ? ' (Class of $year)' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorFeedback() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Card(
        color: AppColors.error,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.error, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _lastErrorMessage ?? 'Unknown error',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Try scanning again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
