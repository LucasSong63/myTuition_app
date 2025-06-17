// lib/features/attendance/presentation/pages/edit_attendance_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/features/attendance/data/models/attendance_model.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/widgets/loading_overlay.dart';
import '../../domain/entities/attendance.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class EditAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;
  final DateTime attendanceDate;
  final List<Attendance> existingRecords;
  final String? sessionId; // Add session ID parameter

  const EditAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.attendanceDate,
    required this.existingRecords,
    this.sessionId, // Optional session ID
  }) : super(key: key);

  @override
  State<EditAttendancePage> createState() => _EditAttendancePageState();
}

class _EditAttendancePageState extends State<EditAttendancePage> {
  // Track current and original attendance states
  Map<String, AttendanceStatus> _currentAttendances = {};
  Map<String, AttendanceStatus> _originalAttendances = {};
  Map<String, String> _currentRemarks = {};
  Map<String, String> _originalRemarks = {};

  // UI state
  List<Map<String, dynamic>> _enrolledStudents = [];
  Map<String, dynamic>? _scheduleInfo;
  bool _canEdit = false;
  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Debug logging to help track data flow
    print('EditAttendancePage initialized:');
    print('  Course: ${widget.courseName}');
    print('  Date: ${DateFormat('yyyy-MM-dd').format(widget.attendanceDate)}');
    print('  Session ID: ${widget.sessionId}');
    print('  Records count: ${widget.existingRecords.length}');
    print(
        '  Records: ${widget.existingRecords.map((r) => '${r.studentId}:${r.status}').join(', ')}');

    _initializeAttendanceData();
    _loadEditData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAttendanceData() {
    // Initialize attendance maps from existing records
    for (var record in widget.existingRecords) {
      _originalAttendances[record.studentId] = record.status;
      _currentAttendances[record.studentId] = record.status;

      if (record.remarks != null && record.remarks!.isNotEmpty) {
        // Filter out schedule metadata from remarks
        if (!record.remarks!.contains('_scheduleMeta')) {
          _originalRemarks[record.studentId] = record.remarks!;
          _currentRemarks[record.studentId] = record.remarks!;
        }
      }
    }
  }

  void _loadEditData() {
    // Extract session info from the first record of existing records
    if (widget.existingRecords.isNotEmpty) {
      _scheduleInfo =
          _extractScheduleInfoFromRecord(widget.existingRecords.first);

      // ✅ DEBUG: Print the complete metadata to see what's available
      final firstRecord = widget.existingRecords.first;
      print('🔍 DEBUG - Complete Record Data:');
      print('  Record ID: ${firstRecord.id}');
      print('  Student ID: ${firstRecord.studentId}');
      print('  Status: ${firstRecord.status}');
      print('  Date: ${firstRecord.date}');
      print('  Remarks: ${firstRecord.remarks}');

      if (firstRecord is AttendanceModel) {
        print('🔍 DEBUG - Schedule Metadata:');
        print('  Complete metadata: ${firstRecord.scheduleMetadata}');

        if (firstRecord.scheduleMetadata != null) {
          final metadata = firstRecord.scheduleMetadata!;
          print('  scheduleId: ${metadata['scheduleId']}');
          print('  scheduleDay: ${metadata['scheduleDay']}');
          print('  scheduleLocation: ${metadata['scheduleLocation']}');
          print('  scheduleType: ${metadata['scheduleType']}');
          print('  scheduleStartTime: ${metadata['scheduleStartTime']}');
          print('  scheduleEndTime: ${metadata['scheduleEndTime']}');

          // Test time parsing
          if (metadata['scheduleStartTime'] != null) {
            try {
              final startTime =
                  DateTime.parse(metadata['scheduleStartTime'] as String);
              print('  ✅ Start time parsed successfully: $startTime');
            } catch (e) {
              print('  ❌ Error parsing start time: $e');
            }
          } else {
            print('  ⚠️ scheduleStartTime is null');
          }
        } else {
          print('  ⚠️ scheduleMetadata is null');
        }
      } else {
        print('  ⚠️ Record is not AttendanceModel');
      }

      print('🔍 DEBUG - Extracted _scheduleInfo:');
      print('  $_scheduleInfo');

      // If sessionId is provided, validate it matches the records
      if (widget.sessionId != null && _scheduleInfo != null) {
        final expectedSessionId = _scheduleInfo!['scheduleId'];
        if (expectedSessionId != widget.sessionId) {
          print(
              'Warning: Session ID mismatch - Expected: $expectedSessionId, Got: ${widget.sessionId}');
        }
      }
    }

    // Load attendance for edit with validation
    context.read<AttendanceBloc>().add(
          LoadAttendanceForEditEvent(
            courseId: widget.courseId,
            attendanceDate: widget.attendanceDate,
            existingRecords: widget.existingRecords,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Attendance',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, size: 6.w),
            onPressed: _showEditInfo,
            tooltip: 'Edit Rules',
          ),
        ],
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceLoadedForEdit) {
            setState(() {
              _enrolledStudents = state.enrolledStudents;

              // ✅ FIX: Only update _scheduleInfo if it's empty or if the new one has more complete data
              if (_scheduleInfo == null ||
                  (state.scheduleInfo != null &&
                      _scheduleInfo!['scheduleTime'] == 'Session Time' &&
                      state.scheduleInfo!['scheduleTime'] != 'Session Time')) {
                _scheduleInfo = state.scheduleInfo;
                print('🔄 Updated _scheduleInfo from BLoC: $_scheduleInfo');
              } else {
                print(
                    '🔒 Keeping existing _scheduleInfo with correct time: ${_scheduleInfo!['scheduleTime']}');
              }

              _canEdit = state.canEdit;
              _isLoading = false;
            });
          } else if (state is EditPermissionValidated && !state.canEdit) {
            _showEditRestrictedDialog(state.reason, state.daysOld);
          } else if (state is AttendanceRecordsUpdated) {
            _showUpdateSuccessDialog(state);
          } else if (state is AttendanceEditPreparing) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is AttendanceError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Preparing attendance for editing...',
          child: CustomScrollView(
            slivers: [
              // Header info
              SliverToBoxAdapter(child: _buildHeaderInfo()),

              // Session info
              SliverToBoxAdapter(child: _buildSessionInfo()),

              // Edit controls
              if (_canEdit) ...[
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildSearchBar()),
              ],

              // Students list
              SliverToBoxAdapter(child: _buildStudentsList()),

              // Save button
              if (_canEdit && _hasChanges())
                SliverToBoxAdapter(child: _buildSaveButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryBlue, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy')
                          .format(widget.attendanceDate),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: _canEdit ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  _canEdit ? 'EDITABLE' : 'READ ONLY',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    if (_scheduleInfo == null) {
      return Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning, size: 5.w),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Session information not available',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Use the extracted values directly from _scheduleInfo
    final sessionDay = _scheduleInfo!['scheduleDay'] ?? 'Unknown Day';
    final sessionLocation =
        _scheduleInfo!['scheduleLocation'] ?? 'Unknown Location';
    final sessionTime = _scheduleInfo!['scheduleTime'] ??
        'Session Time'; // ✅ Use extracted scheduleTime
    final sessionType = _scheduleInfo!['scheduleType'] ?? 'regular';

    print('🔍 Building Session Info UI:');
    print('  Day: $sessionDay');
    print('  Time: $sessionTime'); // ✅ This should show "10:00 PM - 1:30 AM"
    print('  Location: $sessionLocation');
    print('  Type: $sessionType');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primaryBlue, size: 5.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Editing Session',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (sessionType == 'replacement')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    'REPLACEMENT',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.w),
          _buildInfoRow(Icons.calendar_today, 'Day', sessionDay),
          _buildInfoRow(Icons.access_time, 'Time', sessionTime),
          // ✅ Will show "10:00 PM - 1:30 AM"
          _buildInfoRow(Icons.location_on, 'Location', sessionLocation),
          if (widget.sessionId != null)
            _buildInfoRow(Icons.fingerprint, 'Session ID', widget.sessionId!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.w),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMedium, size: 4.w),
          SizedBox(width: 3.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    if (!_canEdit) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 2.w),
          Wrap(
            spacing: 2.w,
            children: [
              _buildQuickActionButton('All Present', AppColors.success, () {
                setState(() {
                  for (var studentId in _currentAttendances.keys) {
                    _currentAttendances[studentId] = AttendanceStatus.present;
                  }
                });
              }),
              _buildQuickActionButton('All Absent', AppColors.error, () {
                setState(() {
                  for (var studentId in _currentAttendances.keys) {
                    _currentAttendances[studentId] = AttendanceStatus.absent;
                  }
                });
              }),
              _buildQuickActionButton('All Late', AppColors.warning, () {
                setState(() {
                  for (var studentId in _currentAttendances.keys) {
                    _currentAttendances[studentId] = AttendanceStatus.late;
                  }
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.sp),
      ),
    );
  }

  Widget _buildSearchBar() {
    if (!_canEdit) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildStudentsList() {
    final filteredStudents = _enrolledStudents.where((student) {
      if (_searchQuery.isEmpty) return true;
      final name = (student['name'] as String? ?? '').toLowerCase();
      final studentId = (student['studentId'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery) || studentId.contains(_searchQuery);
    }).toList();

    // Show only students that have existing attendance records
    final studentsWithAttendance = filteredStudents.where((student) {
      return _currentAttendances.containsKey(student['studentId']);
    }).toList();

    if (studentsWithAttendance.isEmpty) {
      return Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: Text(
            'No students found for this session',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textMedium,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Students (${studentsWithAttendance.length}):',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 2.w),
          ...studentsWithAttendance.map((student) {
            final studentId = student['studentId'] as String;
            final name = student['name'] as String? ?? 'Unknown Student';
            final currentStatus =
                _currentAttendances[studentId] ?? AttendanceStatus.absent;
            final originalStatus =
                _originalAttendances[studentId] ?? AttendanceStatus.absent;
            final hasChanged = currentStatus != originalStatus;

            return _buildStudentCard(
              studentId: studentId,
              name: name,
              currentStatus: currentStatus,
              hasChanged: hasChanged,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required String studentId,
    required String name,
    required AttendanceStatus currentStatus,
    required bool hasChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: hasChanged ? AppColors.warning.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: hasChanged ? AppColors.warning : Colors.grey.withOpacity(0.3),
          width: hasChanged ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'ID: $studentId',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasChanged)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    'CHANGED',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.w),

          // Attendance status buttons
          if (_canEdit) ...[
            Wrap(
              spacing: 2.w,
              children: AttendanceStatus.values.map((status) {
                final isSelected = currentStatus == status;
                return _buildStatusButton(
                  status: status,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentAttendances[studentId] = status;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 2.w),

            // Remarks field
            TextField(
              decoration: InputDecoration(
                hintText: 'Add remarks (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1.w),
                ),
                contentPadding: EdgeInsets.all(2.w),
              ),
              style: TextStyle(fontSize: 12.sp),
              maxLines: 1,
              onChanged: (value) {
                setState(() {
                  if (value.trim().isEmpty) {
                    _currentRemarks.remove(studentId);
                  } else {
                    _currentRemarks[studentId] = value.trim();
                  }
                });
              },
              controller: TextEditingController(
                text: _currentRemarks[studentId] ?? '',
              ),
            ),
          ] else ...[
            // Read-only status display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
              decoration: BoxDecoration(
                color: _getStatusColor(currentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(1.w),
                border: Border.all(color: _getStatusColor(currentStatus)),
              ),
              child: Text(
                _getStatusLabel(currentStatus),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _getStatusColor(currentStatus),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_currentRemarks[studentId] != null) ...[
              SizedBox(height: 1.w),
              Text(
                'Remarks: ${_currentRemarks[studentId]}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required AttendanceStatus status,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(1.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.excused:
        return AppColors.textMedium;
    }
  }

  String _getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  Widget _buildSaveButton() {
    return Container(
      margin: EdgeInsets.all(4.w),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
        ),
        child: Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _hasChanges() {
    // Check if any attendance status has changed
    for (var studentId in _currentAttendances.keys) {
      if (_currentAttendances[studentId] != _originalAttendances[studentId]) {
        return true;
      }
    }

    // Check if any remarks have changed
    for (var studentId in _currentRemarks.keys) {
      if (_currentRemarks[studentId] != _originalRemarks[studentId]) {
        return true;
      }
    }

    return false;
  }

  void _showConfirmationDialog() {
    final changes = <String>[];

    // Collect changes
    for (var studentId in _currentAttendances.keys) {
      final originalStatus = _originalAttendances[studentId];
      final currentStatus = _currentAttendances[studentId];

      if (originalStatus != currentStatus) {
        final studentName = _enrolledStudents.firstWhere(
            (s) => s['studentId'] == studentId,
            orElse: () => {'name': 'Unknown'})['name'];
        changes.add(
            '$studentName: ${_getStatusLabel(originalStatus!)} → ${_getStatusLabel(currentStatus!)}');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Changes',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to update attendance for ${changes.length} student(s):',
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 2.h),
              ...changes.map((change) => Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Text(
                      '• $change',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  )),
              SizedBox(height: 2.h),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text('Update', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _performUpdate() {
    context.read<AttendanceBloc>().add(
          UpdateAttendanceRecordsEvent(
            courseId: widget.courseId,
            attendanceDate: widget.attendanceDate,
            updatedAttendances: _currentAttendances,
            updatedRemarks: _currentRemarks.isNotEmpty ? _currentRemarks : null,
            originalAttendances: _originalAttendances,
          ),
        );
  }

  void _showUpdateSuccessDialog(AttendanceRecordsUpdated state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 6.w),
            SizedBox(width: 2.w),
            Text('Success!'),
          ],
        ),
        content: Text(
          'Attendance records have been updated successfully.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Return to manage attendance
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text('Done', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showEditRestrictedDialog(String reason, int daysOld) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.error, size: 6.w),
            SizedBox(width: 2.w),
            Text('Cannot Edit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2.w),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📅 Record Age: $daysOld days old',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '⏰ Edit Window: 7 days maximum',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '• You can still view the attendance data',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Return to manage attendance
            },
            child: Text('Back', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showEditInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Attendance Rules',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection('🕐 Time Restrictions:', [
                '• Records can only be edited within 7 days',
                '• After 7 days, records become read-only',
                '• This prevents accidental changes to old data',
              ]),
              SizedBox(height: 2.h),
              _buildInfoSection('✏️ What You Can Edit:', [
                '• Student attendance status (Present/Absent/Late/Excused)',
                '• Individual student remarks',
                '• Multiple students at once',
              ]),
              SizedBox(height: 2.h),
              _buildInfoSection('🔍 Change Tracking:', [
                '• All changes are highlighted in orange',
                '• Original → New status is shown',
                '• Confirmation dialog shows all changes',
                '• Changes are saved immediately after confirmation',
              ]),
              SizedBox(height: 2.h),
              _buildInfoSection('⚠️ Important Notes:', [
                '• Changes cannot be undone once saved',
                '• Session information cannot be changed',
                '• Only attendance status and remarks can be edited',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> points) {
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
        SizedBox(height: 1.h),
        ...points.map((point) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Text(
                point,
                style: TextStyle(fontSize: 13.sp),
              ),
            )),
      ],
    );
  }

  Map<String, dynamic>? _extractScheduleInfoFromRecord(Attendance record) {
    if (record is AttendanceModel && record.scheduleMetadata != null) {
      final metadata = record.scheduleMetadata!;

      print('🔍 Extracting schedule info from metadata: $metadata');

      // Extract time information - IGNORE the wrong dates, use only TIME
      String timeDisplay = 'Session Time';

      try {
        if (metadata['scheduleStartTime'] != null &&
            metadata['scheduleEndTime'] != null) {
          final startDateTime =
              DateTime.parse(metadata['scheduleStartTime'] as String);
          final endDateTime =
              DateTime.parse(metadata['scheduleEndTime'] as String);

          print('📅 Original start time: $startDateTime');
          print('📅 Original end time: $endDateTime');

          // ✅ Extract ONLY the time components, ignore the wrong date
          final startHour = startDateTime.hour;
          final startMinute = startDateTime.minute;
          final endHour = endDateTime.hour;
          final endMinute = endDateTime.minute;

          // Create new DateTime objects with correct date but original time
          final correctDate = record.date; // Use the attendance date
          final correctedStartTime = DateTime(
            correctDate.year,
            correctDate.month,
            correctDate.day,
            startHour,
            startMinute,
          );

          // Handle end time that might be next day (like 1:30 AM)
          DateTime correctedEndTime;
          if (endHour < startHour) {
            // End time is next day (e.g., starts 10 PM, ends 1:30 AM)
            correctedEndTime = DateTime(
              correctDate.year,
              correctDate.month,
              correctDate.day + 1, // Next day
              endHour,
              endMinute,
            );
          } else {
            // Same day
            correctedEndTime = DateTime(
              correctDate.year,
              correctDate.month,
              correctDate.day,
              endHour,
              endMinute,
            );
          }

          timeDisplay = _formatTimeRange(correctedStartTime, correctedEndTime);
          print('✅ Corrected time display: $timeDisplay');

          // Return the metadata with corrected time info
          return Map<String, dynamic>.from(metadata)
            ..addAll({
              'scheduleTime': timeDisplay,
              'scheduleStartTime': correctedStartTime.toIso8601String(),
              'scheduleEndTime': correctedEndTime.toIso8601String(),
            });
        }
      } catch (e) {
        print('❌ Error parsing schedule times: $e');
      }

      // Fallback: use metadata as-is but with default time
      return Map<String, dynamic>.from(metadata)
        ..addAll({
          'scheduleTime': 'Session Time (Parse Error)',
        });
    }

    // Enhanced fallback for records without proper metadata
    print('Warning: No schedule metadata found for record ${record.id}');

    return {
      'scheduleId': 'unknown',
      'scheduleDay': DateFormat('EEEE').format(record.date),
      'scheduleLocation': 'Classroom A',
      'scheduleType': 'regular',
      'scheduleTime': 'Session Time (No Metadata)',
      'scheduleStartTime': record.date.toIso8601String(),
      'scheduleEndTime': record.date.add(Duration(hours: 1)).toIso8601String(),
    };
  }

// Helper method for consistent time formatting
  String _formatTimeRange(DateTime startTime, DateTime endTime) {
    String formatTime(DateTime dateTime) {
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute $period';
    }

    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }
}
