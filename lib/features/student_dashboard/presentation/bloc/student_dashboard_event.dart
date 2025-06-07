// lib/features/student_dashboard/presentation/bloc/student_dashboard_event.dart

import 'package:equatable/equatable.dart';

abstract class StudentDashboardEvent extends Equatable {
  const StudentDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentDashboardEvent extends StudentDashboardEvent {
  final String studentId;

  const LoadStudentDashboardEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class RefreshStudentDashboardEvent extends StudentDashboardEvent {
  final String studentId;

  const RefreshStudentDashboardEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class LoadUpcomingClassesEvent extends StudentDashboardEvent {
  final String studentId;

  const LoadUpcomingClassesEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class LoadRecentTasksEvent extends StudentDashboardEvent {
  final String studentId;
  final int limit;

  const LoadRecentTasksEvent({
    required this.studentId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [studentId, limit];
}

class LoadRecentActivitiesEvent extends StudentDashboardEvent {
  final String studentId;
  final int limit;

  const LoadRecentActivitiesEvent({
    required this.studentId,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [studentId, limit];
}
