// lib/features/attendance/presentation/widgets/manage/day_attendance_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../../data/models/attendance_model.dart';
import '../manage/status_badge.dart';
import '../manage/schedule_session_card.dart';
import '../session_selection_bottom_sheet.dart';

class DayAttendanceCard extends StatelessWidget {
  final DateTime date;
  final List<Attendance> records;
  final bool isEditable;
  final String courseId;
  final String courseName;
  final VoidCallback onRefresh;

  const DayAttendanceCard({
    Key? key,
    required this.date,
    required this.records,
    required this.isEditable,
    required this.courseId,
    required this.courseName,
    required this.onRefresh,
  }) : super(key: key);

  Map<String, dynamic>? _extractScheduleInfo(Attendance record) {
    try {
      // Cast to AttendanceModel to access scheduleMetadata
      if (record is AttendanceModel && record.scheduleMetadata != null) {
        final metadata = record.scheduleMetadata!;

        // Validate and extract schedule times
        DateTime? startTime;
        DateTime? endTime;

        try {
          if (metadata['scheduleStartTime'] != null) {
            startTime = DateTime.parse(metadata['scheduleStartTime'] as String);
          }
          if (metadata['scheduleEndTime'] != null) {
            endTime = DateTime.parse(metadata['scheduleEndTime'] as String);
          }
        } catch (e) {
          print('Error parsing schedule times: $e');
        }

        // Format time display
        String timeDisplay = 'Session Time';
        if (startTime != null && endTime != null) {
          timeDisplay = _formatTimeRange(startTime, endTime);
        }

        return {
          'scheduleId': metadata['scheduleId'] ?? 'unknown-schedule',
          'scheduleDay':
              metadata['scheduleDay'] ?? DateFormat('EEEE').format(record.date),
          'scheduleTime': timeDisplay,
          'scheduleLocation': metadata['scheduleLocation'] ?? 'Classroom',
          'scheduleType': metadata['scheduleType'] ?? 'regular',
          'scheduleStartTime': startTime?.toIso8601String(),
          'scheduleEndTime': endTime?.toIso8601String(),
        };
      }
    } catch (e) {
      print('Error extracting schedule info: $e');
    }

    return null;
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final timeFormat = DateFormat('HH:mm');
    return '${timeFormat.format(start)} - ${timeFormat.format(end)}';
  }

  void _handleEditButtonPress(BuildContext context) {
    // Group records by schedule to check if multiple sessions exist
    final Map<String, List<Attendance>> sessionGroups = {};

    for (var record in records) {
      final scheduleInfo = _extractScheduleInfo(record);
      final scheduleId = scheduleInfo?['scheduleId'] ?? 'unknown-session';
      sessionGroups[scheduleId] = sessionGroups[scheduleId] ?? [];
      sessionGroups[scheduleId]!.add(record);
    }

    if (sessionGroups.length > 1) {
      // Multiple sessions - show selection bottom sheet
      SessionSelectionBottomSheet.show(
        context: context,
        courseName: courseName,
        attendanceDate: date,
        sessionGroups: sessionGroups,
        onSessionSelected: (sessionId, records) {
          _navigateToEditAttendance(context, sessionId, records);
        },
      );
    } else {
      // Single session - navigate directly
      final firstSessionId = sessionGroups.keys.first;
      final firstSessionRecords = sessionGroups[firstSessionId]!;
      _navigateToEditAttendance(context, firstSessionId, firstSessionRecords);
    }
  }

  void _navigateToEditAttendance(
      BuildContext context, String sessionId, List<Attendance> sessionRecords) {
    // Debug logging
    print('Navigation - EditAttendance:');
    print('  Course ID: $courseId');
    print('  Course Name: $courseName');
    print('  Date: $date');
    print('  Session ID: $sessionId');
    print('  Records Count: ${sessionRecords.length}');
    print(
        '  Records: ${sessionRecords.map((r) => '${r.studentId}:${r.status}').join(', ')}');

    // Convert complex objects to simpler types to avoid GoRouter serialization issues
    final Map<String, dynamic> navigationData = {
      'courseName': courseName,
      'attendanceDate': date.toIso8601String(), // Convert DateTime to String
      'sessionId': sessionId, // Include sessionId
      'existingRecords': sessionRecords
          .map((record) => {
                'id': record.id,
                'studentId': record.studentId,
                'status': record.status.toString(), // Convert enum to String
                'date':
                    record.date.toIso8601String(), // Convert DateTime to String
                'remarks': record.remarks,
                // Include schedule metadata if available
                if (record is AttendanceModel &&
                    record.scheduleMetadata != null)
                  'scheduleMetadata': record.scheduleMetadata,
              })
          .toList(),
    };

    // Navigate using pushNamed with simplified data
    context
        .pushNamed(
      RouteNames.editAttendance,
      pathParameters: {'courseId': courseId},
      extra: navigationData,
    )
        .then((_) {
      // Refresh data when returning
      onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group records by schedule if schedule metadata is available
    final Map<String, List<Attendance>> scheduleGroups = {};
    final List<Attendance> unScheduledRecords = [];

    for (var record in records) {
      final scheduleInfo = _extractScheduleInfo(record);

      if (scheduleInfo != null) {
        final scheduleId = scheduleInfo['scheduleId'] as String;
        scheduleGroups[scheduleId] = scheduleGroups[scheduleId] ?? [];
        scheduleGroups[scheduleId]!.add(record);
      } else {
        unScheduledRecords.add(record);
      }
    }

    // Calculate overall statistics
    final statusCounts = <AttendanceStatus, int>{};
    for (var record in records) {
      statusCounts[record.status] = (statusCounts[record.status] ?? 0) + 1;
    }

    final totalRecords = records.length;
    final presentCount = (statusCounts[AttendanceStatus.present] ?? 0) +
        (statusCounts[AttendanceStatus.late] ?? 0);
    final attendanceRate = totalRecords > 0 ? presentCount / totalRecords : 0.0;

    // Check if editing is possible (within 7 days)
    final now = DateTime.now();
    final daysDifference = now.difference(date).inDays;
    final canEdit = isEditable && daysDifference <= 7;

    return Card(
      margin: EdgeInsets.only(bottom: 4.w),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2.w),

                // Editability indicator
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.w),
                  decoration: BoxDecoration(
                    color: canEdit
                        ? AppColors.success
                        : isEditable
                            ? AppColors.error
                            : AppColors.warning,
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  child: Text(
                    canEdit
                        ? 'EDITABLE'
                        : isEditable
                            ? 'TOO OLD'
                            : 'VIEW ONLY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(width: 2.w),

                // Attendance rate indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: attendanceRate >= 0.8
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3.w),
                    border: Border.all(
                      color: attendanceRate >= 0.8
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  child: Text(
                    '${(attendanceRate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: attendanceRate >= 0.8
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.w),

            // Schedule-specific attendance display
            if (scheduleGroups.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 4.w, color: AppColors.accentTeal),
                  SizedBox(width: 1.w),
                  Text(
                    'Sessions (${scheduleGroups.length}):',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.w),
              ...scheduleGroups.entries.map((entry) {
                final scheduleId = entry.key;
                final scheduleRecords = entry.value;
                final scheduleInfo =
                    _extractScheduleInfo(scheduleRecords.first);

                return ScheduleSessionCard(
                  scheduleId: scheduleId,
                  scheduleInfo: scheduleInfo,
                  records: scheduleRecords,
                );
              }).toList(),
            ],

            // Unscheduled records (if any)
            if (unScheduledRecords.isNotEmpty) ...[
              SizedBox(height: 2.w),
              Text(
                'General Attendance: ${unScheduledRecords.length} students',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],

            SizedBox(height: 3.w),

            // Overall status breakdown
            Wrap(
              spacing: 2.w,
              runSpacing: 1.w,
              children: [
                StatusBadge(
                  label: 'Present',
                  count: statusCounts[AttendanceStatus.present] ?? 0,
                  color: AppColors.success,
                ),
                StatusBadge(
                  label: 'Late',
                  count: statusCounts[AttendanceStatus.late] ?? 0,
                  color: AppColors.warning,
                ),
                StatusBadge(
                  label: 'Absent',
                  count: statusCounts[AttendanceStatus.absent] ?? 0,
                  color: AppColors.error,
                ),
                StatusBadge(
                  label: 'Excused',
                  count: statusCounts[AttendanceStatus.excused] ?? 0,
                  color: AppColors.textMedium,
                ),
              ],
            ),

            // Action buttons
            if (canEdit) ...[
              SizedBox(height: 3.w),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleEditButtonPress(context),
                      icon: Icon(Icons.edit, size: 4.w),
                      label: Text(
                        'Edit Attendance',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
