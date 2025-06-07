// lib/features/student_dashboard/presentation/bloc/student_dashboard_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/student_dashboard_stats.dart';

abstract class StudentDashboardState extends Equatable {
  const StudentDashboardState();

  @override
  List<Object?> get props => [];
}

class StudentDashboardInitial extends StudentDashboardState {}

class StudentDashboardLoading extends StudentDashboardState {}

class StudentDashboardLoaded extends StudentDashboardState {
  final StudentDashboardStats stats;

  const StudentDashboardLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];

  StudentDashboardLoaded copyWith({
    StudentDashboardStats? stats,
  }) {
    return StudentDashboardLoaded(
      stats: stats ?? this.stats,
    );
  }
}

class StudentDashboardError extends StudentDashboardState {
  final String message;

  const StudentDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class StudentDashboardPartiallyLoaded extends StudentDashboardState {
  final StudentDashboardStats stats;
  final String? warning;

  const StudentDashboardPartiallyLoaded({
    required this.stats,
    this.warning,
  });

  @override
  List<Object?> get props => [stats, warning];
}
