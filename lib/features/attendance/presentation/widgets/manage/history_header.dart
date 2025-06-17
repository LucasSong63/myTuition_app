// lib/features/attendance/presentation/widgets/manage/history_header.dart
import 'package:flutter/material.dart';
import 'package:mytuition/features/attendance/data/models/attendance_model.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/attendance.dart';
import '../manage/quick_filter_chips.dart';

class HistoryHeader extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, List<Attendance>> past7DaysAttendance;
  final Map<String, List<Attendance>> olderAttendance;
  final Function(DateTime start, DateTime end) onDateRangeChanged;

  const HistoryHeader({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.past7DaysAttendance,
    required this.olderAttendance,
    required this.onDateRangeChanged,
  }) : super(key: key);

  // FIXED: Count unique sessions properly
  int _countUniqueSessions() {
    Set<String> uniqueSessions = {};

    // Combine all attendance records
    final allRecords = <Attendance>[];
    allRecords.addAll(past7DaysAttendance.values.expand((records) => records));
    allRecords.addAll(olderAttendance.values.expand((records) => records));

    for (var record in allRecords) {
      // Extract schedule info to identify unique sessions
      String sessionId = _extractSessionId(record);
      String dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      String uniqueSessionKey = '${dateKey}_$sessionId';
      uniqueSessions.add(uniqueSessionKey);
    }

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

      // Final fallback
      return 'session-${record.date.millisecondsSinceEpoch}';
    } catch (e) {
      return 'default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = _countUniqueSessions();

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                startDate != null && endDate != null
                    ? '${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}'
                    : 'Attendance History',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (totalSessions > 0)
                Text(
                  '$totalSessions ${totalSessions == 1 ? 'session' : 'sessions'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.w),
          // Quick filter buttons
          if (startDate == null && endDate == null)
            QuickFilterChips(
              startDate: startDate,
              endDate: endDate,
              onDateRangeChanged: onDateRangeChanged,
            ),
        ],
      ),
    );
  }
}
