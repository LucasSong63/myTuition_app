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
