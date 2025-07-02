import 'package:equatable/equatable.dart';

abstract class StudentAttendanceHistoryEvent extends Equatable {
  const StudentAttendanceHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentAttendanceHistoryEvent extends StudentAttendanceHistoryEvent {
  final String studentId;

  const LoadStudentAttendanceHistoryEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class FilterAttendanceByStatusEvent extends StudentAttendanceHistoryEvent {
  final String? statusFilter;

  const FilterAttendanceByStatusEvent({this.statusFilter});

  @override
  List<Object?> get props => [statusFilter];
}

class FilterAttendanceByCourseEvent extends StudentAttendanceHistoryEvent {
  final String? courseFilter;

  const FilterAttendanceByCourseEvent({this.courseFilter});

  @override
  List<Object?> get props => [courseFilter];
}

class FilterAttendanceByDateRangeEvent extends StudentAttendanceHistoryEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterAttendanceByDateRangeEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
