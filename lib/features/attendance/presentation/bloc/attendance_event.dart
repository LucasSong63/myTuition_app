// lib/features/attendance/presentation/bloc/attendance_event.dart
import 'package:equatable/equatable.dart';
import '../../../courses/domain/entities/schedule.dart';
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

/// Record attendance for a specific schedule/session (REQUIRED)
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

/// Check if attendance has been taken for a specific schedule
class CheckScheduleAttendanceStatusEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;
  final String scheduleId;

  const CheckScheduleAttendanceStatusEvent({
    required this.courseId,
    required this.date,
    required this.scheduleId,
  });

  @override
  List<Object?> get props => [courseId, date, scheduleId];
}

/// Load attendance status for multiple schedules on a specific date
class LoadMultipleScheduleAttendanceStatusEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;
  final List<String> scheduleIds;

  const LoadMultipleScheduleAttendanceStatusEvent({
    required this.courseId,
    required this.date,
    required this.scheduleIds,
  });

  @override
  List<Object?> get props => [courseId, date, scheduleIds];
}

/// Load past 7 days attendance with optimized single query
class LoadPast7DaysAttendanceEvent extends AttendanceEvent {
  final String courseId;

  const LoadPast7DaysAttendanceEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Load past 7 days attendance with summary statistics
class LoadPast7DaysAttendanceWithSummaryEvent extends AttendanceEvent {
  final String courseId;

  const LoadPast7DaysAttendanceWithSummaryEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Load schedule attendance status for take attendance page
class LoadScheduleAttendanceStatusEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;
  final List<Schedule> schedules;

  const LoadScheduleAttendanceStatusEvent({
    required this.courseId,
    required this.date,
    required this.schedules,
  });

  @override
  List<Object?> get props => [courseId, date, schedules];
}

/// Check if attendance exists for a specific schedule before taking
class CheckScheduleAttendanceBeforeTakingEvent extends AttendanceEvent {
  final String courseId;
  final Schedule schedule;

  const CheckScheduleAttendanceBeforeTakingEvent({
    required this.courseId,
    required this.schedule,
  });

  @override
  List<Object?> get props => [courseId, schedule];
}

/// Record attendance with automatic date resolution from schedule
class RecordScheduledAttendanceWithDateResolutionEvent extends AttendanceEvent {
  final String courseId;
  final Schedule schedule;
  final Map<String, AttendanceStatus> studentAttendances;
  final Map<String, String>? remarks;
  final bool allowOverwrite;

  const RecordScheduledAttendanceWithDateResolutionEvent({
    required this.courseId,
    required this.schedule,
    required this.studentAttendances,
    this.remarks,
    this.allowOverwrite = false,
  });

  @override
  List<Object?> get props =>
      [courseId, schedule, studentAttendances, remarks, allowOverwrite];
}

/// Load multiple schedule attendance status for a specific date
class LoadMultipleScheduleStatusEvent extends AttendanceEvent {
  final String courseId;
  final DateTime date;
  final List<Schedule> schedules;

  const LoadMultipleScheduleStatusEvent({
    required this.courseId,
    required this.date,
    required this.schedules,
  });

  @override
  List<Object?> get props => [courseId, date, schedules];
}

/// Load existing attendance records for editing
class LoadAttendanceForEditEvent extends AttendanceEvent {
  final String courseId;
  final DateTime attendanceDate;
  final List<Attendance> existingRecords;

  const LoadAttendanceForEditEvent({
    required this.courseId,
    required this.attendanceDate,
    required this.existingRecords,
  });

  @override
  List<Object?> get props => [courseId, attendanceDate, existingRecords];
}

/// Update existing attendance records with changes
class UpdateAttendanceRecordsEvent extends AttendanceEvent {
  final String courseId;
  final DateTime attendanceDate;
  final Map<String, AttendanceStatus> updatedAttendances;
  final Map<String, String>? updatedRemarks;
  final Map<String, AttendanceStatus>
      originalAttendances; // For change tracking

  const UpdateAttendanceRecordsEvent({
    required this.courseId,
    required this.attendanceDate,
    required this.updatedAttendances,
    this.updatedRemarks,
    required this.originalAttendances,
  });

  @override
  List<Object?> get props => [
        courseId,
        attendanceDate,
        updatedAttendances,
        updatedRemarks,
        originalAttendances,
      ];
}

/// Validate if attendance records can be edited (within 7-day window)
class ValidateEditPermissionEvent extends AttendanceEvent {
  final DateTime attendanceDate;

  const ValidateEditPermissionEvent({required this.attendanceDate});

  @override
  List<Object?> get props => [attendanceDate];
}
