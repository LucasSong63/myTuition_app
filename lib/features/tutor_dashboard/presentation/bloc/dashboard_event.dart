// lib/features/dashboard/presentation/bloc/dashboard_event.dart

import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardOverviewEvent extends DashboardEvent {
  const LoadDashboardOverviewEvent();
}

class LoadUpcomingClassesEvent extends DashboardEvent {
  const LoadUpcomingClassesEvent();
}

class LoadRecentActivityEvent extends DashboardEvent {
  final int limit;

  const LoadRecentActivityEvent({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();
}
