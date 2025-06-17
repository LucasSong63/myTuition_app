import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class GetPast7DaysAttendanceUseCase {
  final AttendanceRepository repository;

  GetPast7DaysAttendanceUseCase(this.repository);

  /// Get attendance records for the past 7 days (excluding today)
  /// Returns a map with date strings as keys and attendance lists as values
  Future<Map<String, List<Attendance>>> execute(String courseId) async {
    try {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 7));
      final endDate = today;

      print(
          'Loading past 7 days attendance from ${startDate.toString()} to ${endDate.toString()}');

      final attendanceMap = await repository.getAttendanceInDateRange(
          courseId, startDate, endDate);

      // Filter to only include days that actually have attendance records
      final filteredMap = <String, List<Attendance>>{};

      attendanceMap.forEach((dateKey, records) {
        if (records.isNotEmpty) {
          // Sort records by student name for consistent display
          records.sort((a, b) => a.studentId.compareTo(b.studentId));
          filteredMap[dateKey] = records;
        }
      });

      print(
          'Found attendance records for ${filteredMap.length} days in the past 7 days');

      return filteredMap;
    } catch (e) {
      throw Exception('Failed to get past 7 days attendance: $e');
    }
  }

  /// Get past 7 days attendance with schedule grouping
  /// Returns nested map: {dateString: {scheduleId: [Attendance]}}
  Future<Map<String, Map<String, List<Attendance>>>>
      executeWithScheduleGrouping(String courseId) async {
    try {
      final attendanceMap = await execute(courseId);
      final scheduleGroupedMap = <String, Map<String, List<Attendance>>>{};

      attendanceMap.forEach((dateKey, records) {
        final scheduleMap = <String, List<Attendance>>{};

        for (var record in records) {
          // Extract schedule ID from attendance record
          // Note: This assumes scheduleMetadata is available in the attendance record
          final scheduleId = _extractScheduleId(record);

          scheduleMap[scheduleId] = scheduleMap[scheduleId] ?? [];
          scheduleMap[scheduleId]!.add(record);
        }

        if (scheduleMap.isNotEmpty) {
          scheduleGroupedMap[dateKey] = scheduleMap;
        }
      });

      return scheduleGroupedMap;
    } catch (e) {
      throw Exception(
          'Failed to get past 7 days attendance with schedule grouping: $e');
    }
  }

  /// Extract schedule ID from attendance record
  /// This is a helper method to handle different ways schedule ID might be stored
  String _extractScheduleId(Attendance record) {
    // For now, we'll need to extract this from remarks or create a default
    // In a real implementation, you might want to add scheduleId as a direct field
    // or access it through attendance metadata

    // Default fallback - you may need to adjust this based on your data structure
    return 'schedule-unknown';
  }

  /// Get summary statistics for past 7 days
  Future<Map<String, dynamic>> executeWithSummary(String courseId) async {
    try {
      final attendanceMap = await execute(courseId);

      int totalDays = attendanceMap.length;
      int totalRecords = 0;
      Map<String, int> statusCounts = {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };

      // Calculate summary statistics
      attendanceMap.forEach((dateKey, records) {
        totalRecords += records.length;

        for (var record in records) {
          final status = record.status.toString().split('.').last;
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      });

      final presentCount = statusCounts['present']! + statusCounts['late']!;
      final attendanceRate =
          totalRecords > 0 ? presentCount / totalRecords : 0.0;

      return {
        'attendanceMap': attendanceMap,
        'summary': {
          'totalDays': totalDays,
          'totalRecords': totalRecords,
          'statusCounts': statusCounts,
          'attendanceRate': attendanceRate,
        }
      };
    } catch (e) {
      throw Exception('Failed to get past 7 days attendance summary: $e');
    }
  }
}
