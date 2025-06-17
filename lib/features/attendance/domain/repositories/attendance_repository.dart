import 'package:mytuition/features/courses/domain/entities/schedule.dart';

import '../entities/attendance.dart';

abstract class AttendanceRepository {
  // Existing methods
  Future<List<Attendance>> getAttendanceByDate(String courseId, DateTime date);

  Future<List<Attendance>> getStudentAttendance(
      String courseId, String studentId);

  Future<List<Attendance>> getAllStudentAttendance(String studentId);

  Future<Map<String, dynamic>> getCourseAttendanceStats(String courseId);

  Future<void> recordAttendance(
      String courseId, String studentId, DateTime date, AttendanceStatus status,
      {String? remarks});

  Future<void> recordBulkAttendance(String courseId, DateTime date,
      Map<String, AttendanceStatus> studentAttendances,
      {Map<String, String>? remarks});

  Future<void> updateAttendance(String attendanceId, AttendanceStatus status,
      {String? remarks});

  Future<void> deleteAttendance(String attendanceId);

  Future<List<Map<String, dynamic>>> getEnrolledStudents(String courseId);

  Future<List<Schedule>> getCourseSchedules(String courseId);

  // NEW: Schedule-specific attendance methods

  /// Check if attendance has been taken for a specific schedule
  Future<bool> hasAttendanceForSchedule(
      String courseId, DateTime date, String scheduleId);

  /// Get the count of students who have attendance records for a specific schedule
  Future<int> getScheduleAttendanceCount(
      String courseId, DateTime date, String scheduleId);

  /// Get attendance records for a date range (optimized for past 7 days loading)
  /// Returns a map with date strings as keys and attendance lists as values
  Future<Map<String, List<Attendance>>> getAttendanceInDateRange(
      String courseId, DateTime startDate, DateTime endDate);

  /// Get attendance status for multiple schedules on a specific date
  /// Returns a map with scheduleId as key and attendance info as value
  Future<Map<String, Map<String, dynamic>>> getMultipleScheduleAttendanceStatus(
      String courseId, DateTime date, List<String> scheduleIds);
}
