import '../repositories/attendance_repository.dart';

class GetScheduleAttendanceStatusUseCase {
  final AttendanceRepository repository;

  GetScheduleAttendanceStatusUseCase(this.repository);

  /// Get detailed attendance status for a specific schedule
  /// Returns map with isTaken, count, and totalStudents information
  Future<Map<String, dynamic>> execute(
      String courseId, DateTime date, String scheduleId) async {
    try {
      // Check if attendance has been taken
      final isTaken =
          await repository.hasAttendanceForSchedule(courseId, date, scheduleId);

      // Get attendance count if taken
      final attendanceCount = isTaken
          ? await repository.getScheduleAttendanceCount(
              courseId, date, scheduleId)
          : 0;

      // Get total enrolled students for comparison
      final enrolledStudents = await repository.getEnrolledStudents(courseId);
      final totalStudents = enrolledStudents.length;

      return {
        'isTaken': isTaken,
        'count': attendanceCount,
        'totalStudents': totalStudents,
        'completionRate':
            totalStudents > 0 ? attendanceCount / totalStudents : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get schedule attendance status: $e');
    }
  }

  /// Get attendance status for multiple schedules at once (optimized)
  Future<Map<String, Map<String, dynamic>>> executeForMultipleSchedules(
    String courseId,
    DateTime date,
    List<String> scheduleIds,
  ) async {
    return await repository.getMultipleScheduleAttendanceStatus(
      courseId,
      date,
      scheduleIds,
    );
  }
}
