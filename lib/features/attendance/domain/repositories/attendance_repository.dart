import 'package:mytuition/features/courses/domain/entities/schedule.dart';

import '../entities/attendance.dart';

abstract class AttendanceRepository {
  // Get attendance records for a specific course on a specific date
  Future<List<Attendance>> getAttendanceByDate(String courseId, DateTime date);

  // Get attendance records for a specific student in a course
  Future<List<Attendance>> getStudentAttendance(
      String courseId, String studentId);

  // Get attendance records for a specific student across all courses
  Future<List<Attendance>> getAllStudentAttendance(String studentId);

  // Get attendance statistics for a course
  Future<Map<String, dynamic>> getCourseAttendanceStats(String courseId);

  // Record attendance for a student
  Future<void> recordAttendance(
      String courseId, String studentId, DateTime date, AttendanceStatus status,
      {String? remarks});

  // Record attendance for multiple students at once
  Future<void> recordBulkAttendance(String courseId, DateTime date,
      Map<String, AttendanceStatus> studentAttendances,
      {Map<String, String>? remarks});

  // Update existing attendance record
  Future<void> updateAttendance(String attendanceId, AttendanceStatus status,
      {String? remarks});

  // Delete attendance record
  Future<void> deleteAttendance(String attendanceId);

  // Get all students enrolled in a course
  Future<List<Map<String, dynamic>>> getEnrolledStudents(String courseId);

  Future<List<Schedule>> getCourseSchedules(String courseId);
}
