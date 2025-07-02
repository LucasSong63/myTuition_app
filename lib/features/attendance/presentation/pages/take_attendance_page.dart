// lib/features/attendance/presentation/pages/take_attendance_page.dart
// IMPROVED VERSION with UI refinements

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:mytuition/features/attendance/domain/utils/schedule_date_utils.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/widgets/loading_overlay.dart';
import 'package:mytuition/features/attendance/presentation/pages/qr_scanner_page.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/attendance.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class TakeAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;
  final bool isUpdateMode;
  final DateTime? targetDate;

  const TakeAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
    this.isUpdateMode = false,
    this.targetDate,
  }) : super(key: key);

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  Schedule? _selectedSchedule;
  Schedule? _fixedSchedule;
  DateTime? _resolvedAttendanceDate;
  List<Schedule> _availableSchedules = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  Map<String, AttendanceStatus> _attendanceMap = {};
  Map<String, String> _remarksMap = {};
  List<Attendance> _existingAttendanceRecords = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Schedule status tracking
  Map<String, bool> _scheduleStatusMap = {};
  Map<String, int> _scheduleCountMap = {};
  bool _isLoadingScheduleStatus = false;

  @override
  void initState() {
    super.initState();
    _resolvedAttendanceDate = widget.targetDate ?? DateTime.now();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    context.read<AttendanceBloc>().add(
          LoadEnrolledStudentsEvent(courseId: widget.courseId),
        );

    if (widget.isUpdateMode && widget.targetDate != null) {
      context.read<AttendanceBloc>().add(
            LoadAttendanceByDateEvent(
              courseId: widget.courseId,
              date: widget.targetDate!,
            ),
          );
    } else {
      context.read<AttendanceBloc>().add(
            LoadCourseSchedulesEvent(courseId: widget.courseId),
          );
    }
  }

  List<Schedule> _getValidSchedulesForDate(List<Schedule> allSchedules) {
    if (_resolvedAttendanceDate == null) return [];

    final validSchedules = <Schedule>[];
    final currentDate = _resolvedAttendanceDate!;

    for (final schedule in allSchedules) {
      if (!schedule.isActive) continue;
      if (schedule.isRelevantForDate(currentDate)) {
        final hasAttendance = _scheduleStatusMap[schedule.id] ?? false;
        if (!hasAttendance) {
          validSchedules.add(schedule);
        }
      }
    }

    return validSchedules;
  }

  void _loadScheduleAttendanceStatus(List<Schedule> schedules) {
    if (_resolvedAttendanceDate == null || schedules.isEmpty) return;

    setState(() {
      _isLoadingScheduleStatus = true;
    });

    context.read<AttendanceBloc>().add(
          LoadScheduleAttendanceStatusEvent(
            courseId: widget.courseId,
            date: _resolvedAttendanceDate!,
            schedules: schedules,
          ),
        );
  }

  Schedule? _extractScheduleFromMetadata(List<Attendance> records) {
    if (records.isEmpty) return null;

    try {
      final attendanceDate = widget.targetDate!;
      final dayName = DateFormat('EEEE').format(attendanceDate);

      return Schedule(
        id: 'update-mode-schedule',
        courseId: widget.courseId,
        startTime: DateTime(attendanceDate.year, attendanceDate.month,
            attendanceDate.day, 14, 0),
        endTime: DateTime(attendanceDate.year, attendanceDate.month,
            attendanceDate.day, 15, 0),
        day: dayName,
        location: 'Classroom',
        subject: widget.courseName.split(' ')[0],
        grade: 1,
        type: ScheduleType.regular,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error extracting schedule from metadata: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is CourseSchedulesLoaded && !widget.isUpdateMode) {
          setState(() {
            _availableSchedules = state.schedules;
          });
          _loadScheduleAttendanceStatus(state.schedules);
        } else if (state is AttendanceByDateLoaded && widget.isUpdateMode) {
          setState(() {
            _existingAttendanceRecords = state.attendanceRecords;
            _fixedSchedule =
                _extractScheduleFromMetadata(state.attendanceRecords);

            _attendanceMap.clear();
            _remarksMap.clear();

            for (var record in state.attendanceRecords) {
              _attendanceMap[record.studentId] = record.status;
              if (record.remarks != null && record.remarks!.isNotEmpty) {
                if (!record.remarks!.contains('_scheduleMeta')) {
                  _remarksMap[record.studentId] = record.remarks!;
                }
              }
            }
          });
        } else if (state is EnrolledStudentsLoaded) {
          setState(() {
            _enrolledStudents = state.students;
            _attendanceMap.clear();
            _remarksMap.clear();
            for (final student in state.students) {
              final studentId = student['studentId'] as String;
              _attendanceMap[studentId] = AttendanceStatus.absent;
            }
          });
        } else if (state is ScheduleAttendanceStatusForTakeAttendanceLoaded) {
          setState(() {
            _scheduleStatusMap = state.scheduleStatuses;
            _scheduleCountMap = state.attendanceCounts;
            _isLoadingScheduleStatus = false;
          });
        } else if (state is AttendanceRecordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isUpdateMode ? 'Edit Attendance' : 'Take Attendance',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            final isLoading =
                state is AttendanceLoading || _isLoadingScheduleStatus;

            return LoadingOverlay(
              child: CustomScrollView(
                slivers: [
                  // Header info
                  SliverToBoxAdapter(child: _buildHeaderInfo()),

                  // Session selector or fixed session info
                  SliverToBoxAdapter(
                    child: widget.isUpdateMode
                        ? _buildFixedSessionInfo()
                        : _buildScheduleSelector(),
                  ),

                  // Main content area
                  if (widget.isUpdateMode || _selectedSchedule != null)
                    ..._buildAttendanceContent()
                  else
                    SliverFillRemaining(child: _buildScheduleSelectionPrompt()),

                  // Submit button
                  if (widget.isUpdateMode || _selectedSchedule != null)
                    SliverToBoxAdapter(child: _buildSubmitButton()),

                  // Bottom padding for safe area
                  SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                ],
              ),
              isLoading: isLoading,
              message: _isLoadingScheduleStatus
                  ? 'Checking schedule availability...'
                  : 'Loading...',
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.w),
          bottomRight: Radius.circular(6.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Colors.white,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  widget.courseName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Attendance Date',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('EEEE, MMM d, yyyy')
                    .format(_resolvedAttendanceDate!),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFixedSessionInfo() {
    if (_fixedSchedule == null) {
      return Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'No schedule information available for this attendance record.',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
              Icon(Icons.edit, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Editing Session:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fixedSchedule!.day} - ${_fixedSchedule!.location}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${DateFormat('HH:mm').format(_fixedSchedule!.startTime)} - ${DateFormat('HH:mm').format(_fixedSchedule!.endTime)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (_fixedSchedule!.type != ScheduleType.regular) ...[
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _fixedSchedule!.type == ScheduleType.replacement
                        ? AppColors.warning
                        : AppColors.accentTeal,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    _fixedSchedule!.type
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelector() {
    final validSchedules = _getValidSchedulesForDate(_availableSchedules);

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
              Icon(Icons.schedule, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Select Session (Required):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: _selectedSchedule == null
                      ? AppColors.error
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (validSchedules.isEmpty && !_isLoadingScheduleStatus) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2.w),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 6.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'No sessions available for ${DateFormat('EEEE, MMM d').format(_resolvedAttendanceDate!)}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Either no classes are scheduled for this date, or attendance has already been taken for all sessions.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedSchedule == null
                      ? AppColors.error
                      : AppColors.primaryBlue.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Schedule>(
                  value: _selectedSchedule,
                  hint: Text(
                    validSchedules.isEmpty
                        ? 'No sessions available...'
                        : 'Choose a class session...',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12.sp,
                    ),
                  ),
                  isExpanded: true,
                  items: validSchedules.map((schedule) {
                    final hasAttendance =
                        _scheduleStatusMap[schedule.id] ?? false;
                    final attendanceCount = _scheduleCountMap[schedule.id] ?? 0;

                    return DropdownMenuItem<Schedule>(
                      value: schedule,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${schedule.day} - ${schedule.location}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                if (hasAttendance) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 2.w, vertical: 0.5.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(1.w),
                                    ),
                                    child: Text(
                                      'TAKEN',
                                      style: TextStyle(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textMedium,
                              ),
                            ),
                            if (hasAttendance) ...[
                              Text(
                                'Attendance already recorded ($attendanceCount students)',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: AppColors.success,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _onScheduleSelected,
                  dropdownColor: Colors.white,
                  iconEnabledColor: AppColors.primaryBlue,
                  style: TextStyle(color: AppColors.textDark),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSelectionPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 20.w,
              color: AppColors.textMedium,
            ),
            SizedBox(height: 3.h),
            Text(
              'Please select a session to continue',
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'You must choose which class session this attendance is for.',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttendanceContent() {
    final filteredStudents = _enrolledStudents.where((student) {
      if (_searchQuery.isEmpty) return true;
      final name = student['name'] as String? ?? '';
      final studentId = student['studentId'] as String? ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          studentId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return [
      // Search bar
      if (_enrolledStudents.length > 5)
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(fontSize: 14.sp),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMedium, size: 5.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),

      // Quick Actions + QR Scanner
      SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Column(
            children: [
              // Quick Actions Row
              Row(
                children: [
                  Text(
                    'Quick Actions:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBatchButton(
                            'All Present', AttendanceStatus.present),
                        _buildBatchButton(
                            'All Absent', AttendanceStatus.absent),
                        _buildBatchButton('All Late', AttendanceStatus.late),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // QR Scanner Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _enrolledStudents.isNotEmpty ? _openQRScanner : null,
                  icon: Icon(Icons.qr_code_scanner, size: 5.w),
                  label: Text(
                    'Scan QR Codes',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Student list
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final student = filteredStudents[index];
            final studentId = student['studentId'] as String;
            final studentName = student['name'] as String? ?? 'Unknown Student';
            final currentStatus =
                _attendanceMap[studentId] ?? AttendanceStatus.absent;
            final remarks = _remarksMap[studentId] ?? '';

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: _buildStudentAttendanceCard(
                studentId: studentId,
                studentName: studentName,
                currentStatus: currentStatus,
                remarks: remarks,
              ),
            );
          },
          childCount: filteredStudents.length,
        ),
      ),
    ];
  }

  Widget _buildBatchButton(String label, AttendanceStatus status) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        child: ElevatedButton(
          onPressed: () => _applyBatchStatus(status),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(status),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 1.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1.5.w),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceCard({
    required String studentId,
    required String studentName,
    required AttendanceStatus currentStatus,
    required String remarks,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 6.w,
                  backgroundColor: _getStatusColor(currentStatus),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        studentId,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: AttendanceStatus.values.map((status) {
                final isSelected = currentStatus == status;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateAttendanceStatus(studentId, status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? _getStatusColor(status)
                            : Colors.grey.shade200,
                        foregroundColor:
                            isSelected ? Colors.white : AppColors.textMedium,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                        elevation: isSelected ? 2 : 0,
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 2.h),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add remarks (optional)',
                hintStyle: TextStyle(fontSize: 11.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              style: TextStyle(fontSize: 11.sp),
              onChanged: (value) => _updateRemarks(studentId, value),
              controller: TextEditingController(text: remarks)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: remarks.length),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _canSubmitAttendance() ? _submitAttendance : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _canSubmitAttendance() ? AppColors.success : Colors.grey,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 0,
        ),
        child: Text(
          _getSubmitButtonText(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper methods
  void _onScheduleSelected(Schedule? schedule) {
    if (schedule != null) {
      setState(() {
        _selectedSchedule = schedule;
        _resolvedAttendanceDate =
            ScheduleDateUtils.getScheduleDateForCurrentWeek(schedule);
      });
    }
  }

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

  void _updateAttendanceStatus(String studentId, AttendanceStatus status) {
    setState(() {
      _attendanceMap[studentId] = status;
    });
  }

  void _updateRemarks(String studentId, String remarks) {
    setState(() {
      _remarksMap[studentId] = remarks;
    });
  }

  void _applyBatchStatus(AttendanceStatus status) {
    setState(() {
      for (final key in _attendanceMap.keys) {
        _attendanceMap[key] = status;
      }
    });
  }

  bool _canSubmitAttendance() {
    if (widget.isUpdateMode) {
      return _fixedSchedule != null && _attendanceMap.isNotEmpty;
    }
    return _selectedSchedule != null && _attendanceMap.isNotEmpty;
  }

  String _getSubmitButtonText() {
    if (widget.isUpdateMode) {
      return 'Update Attendance (${_attendanceMap.length} students)';
    }
    return 'Submit Attendance (${_attendanceMap.length} students)';
  }

  void _submitAttendance() {
    if (widget.isUpdateMode) {
      if (_fixedSchedule != null) {
        context.read<AttendanceBloc>().add(
              RecordScheduledAttendanceWithDateResolutionEvent(
                courseId: widget.courseId,
                schedule: _fixedSchedule!,
                studentAttendances: _attendanceMap,
                remarks: _remarksMap.isNotEmpty ? _remarksMap : null,
                allowOverwrite: true,
              ),
            );
      }
    } else {
      if (_selectedSchedule != null) {
        context.read<AttendanceBloc>().add(
              RecordScheduledAttendanceWithDateResolutionEvent(
                courseId: widget.courseId,
                schedule: _selectedSchedule!,
                studentAttendances: _attendanceMap,
                remarks: _remarksMap.isNotEmpty ? _remarksMap : null,
                allowOverwrite: false,
              ),
            );
      }
    }
  }

  void _openQRScanner() {
    final enrolledStudentsMap = <String, Map<String, dynamic>>{};
    for (final student in _enrolledStudents) {
      final studentId = student['studentId'] as String;
      enrolledStudentsMap[studentId] = student;
    }

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          enrolledStudents: enrolledStudentsMap,
          initialAttendances: _attendanceMap,
        ),
      ),
    )
        .then((result) {
      if (result != null && result is Map<String, AttendanceStatus>) {
        setState(() {
          _attendanceMap.addAll(result);
        });
      }
    });
  }
}
