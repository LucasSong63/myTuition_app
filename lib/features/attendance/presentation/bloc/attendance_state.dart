import 'package:equatable/equatable.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import '../../domain/entities/attendance.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is created
class AttendanceInitial extends AttendanceState {}

/// State during loading operations
class AttendanceLoading extends AttendanceState {}

/// State when attendance records for a date are loaded
class AttendanceByDateLoaded extends AttendanceState {
  final List<Attendance> attendanceRecords;
  final DateTime date;

  const AttendanceByDateLoaded({
    required this.attendanceRecords,
    required this.date,
  });

  @override
  List<Object?> get props => [attendanceRecords, date];
}

/// State when enrolled students are loaded
class EnrolledStudentsLoaded extends AttendanceState {
  final List<Map<String, dynamic>> students;

  const EnrolledStudentsLoaded({required this.students});

  @override
  List<Object?> get props => [students];
}

/// State when attendance is successfully recorded
class AttendanceRecordSuccess extends AttendanceState {
  final String message;

  const AttendanceRecordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when a student's attendance history is loaded
class StudentAttendanceLoaded extends AttendanceState {
  final List<Attendance> attendanceRecords;
  final String studentId;

  const StudentAttendanceLoaded({
    required this.attendanceRecords,
    required this.studentId,
  });

  @override
  List<Object?> get props => [attendanceRecords, studentId];
}

/// State when course attendance statistics are loaded
class CourseAttendanceStatsLoaded extends AttendanceState {
  final Map<String, dynamic> stats;

  const CourseAttendanceStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// State when weekly attendance trends are loaded
class AttendanceWeeklyTrendsLoaded extends AttendanceState {
  final List<Map<String, dynamic>> weeklyData;

  const AttendanceWeeklyTrendsLoaded({required this.weeklyData});

  @override
  List<Object?> get props => [weeklyData];
}

/// State when course schedules are loaded
class CourseSchedulesLoaded extends AttendanceState {
  final List<Schedule> schedules;

  const CourseSchedulesLoaded({required this.schedules});

  @override
  List<Object?> get props => [schedules];
}

/// State when working in offline mode
class AttendanceOfflineMode extends AttendanceState {
  final DateTime lastSynced;
  final bool hasUnsynced;

  const AttendanceOfflineMode({
    required this.lastSynced,
    required this.hasUnsynced,
  });

  @override
  List<Object?> get props => [lastSynced, hasUnsynced];
}

/// State when an error occurs
class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when schedule attendance status is checked
class ScheduleAttendanceStatusLoaded extends AttendanceState {
  final String scheduleId;
  final bool isTaken;
  final int attendanceCount;
  final int totalStudents;
  final double completionRate;

  const ScheduleAttendanceStatusLoaded({
    required this.scheduleId,
    required this.isTaken,
    required this.attendanceCount,
    required this.totalStudents,
    required this.completionRate,
  });

  @override
  List<Object?> get props => [
        scheduleId,
        isTaken,
        attendanceCount,
        totalStudents,
        completionRate,
      ];
}

/// State when multiple schedule attendance statuses are loaded
class MultipleScheduleAttendanceStatusLoaded extends AttendanceState {
  final Map<String, Map<String, dynamic>> scheduleStatuses;
  final DateTime date;

  const MultipleScheduleAttendanceStatusLoaded({
    required this.scheduleStatuses,
    required this.date,
  });

  @override
  List<Object?> get props => [scheduleStatuses, date];
}

/// State when past 7 days attendance is loaded (optimized)
class Past7DaysAttendanceLoaded extends AttendanceState {
  final Map<String, List<Attendance>> attendanceMap;

  const Past7DaysAttendanceLoaded({
    required this.attendanceMap,
  });

  @override
  List<Object?> get props => [attendanceMap];
}

/// State when past 7 days attendance is loaded with summary statistics
class Past7DaysAttendanceWithSummaryLoaded extends AttendanceState {
  final Map<String, List<Attendance>> attendanceMap;
  final Map<String, dynamic> summary;

  const Past7DaysAttendanceWithSummaryLoaded({
    required this.attendanceMap,
    required this.summary,
  });

  @override
  List<Object?> get props => [attendanceMap, summary];
}

/// State when schedule attendance status is loaded for take attendance page
class ScheduleAttendanceStatusForTakeAttendanceLoaded extends AttendanceState {
  final List<Schedule> schedules;
  final Map<String, bool> scheduleStatuses;
  final Map<String, int> attendanceCounts;
  final DateTime date;

  const ScheduleAttendanceStatusForTakeAttendanceLoaded({
    required this.schedules,
    required this.scheduleStatuses,
    required this.attendanceCounts,
    required this.date,
  });

  @override
  List<Object?> get props =>
      [schedules, scheduleStatuses, attendanceCounts, date];
}

/// State when schedule attendance already exists (duplicate detected)
class ScheduleAttendanceAlreadyExists extends AttendanceState {
  final Schedule schedule;
  final DateTime attendanceDate;
  final int existingCount;

  const ScheduleAttendanceAlreadyExists({
    required this.schedule,
    required this.attendanceDate,
    required this.existingCount,
  });

  @override
  List<Object?> get props => [schedule, attendanceDate, existingCount];
}

/// State when schedule attendance can be taken (no duplicates)
class ScheduleAttendanceCanBeTaken extends AttendanceState {
  final Schedule schedule;
  final DateTime attendanceDate;

  const ScheduleAttendanceCanBeTaken({
    required this.schedule,
    required this.attendanceDate,
  });

  @override
  List<Object?> get props => [schedule, attendanceDate];
}

/// State when multiple schedule statuses are loaded
class MultipleScheduleStatusLoaded extends AttendanceState {
  final Map<String, bool> scheduleStatuses;
  final Map<String, int> attendanceCounts;
  final DateTime date;

  const MultipleScheduleStatusLoaded({
    required this.scheduleStatuses,
    required this.attendanceCounts,
    required this.date,
  });

  @override
  List<Object?> get props => [scheduleStatuses, attendanceCounts, date];
}

/// State when attendance records are loaded for editing
class AttendanceLoadedForEdit extends AttendanceState {
  final String courseId;
  final DateTime attendanceDate;
  final List<Attendance> attendanceRecords;
  final List<Map<String, dynamic>> enrolledStudents;
  final Map<String, dynamic>? scheduleInfo; // Extracted from first record
  final bool canEdit; // Based on 7-day rule

  const AttendanceLoadedForEdit({
    required this.courseId,
    required this.attendanceDate,
    required this.attendanceRecords,
    required this.enrolledStudents,
    this.scheduleInfo,
    required this.canEdit,
  });

  @override
  List<Object?> get props => [
        courseId,
        attendanceDate,
        attendanceRecords,
        enrolledStudents,
        scheduleInfo,
        canEdit,
      ];
}

/// State when attendance records are successfully updated
class AttendanceRecordsUpdated extends AttendanceState {
  final String message;
  final int changedStudentCount;
  final Map<String, String> changes; // studentId -> "Absent → Present"

  const AttendanceRecordsUpdated({
    required this.message,
    required this.changedStudentCount,
    required this.changes,
  });

  @override
  List<Object?> get props => [message, changedStudentCount, changes];
}

/// State when edit permission validation is complete
class EditPermissionValidated extends AttendanceState {
  final DateTime attendanceDate;
  final bool canEdit;
  final String reason; // Why can't edit (if applicable)
  final int daysOld; // How many days old the record is

  const EditPermissionValidated({
    required this.attendanceDate,
    required this.canEdit,
    required this.reason,
    required this.daysOld,
  });

  @override
  List<Object?> get props => [attendanceDate, canEdit, reason, daysOld];
}

/// State when there's a conflict (concurrent editing detected)
class AttendanceEditConflict extends AttendanceState {
  final String message;
  final DateTime lastModified;
  final List<Attendance> latestRecords;

  const AttendanceEditConflict({
    required this.message,
    required this.lastModified,
    required this.latestRecords,
  });

  @override
  List<Object?> get props => [message, lastModified, latestRecords];
}

/// State when attendance edit is preparing (validating and loading)
class AttendanceEditPreparing extends AttendanceState {
  final String message;

  const AttendanceEditPreparing({required this.message});

  @override
  List<Object?> get props => [message];
}
