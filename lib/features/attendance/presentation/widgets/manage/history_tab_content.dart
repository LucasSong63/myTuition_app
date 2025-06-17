// lib/features/attendance/presentation/widgets/manage/history_tab_content.dart
import 'package:flutter/material.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';
import '../manage/history_header.dart';
import '../manage/history_list.dart';

class HistoryTabContent extends StatelessWidget {
  final bool isLoading;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, List<Attendance>> past7DaysAttendance;
  final Map<String, List<Attendance>> olderAttendance;
  final Function(DateTime start, DateTime end) onDateRangeChanged;
  final VoidCallback onRefresh;
  final String courseId;
  final String courseName;

  const HistoryTabContent({
    Key? key,
    required this.isLoading,
    required this.startDate,
    required this.endDate,
    required this.past7DaysAttendance,
    required this.olderAttendance,
    required this.onDateRangeChanged,
    required this.onRefresh,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with date info and filters
        HistoryHeader(
          startDate: startDate,
          endDate: endDate,
          past7DaysAttendance: past7DaysAttendance,
          olderAttendance: olderAttendance,
          onDateRangeChanged: onDateRangeChanged,
        ),

        Divider(height: 1),

        // History list
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : HistoryList(
                  past7DaysAttendance: past7DaysAttendance,
                  olderAttendance: olderAttendance,
                  startDate: startDate,
                  endDate: endDate,
                  onRefresh: onRefresh,
                  courseId: courseId,
                  courseName: courseName,
                ),
        ),
      ],
    );
  }
}
