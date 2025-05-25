import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Load attendance records for a specific date
class LoadAttendanceByDateEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;

  const LoadAttendanceByDateEvent({
    required this.courseId,
    required this.date,
  });

  @override
  List<Object?> get props => [courseId, date];
}

/// Load all students enrolled in a course
class LoadEnrolledStudentsEvent extends AttendanceEvent {
  final String courseId;

  const LoadEnrolledStudentsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Record attendance for multiple students at once
class RecordBulkAttendanceEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;
  final Map<String, AttendanceStatus> studentAttendances;
  final Map<String, String>? remarks;

  const RecordBulkAttendanceEvent({
    required this.courseId,
    required this.date,
    required this.studentAttendances,
    this.remarks,
  });

  @override
  List<Object?> get props => [courseId, date, studentAttendances, remarks];
}

/// Load attendance history for a specific student
class LoadStudentAttendanceEvent extends AttendanceEvent {
  final String courseId;
  final String studentId;

  const LoadStudentAttendanceEvent({
    required this.courseId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [courseId, studentId];
}

/// Load attendance statistics for a course
class LoadCourseAttendanceStatsEvent extends AttendanceEvent {
  final String courseId;

  const LoadCourseAttendanceStatsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Load attendance statistics within a specific date range
class LoadCourseAttendanceStatsWithDateRangeEvent extends AttendanceEvent {
  final String courseId;
  final DateTime startDate;
  final DateTime endDate;

  const LoadCourseAttendanceStatsWithDateRangeEvent({
    required this.courseId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [courseId, startDate, endDate];
}

/// Load all schedules for a course
class LoadCourseSchedulesEvent extends AttendanceEvent {
  final String courseId;

  const LoadCourseSchedulesEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Record attendance for a specific schedule/session
class RecordScheduledAttendanceEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;
  final int scheduleIndex;
  final Map<String, AttendanceStatus> studentAttendances;
  final Map<String, String>? remarks;

  const RecordScheduledAttendanceEvent({
    required this.courseId,
    required this.date,
    required this.scheduleIndex,
    required this.studentAttendances,
    this.remarks,
  });

  @override
  List<Object?> get props =>
      [courseId, date, scheduleIndex, studentAttendances, remarks];
}

/// Check the connection status to handle online/offline mode
class CheckConnectionStatusEvent extends AttendanceEvent {}

/// Sync offline attendance data to the server
class SyncAttendanceDataEvent extends AttendanceEvent {}

/// Load weekly trends for attendance visualization
class LoadAttendanceWeeklyTrendsEvent extends AttendanceEvent {
  final String courseId;

  const LoadAttendanceWeeklyTrendsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}
