// lib/features/attendance/presentation/pages/qr_scanner_page.dart
// SCROLLABLE VERSION - QR scanner above, student records below

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/utils/student_id_validator.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';
import 'package:sizer/sizer.dart';

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

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  // Student records (attendance map)
  final Map<String, AttendanceStatus> _studentRecords = {};

  // Scan feedback
  String? _lastScannedId;
  String? _lastErrorMessage;
  Timer? _feedbackTimer;
  bool _isProcessing = false;
  bool _showingError = false;
  bool _isTorchOn = false;

  // Statistics for actual scan attempts vs student records
  int _totalScanAttempts = 0;
  int _successfulScanAttempts = 0;
  int _errorScanAttempts = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with existing attendances
    _studentRecords.addAll(widget.initialAttendances);

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
        title: Text(
          'Scan Student QR Codes',
          style: TextStyle(fontSize: 18.sp),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              size: 6.w,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              size: 6.w,
            ),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // QR Scanner Section
          SliverToBoxAdapter(
            child: _buildQRScannerSection(),
          ),

          // Student Records Section Header
          SliverToBoxAdapter(
            child: _buildStudentRecordsHeader(),
          ),

          // Student Records List
          _studentRecords.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : _buildStudentRecordsList(),

          // Done Button
          SliverToBoxAdapter(
            child: _buildDoneButton(),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 4.h),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScannerSection() {
    return Container(
      height: 50.h, // 50% of screen height for QR scanner
      child: Column(
        children: [
          // Info panel
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Position student QR code in the frame',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Scan Attempts: $_totalScanAttempts | Success: $_successfulScanAttempts | Errors: $_errorScanAttempts',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Camera scanner
          Expanded(
            child: Stack(
              children: [
                // Camera feed
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onQRCodeDetected,
                ),

                // Scanning overlay
                _buildScannerOverlay(),

                // Feedback overlay
                if (_lastScannedId != null || _showingError)
                  _buildFeedbackOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return CustomPaint(
      painter: QRScannerOverlayPainter(
        animation: _scanLineAnimation,
        isScanning: !_isProcessing,
      ),
      child: Container(),
    );
  }

  Widget _buildFeedbackOverlay() {
    if (_showingError && _lastErrorMessage != null) {
      return _buildErrorFeedback();
    } else if (_lastScannedId != null) {
      return _buildSuccessFeedback();
    }
    return const SizedBox.shrink();
  }

  Widget _buildErrorFeedback() {
    return Container(
      margin: EdgeInsets.all(4.w),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.95),
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'Scan Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _lastErrorMessage!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _lastErrorMessage = null;
                    _showingError = false;
                    _isProcessing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.error,
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                ),
                child: Text(
                  'Try again',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessFeedback() {
    final studentId = _lastScannedId!;
    final studentData = widget.enrolledStudents[studentId];
    final studentName = studentData?['name'] as String? ?? 'Student';
    final status = _studentRecords[studentId] ?? AttendanceStatus.present;

    return Container(
      margin: EdgeInsets.all(4.w),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.95),
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'Scan Successful',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                studentName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '$studentId - ${_getStatusText(status)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRecordsHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Student Records (${_studentRecords.length})',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _studentRecords.isNotEmpty ? _resetStudentRecords : null,
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 30.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 12.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No student records yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Scan QR codes or manually update attendance',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRecordsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final studentId = _studentRecords.keys.elementAt(index);
          final status = _studentRecords[studentId]!;
          final studentData = widget.enrolledStudents[studentId];
          final studentName =
              studentData?['name'] as String? ?? 'Unknown Student';

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: _buildStudentCard(
              studentId: studentId,
              studentName: studentName,
              status: status,
            ),
          );
        },
        childCount: _studentRecords.length,
      ),
    );
  }

  Widget _buildStudentCard({
    required String studentId,
    required String studentName,
    required AttendanceStatus status,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            // Student avatar
            CircleAvatar(
              radius: 6.w,
              backgroundColor: _getStatusColor(status),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 3.w),

            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    studentId,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Status button
            ElevatedButton(
              onPressed: () => _cycleStudentStatus(studentId),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(status),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(width: 2.w),

            // Remove button
            IconButton(
              onPressed: () => _removeStudentRecord(studentId),
              icon: Icon(
                Icons.close,
                color: AppColors.error,
                size: 5.w,
              ),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      child: ElevatedButton(
        onPressed: _studentRecords.isNotEmpty ? _completeScanning : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _studentRecords.isNotEmpty ? AppColors.success : Colors.grey,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              'Done (${_studentRecords.length})',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? scannedData = barcodes.first.rawValue;
    if (scannedData == null || scannedData.isEmpty) return;

    _processScannedCode(scannedData);
  }

  void _processScannedCode(String scannedCode) {
    setState(() {
      _isProcessing = true;
      _lastErrorMessage = null;
      _showingError = false;
      _totalScanAttempts++;
    });

    // Validate student ID format
    if (!StudentIdValidator.isValidFormat(scannedCode)) {
      _handleScanError('Invalid QR code format. Expected: MT[YY]-[NNNN]');
      return;
    }

    final studentId = scannedCode.trim().toUpperCase();

    // Check if student is enrolled in this course
    if (!widget.enrolledStudents.containsKey(studentId)) {
      _handleScanError('Student $studentId is not enrolled in this course');
      return;
    }

    // Simplified logic based on requirements
    final currentStatus = _studentRecords[studentId];

    if (currentStatus == null) {
      // Student not in records - add as present
      setState(() {
        _lastScannedId = studentId;
        _showingError = false;
        _successfulScanAttempts++;
        _studentRecords[studentId] = AttendanceStatus.present;
      });
      _showSuccessMessage('Student marked as Present');
    } else if (currentStatus == AttendanceStatus.absent) {
      // Student is absent - change to present
      setState(() {
        _lastScannedId = studentId;
        _showingError = false;
        _successfulScanAttempts++;
        _studentRecords[studentId] = AttendanceStatus.present;
      });
      _showSuccessMessage('Status changed from Absent to Present');
    } else {
      // If student is Present/Late/Excused, just confirm status
      setState(() {
        _lastScannedId = studentId;
        _showingError = false;
        _successfulScanAttempts++;
      });
      _showSuccessMessage('${_getStatusText(currentStatus)} status confirmed');
    }

    // Success feedback
    HapticFeedback.mediumImpact();
    _startFeedbackTimer();
  }

  void _handleScanError(String message) {
    setState(() {
      _lastErrorMessage = message;
      _showingError = true;
      _errorScanAttempts++;
    });

    HapticFeedback.heavyImpact();

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
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14.sp),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _startFeedbackTimer() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _lastScannedId = null;
          _isProcessing = false;
        });
      }
    });
  }

  void _cycleStudentStatus(String studentId) {
    final currentStatus =
        _studentRecords[studentId] ?? AttendanceStatus.present;

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
      _studentRecords[studentId] = nextStatus;
    });

    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status changed to ${_getStatusText(nextStatus)}',
          style: TextStyle(fontSize: 14.sp),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeStudentRecord(String studentId) {
    setState(() {
      _studentRecords.remove(studentId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed $studentId from records',
          style: TextStyle(fontSize: 14.sp),
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _studentRecords[studentId] = AttendanceStatus.present;
            });
          },
        ),
      ),
    );
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _resetStudentRecords() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Student Records',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Text(
          'Are you sure you want to clear all student records? This action cannot be undone.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _studentRecords.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All student records cleared',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Reset',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _completeScanning() {
    if (_studentRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No student records yet',
            style: TextStyle(fontSize: 14.sp),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, _studentRecords);
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'QR Code Scanner Instructions',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionSection('📱 Scanning:', [
                '• Position student QR code in the frame',
                '• Hold device steady until confirmation',
                '• Green feedback = successful scan',
                '• Red feedback = error (check message)',
              ]),
              SizedBox(height: 2.h),
              _buildInstructionSection('🔄 Smart Logic:', [
                '• Scanning absent students → changes to present',
                '• Scanning new students → adds as present',
                '• Scanning present/late/excused → confirms status',
                '• Manual status cycling available via buttons',
              ]),
              SizedBox(height: 2.h),
              _buildInstructionSection('✨ Features:', [
                '• Scroll down to view student records',
                '• Tap student cards to change status',
                '• Remove students from records',
                '• Reset all records if needed',
              ]),
              SizedBox(height: 2.h),
              _buildInstructionSection('🎯 Expected QR Format:', [
                '• MT[YY]-[NNNN] (e.g., MT25-0001)',
                '• Must be enrolled in this course',
                '• Year range: 2020-2030',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...points
            .map((point) => Text(
                  point,
                  style: TextStyle(fontSize: 13.sp),
                ))
            .toList(),
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }
}

// QR Scanner Overlay Painter
class QRScannerOverlayPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isScanning;

  QRScannerOverlayPainter({
    required this.animation,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final scannerSize = size.width * 0.7;
    final left = (size.width - scannerSize) / 2;
    final top = (size.height - scannerSize) / 2;
    final cornerLength = scannerSize * 0.1;

    // Draw corners
    final corners = [
      // Top-left
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      // Top-right
      Path()
        ..moveTo(left + scannerSize - cornerLength, top)
        ..lineTo(left + scannerSize, top)
        ..lineTo(left + scannerSize, top + cornerLength),
      // Bottom-left
      Path()
        ..moveTo(left, top + scannerSize - cornerLength)
        ..lineTo(left, top + scannerSize)
        ..lineTo(left + cornerLength, top + scannerSize),
      // Bottom-right
      Path()
        ..moveTo(left + scannerSize - cornerLength, top + scannerSize)
        ..lineTo(left + scannerSize, top + scannerSize)
        ..lineTo(left + scannerSize, top + scannerSize - cornerLength),
    ];

    for (final corner in corners) {
      canvas.drawPath(corner, paint);
    }

    // Draw scanning line animation
    if (isScanning) {
      final scanLinePaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0;

      final scanLineY = top + (scannerSize * animation.value);
      canvas.drawLine(
        Offset(left + 20, scanLineY),
        Offset(left + scannerSize - 20, scanLineY),
        scanLinePaint,
      );
    }

    // Draw overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    // Top overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, top),
      overlayPaint,
    );

    // Bottom overlay
    canvas.drawRect(
      Rect.fromLTWH(
          0, top + scannerSize, size.width, size.height - (top + scannerSize)),
      overlayPaint,
    );

    // Left overlay
    canvas.drawRect(
      Rect.fromLTWH(0, top, left, scannerSize),
      overlayPaint,
    );

    // Right overlay
    canvas.drawRect(
      Rect.fromLTWH(left + scannerSize, top, size.width - (left + scannerSize),
          scannerSize),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
