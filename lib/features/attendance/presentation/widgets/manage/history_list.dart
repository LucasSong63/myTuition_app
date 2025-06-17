// lib/features/attendance/presentation/widgets/manage/history_list.dart
import 'package:flutter/material.dart';
import 'package:mytuition/features/attendance/data/models/attendance_model.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';
import 'package:sizer/sizer.dart';
import '../manage/day_attendance_card.dart';
import '../manage/empty_history_view.dart';

class HistoryList extends StatelessWidget {
  final Map<String, List<Attendance>> past7DaysAttendance;
  final Map<String, List<Attendance>> olderAttendance;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onRefresh;
  final String courseId;
  final String courseName;

  const HistoryList({
    Key? key,
    required this.past7DaysAttendance,
    required this.olderAttendance,
    required this.startDate,
    required this.endDate,
    required this.onRefresh,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  // FIXED: Count unique sessions within a map of attendance records
  int _countUniqueSessionsInMap(Map<String, List<Attendance>> attendanceMap) {
    Set<String> uniqueSessions = {};

    attendanceMap.forEach((dateKey, records) {
      for (var record in records) {
        String sessionId = _extractSessionId(record);
        String uniqueSessionKey = '${dateKey}_$sessionId';
        uniqueSessions.add(uniqueSessionKey);
      }
    });

    return uniqueSessions.length;
  }

  String _extractSessionId(Attendance record) {
    try {
      // Try to extract from schedule metadata first
      if (record is AttendanceModel && record.scheduleMetadata != null) {
        final metadata = record.scheduleMetadata!;
        return metadata['scheduleId'] as String? ?? 'default';
      }

      // Fallback: extract from record ID pattern
      if (record.id.contains('-')) {
        List<String> idParts = record.id.split('-');
        if (idParts.length >= 4) {
          // Pattern: courseId-studentId-date-scheduleId
          return idParts[3];
        }
      }

      // Final fallback - use timestamp to differentiate sessions on same day
      return 'session-${record.date.millisecondsSinceEpoch}';
    } catch (e) {
      return 'default';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (past7DaysAttendance.isEmpty && olderAttendance.isEmpty) {
      return EmptyHistoryView(
        startDate: startDate,
        endDate: endDate,
      );
    }

    // FIXED: Calculate session counts properly
    final past7DaysSessionCount =
        _countUniqueSessionsInMap(past7DaysAttendance);
    final olderSessionCount = _countUniqueSessionsInMap(olderAttendance);

    return CustomScrollView(
      slivers: [
        // Past 7 days section (editable)
        if (past7DaysAttendance.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.green[700], size: 5.w),
                  SizedBox(width: 2.w),
                  Text(
                    'Past 7 Days (Editable)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$past7DaysSessionCount ${past7DaysSessionCount == 1 ? 'session' : 'sessions'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sortedKeys = past7DaysAttendance.keys.toList()
                    ..sort((a, b) => b.compareTo(a));
                  final dateKey = sortedKeys[index];
                  final date = DateTime.parse(dateKey);
                  final records = past7DaysAttendance[dateKey]!;
                  return DayAttendanceCard(
                    date: date,
                    records: records,
                    isEditable: true,
                    courseId: courseId,
                    courseName: courseName,
                    onRefresh: onRefresh,
                  );
                },
                childCount: past7DaysAttendance.length,
              ),
            ),
          ),
        ],

        // Older records section (view only)
        if (olderAttendance.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.orange[700], size: 5.w),
                  SizedBox(width: 2.w),
                  Text(
                    'Older Records (View Only)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$olderSessionCount ${olderSessionCount == 1 ? 'session' : 'sessions'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sortedKeys = olderAttendance.keys.toList()
                    ..sort((a, b) => b.compareTo(a));
                  final dateKey = sortedKeys[index];
                  final date = DateTime.parse(dateKey);
                  final records = olderAttendance[dateKey]!;
                  return DayAttendanceCard(
                    date: date,
                    records: records,
                    isEditable: false,
                    courseId: courseId,
                    courseName: courseName,
                    onRefresh: onRefresh,
                  );
                },
                childCount: olderAttendance.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
