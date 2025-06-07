// lib/features/dashboard/presentation/bloc/dashboard_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_stats.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  const DashboardLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardPartiallyLoaded extends DashboardState {
  final DashboardStats stats;
  final String? warning;

  const DashboardPartiallyLoaded({
    required this.stats,
    this.warning,
  });

  @override
  List<Object?> get props => [stats, warning];
}
