// lib/features/attendance/presentation/widgets/manage/summary_tab_content.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

// Import existing widgets from correct paths
import '../shared/date_range_indicator.dart';
import '../summary/attendance_stats_card.dart';
import '../summary/attendance_status_card.dart';
import '../manage/student_statistics_section.dart';

class SummaryTabContent extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? stats;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> students;

  const SummaryTabContent({
    Key? key,
    required this.isLoading,
    required this.stats,
    required this.startDate,
    required this.endDate,
    required this.students,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            SizedBox(height: 4.w),
            Text(
              'Loading attendance statistics...',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 16.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 4.w),
            Text(
              'No attendance data available',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              'Take attendance for some sessions to see statistics',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // SAFE NULL HANDLING - Use ?? to provide default values
    final totalStudents = (stats!['totalStudents'] as int?) ?? 0;

    // FIXED: Try both 'totalDays' and 'totalSessions' for backward compatibility
    final totalDays =
        (stats!['totalDays'] as int?) ?? (stats!['totalSessions'] as int?) ?? 0;

    final statusCounts = (stats!['statusCounts'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    // Convert statusCounts to proper int values with null safety
    final safeStatusCounts = <String, int>{
      'present': (statusCounts['present'] as int?) ?? 0,
      'absent': (statusCounts['absent'] as int?) ?? 0,
      'late': (statusCounts['late'] as int?) ?? 0,
      'excused': (statusCounts['excused'] as int?) ?? 0,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range indicator
          if (startDate != null && endDate != null)
            DateRangeIndicator(
              startDate: startDate!,
              endDate: endDate!,
            ),

          // Overview cards
          Row(
            children: [
              AttendanceStatsCard(
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.people,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 4.w),
              AttendanceStatsCard(
                title: 'Sessions',
                value: totalDays.toString(),
                icon: Icons.calendar_today,
                color: AppColors.accentTeal,
              ),
            ],
          ),
          SizedBox(height: 4.w),

          // REMOVED: Overall Attendance Rate Card
          // This was causing calculation issues and showing 150%

          // Status breakdown
          Text(
            'Attendance Breakdown',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.w),

          AttendanceStatusCard(
            title: 'Present',
            count: safeStatusCounts['present']!,
            color: AppColors.success,
            icon: Icons.check_circle,
          ),
          AttendanceStatusCard(
            title: 'Absent',
            count: safeStatusCounts['absent']!,
            color: AppColors.error,
            icon: Icons.cancel,
          ),
          AttendanceStatusCard(
            title: 'Late',
            count: safeStatusCounts['late']!,
            color: AppColors.warning,
            icon: Icons.watch_later,
          ),
          AttendanceStatusCard(
            title: 'Excused',
            count: safeStatusCounts['excused']!,
            color: AppColors.accentTeal,
            icon: Icons.medical_services,
          ),

          SizedBox(height: 4.w),

          // Student statistics section
          if (students.isNotEmpty) StudentStatisticsSection(students: students),
        ],
      ),
    );
  }
}
