import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

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

class EnrolledStudentsLoaded extends AttendanceState {
  final List<Map<String, dynamic>> students;

  const EnrolledStudentsLoaded({required this.students});

  @override
  List<Object?> get props => [students];
}

class AttendanceRecordSuccess extends AttendanceState {
  final String message;

  const AttendanceRecordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

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

class CourseAttendanceStatsLoaded extends AttendanceState {
  final Map<String, dynamic> stats;

  const CourseAttendanceStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}
