// lib/features/attendance/presentation/widgets/session_selection_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/attendance.dart';
import '../../data/models/attendance_model.dart';

class SessionSelectionBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required String courseName,
    required DateTime attendanceDate,
    required Map<String, List<Attendance>> sessionGroups,
    required Function(String sessionId, List<Attendance> records)
        onSessionSelected,
  }) async {
    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          'Select Session to Edit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: EdgeInsets.all(4.w),
          icon: Icon(Icons.close, size: 6.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600, // Limit width on larger screens
                ),
                child: _SessionSelectionContent(
                  courseName: courseName,
                  attendanceDate: attendanceDate,
                  sessionGroups: sessionGroups,
                  onSessionSelected: onSessionSelected,
                ),
              ),
            );
          },
        ),
      );
    }

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [pageBuilder(context)],
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(),
    );
  }
}

class _SessionSelectionContent extends StatelessWidget {
  final String courseName;
  final DateTime attendanceDate;
  final Map<String, List<Attendance>> sessionGroups;
  final Function(String sessionId, List<Attendance> records) onSessionSelected;

  const _SessionSelectionContent({
    required this.courseName,
    required this.attendanceDate,
    required this.sessionGroups,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info
          _buildHeader(),
          SizedBox(height: 4.w),

          // Date info
          _buildDateInfo(),
          SizedBox(height: 4.w),

          // Instruction text
          Text(
            'Multiple sessions found on this date. Choose which session you want to edit:',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 3.w),

          // Session cards
          ...sessionGroups.entries.map((entry) {
            final sessionId = entry.key;
            final records = entry.value;
            return _buildSessionCard(context, sessionId, records);
          }).toList(),

          SizedBox(height: 2.w),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Icon(
            Icons.edit,
            color: AppColors.primaryBlue,
            size: 6.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Attendance',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Multiple sessions available',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.accentTeal,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(attendanceDate),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentTeal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.w),
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: AppColors.textMedium,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, String sessionId, List<Attendance> records) {
    final sessionInfo = _extractSessionInfo(records.first);
    final attendanceCount = records.length;
    final presentCount = records
        .where((r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.late)
        .length;
    final attendanceRate =
        attendanceCount > 0 ? presentCount / attendanceCount : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
        side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onSessionSelected(sessionId, records);
        },
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session title and time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionInfo['displayName'] ?? sessionId,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (sessionInfo['timeDisplay'] != null) ...[
                          SizedBox(height: 1.w),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 4.w,
                                color: AppColors.textMedium,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                sessionInfo['timeDisplay']!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primaryBlue,
                    size: 4.w,
                  ),
                ],
              ),

              SizedBox(height: 3.w),

              // Session stats
              Row(
                children: [
                  _buildInfoChip(
                    '$attendanceCount students',
                    Icons.people,
                    AppColors.primaryBlue,
                  ),
                  SizedBox(width: 2.w),
                  _buildInfoChip(
                    '${(attendanceRate * 100).toStringAsFixed(0)}%',
                    Icons.trending_up,
                    attendanceRate >= 0.8
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),

              if (sessionInfo['location'] != null) ...[
                SizedBox(height: 2.w),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.textMedium,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      sessionInfo['location']!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 3.5.w),
          SizedBox(width: 1.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String?> _extractSessionInfo(Attendance record) {
    Map<String, String?> info = {
      'displayName': null,
      'timeDisplay': null,
      'location': null,
    };

    if (record is AttendanceModel && record.scheduleMetadata != null) {
      final metadata = record.scheduleMetadata!;

      // Extract display name
      final day = metadata['scheduleDay'] as String?;
      final location = metadata['scheduleLocation'] as String?;
      final type = metadata['scheduleType'] as String?;

      if (type == 'replacement') {
        info['displayName'] = '$day Replacement Class';
      } else {
        info['displayName'] = '$day - ${location ?? 'Session'}';
      }

      // Extract time display
      final startTimeStr = metadata['scheduleStartTime'] as String?;
      final endTimeStr = metadata['scheduleEndTime'] as String?;

      if (startTimeStr != null && endTimeStr != null) {
        try {
          final startTime = DateTime.parse(startTimeStr);
          final endTime = DateTime.parse(endTimeStr);
          info['timeDisplay'] = _formatTimeRange(startTime, endTime);
        } catch (e) {
          print('Error parsing schedule times: $e');
        }
      }

      info['location'] = location;
    } else {
      // Fallback for records without metadata
      info['displayName'] = 'Session ${record.id.split('-').last}';
      info['timeDisplay'] = 'Session Time';
    }

    return info;
  }

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
