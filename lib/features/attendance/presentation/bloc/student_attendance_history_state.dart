import 'package:equatable/equatable.dart';
import '../../data/models/attendance_model.dart';

abstract class StudentAttendanceHistoryState extends Equatable {
  const StudentAttendanceHistoryState();

  @override
  List<Object?> get props => [];
}

class StudentAttendanceHistoryInitial extends StudentAttendanceHistoryState {}

class StudentAttendanceHistoryLoading extends StudentAttendanceHistoryState {}

class StudentAttendanceHistoryLoaded extends StudentAttendanceHistoryState {
  final List<AttendanceModel> allAttendance;
  final List<AttendanceModel> filteredAttendance;
  final Map<String, dynamic> statistics;
  final String? activeStatusFilter;
  final String? activeCourseFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;

  const StudentAttendanceHistoryLoaded({
    required this.allAttendance,
    required this.filteredAttendance,
    required this.statistics,
    this.activeStatusFilter,
    this.activeCourseFilter,
    this.startDateFilter,
    this.endDateFilter,
  });

  @override
  List<Object?> get props => [
        allAttendance,
        filteredAttendance,
        statistics,
        activeStatusFilter,
        activeCourseFilter,
        startDateFilter,
        endDateFilter,
      ];

  StudentAttendanceHistoryLoaded copyWith({
    List<AttendanceModel>? allAttendance,
    List<AttendanceModel>? filteredAttendance,
    Map<String, dynamic>? statistics,
    String? activeStatusFilter,
    String? activeCourseFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
  }) {
    return StudentAttendanceHistoryLoaded(
      allAttendance: allAttendance ?? this.allAttendance,
      filteredAttendance: filteredAttendance ?? this.filteredAttendance,
      statistics: statistics ?? this.statistics,
      activeStatusFilter: activeStatusFilter ?? this.activeStatusFilter,
      activeCourseFilter: activeCourseFilter ?? this.activeCourseFilter,
      startDateFilter: startDateFilter ?? this.startDateFilter,
      endDateFilter: endDateFilter ?? this.endDateFilter,
    );
  }
}

class StudentAttendanceHistoryError extends StudentAttendanceHistoryState {
  final String message;

  const StudentAttendanceHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
