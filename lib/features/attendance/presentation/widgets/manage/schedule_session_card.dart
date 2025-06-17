// lib/features/attendance/presentation/widgets/manage/schedule_session_card.dart
import 'package:flutter/material.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class ScheduleSessionCard extends StatelessWidget {
  final String scheduleId;
  final Map<String, dynamic>? scheduleInfo;
  final List<Attendance> records;

  const ScheduleSessionCard({
    Key? key,
    required this.scheduleId,
    required this.scheduleInfo,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheduleAttendanceRate = records.isNotEmpty
        ? records
                .where((r) =>
                    r.status == AttendanceStatus.present ||
                    r.status == AttendanceStatus.late)
                .length /
            records.length
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: Colors.grey[200]!),
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
                      scheduleInfo != null
                          ? '${scheduleInfo!['scheduleDay']} - ${scheduleInfo!['scheduleLocation']}'
                          : scheduleId,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (scheduleInfo != null &&
                        scheduleInfo!['scheduleTime'] != null)
                      Text(
                        scheduleInfo!['scheduleTime'],
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${records.length} students',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.w),
                decoration: BoxDecoration(
                  color: scheduleAttendanceRate >= 0.8
                      ? AppColors.success
                      : AppColors.warning,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  '${(scheduleAttendanceRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Schedule type indicator (if available)
          if (scheduleInfo != null &&
              scheduleInfo!['scheduleType'] != 'regular') ...[
            SizedBox(height: 1.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
              decoration: BoxDecoration(
                color: scheduleInfo!['scheduleType'] == 'replacement'
                    ? AppColors.warning.withOpacity(0.1)
                    : AppColors.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(1.w),
                border: Border.all(
                  color: scheduleInfo!['scheduleType'] == 'replacement'
                      ? AppColors.warning
                      : AppColors.accentTeal,
                ),
              ),
              child: Text(
                scheduleInfo!['scheduleType'].toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: scheduleInfo!['scheduleType'] == 'replacement'
                      ? AppColors.warning
                      : AppColors.accentTeal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
