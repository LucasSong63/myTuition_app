import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

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

class LoadEnrolledStudentsEvent extends AttendanceEvent {
  final String courseId;

  const LoadEnrolledStudentsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

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

class LoadCourseAttendanceStatsEvent extends AttendanceEvent {
  final String courseId;

  const LoadCourseAttendanceStatsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}
