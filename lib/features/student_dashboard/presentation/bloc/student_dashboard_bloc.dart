// lib/features/student_dashboard/presentation/bloc/student_dashboard_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/student_dashboard/domain/entities/student_dashboard_stats.dart';
import '../../domain/usecases/get_student_dashboard_stats_usecase.dart';
import '../../domain/repositories/student_dashboard_repository.dart';
import 'student_dashboard_event.dart';
import 'student_dashboard_state.dart';

class StudentDashboardBloc
    extends Bloc<StudentDashboardEvent, StudentDashboardState> {
  final GetStudentDashboardStatsUseCase getStudentDashboardStatsUseCase;
  final StudentDashboardRepository studentDashboardRepository;

  StudentDashboardBloc({
    required this.getStudentDashboardStatsUseCase,
    required this.studentDashboardRepository,
  }) : super(StudentDashboardInitial()) {
    on<LoadStudentDashboardEvent>(_onLoadStudentDashboard);
    on<RefreshStudentDashboardEvent>(_onRefreshStudentDashboard);
    on<LoadUpcomingClassesEvent>(_onLoadUpcomingClasses);
    on<LoadRecentTasksEvent>(_onLoadRecentTasks);
    on<LoadRecentActivitiesEvent>(_onLoadRecentActivities);
  }

  Future<void> _onLoadStudentDashboard(
    LoadStudentDashboardEvent event,
    Emitter<StudentDashboardState> emit,
  ) async {
    emit(StudentDashboardLoading());

    try {
      print('Loading student dashboard for: ${event.studentId}');

      final stats =
          await getStudentDashboardStatsUseCase.execute(event.studentId);

      print('Student dashboard loaded successfully');
      print('- Enrolled courses: ${stats.enrolledCoursesCount}');
      print('- Pending tasks: ${stats.pendingTasksCount}');
      print(
          '- AI usage: ${stats.aiUsage.dailyCount}/${stats.aiUsage.dailyLimit}');
      print('- Outstanding payments: ${stats.hasOutstandingPayments}');
      print('- Upcoming classes today: ${stats.upcomingClassesToday.length}');
      print(
          '- Upcoming classes this week: ${stats.upcomingClassesThisWeek.length}');
      print('- Recent tasks: ${stats.recentTasks.length}');
      print('- Recent activities: ${stats.recentActivities.length}');

      emit(StudentDashboardLoaded(stats: stats));
    } catch (e) {
      print('Error loading student dashboard: $e');
      emit(StudentDashboardError(message: 'Failed to load dashboard: $e'));
    }
  }

  Future<void> _onRefreshStudentDashboard(
    RefreshStudentDashboardEvent event,
    Emitter<StudentDashboardState> emit,
  ) async {
    // For refresh, we can show loading or keep current state while refreshing
    if (state is StudentDashboardLoaded) {
      // Keep current state while refreshing
      try {
        final stats =
            await getStudentDashboardStatsUseCase.execute(event.studentId);
        emit(StudentDashboardLoaded(stats: stats));
      } catch (e) {
        // If refresh fails, show warning but keep current data
        final currentStats = (state as StudentDashboardLoaded).stats;
        emit(StudentDashboardPartiallyLoaded(
          stats: currentStats,
          warning: 'Failed to refresh dashboard: $e',
        ));
      }
    } else {
      // If not loaded yet, treat as regular load
      add(LoadStudentDashboardEvent(studentId: event.studentId));
    }
  }

  Future<void> _onLoadUpcomingClasses(
    LoadUpcomingClassesEvent event,
    Emitter<StudentDashboardState> emit,
  ) async {
    if (state is StudentDashboardLoaded) {
      final currentStats = (state as StudentDashboardLoaded).stats;

      try {
        final upcomingClasses = await studentDashboardRepository
            .getUpcomingClasses(event.studentId);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final upcomingClassesToday = upcomingClasses
            .where((c) => c.isToday || _isSameDay(c.startTime, today))
            .toList();

        final updatedStats = StudentDashboardStats(
          enrolledCoursesCount: currentStats.enrolledCoursesCount,
          pendingTasksCount: currentStats.pendingTasksCount,
          aiUsage: currentStats.aiUsage,
          hasOutstandingPayments: currentStats.hasOutstandingPayments,
          upcomingClassesToday: upcomingClassesToday,
          upcomingClassesThisWeek: upcomingClasses,
          recentTasks: currentStats.recentTasks,
          recentActivities: currentStats.recentActivities,
        );

        emit(StudentDashboardLoaded(stats: updatedStats));
      } catch (e) {
        emit(StudentDashboardPartiallyLoaded(
          stats: currentStats,
          warning: 'Failed to update upcoming classes: $e',
        ));
      }
    }
  }

  Future<void> _onLoadRecentTasks(
    LoadRecentTasksEvent event,
    Emitter<StudentDashboardState> emit,
  ) async {
    if (state is StudentDashboardLoaded) {
      final currentStats = (state as StudentDashboardLoaded).stats;

      try {
        final recentTasks =
            await studentDashboardRepository.getRecentPendingTasks(
          event.studentId,
          limit: event.limit,
        );

        final updatedStats = StudentDashboardStats(
          enrolledCoursesCount: currentStats.enrolledCoursesCount,
          pendingTasksCount: currentStats.pendingTasksCount,
          aiUsage: currentStats.aiUsage,
          hasOutstandingPayments: currentStats.hasOutstandingPayments,
          upcomingClassesToday: currentStats.upcomingClassesToday,
          upcomingClassesThisWeek: currentStats.upcomingClassesThisWeek,
          recentTasks: recentTasks,
          recentActivities: currentStats.recentActivities,
        );

        emit(StudentDashboardLoaded(stats: updatedStats));
      } catch (e) {
        emit(StudentDashboardPartiallyLoaded(
          stats: currentStats,
          warning: 'Failed to update recent tasks: $e',
        ));
      }
    }
  }

  Future<void> _onLoadRecentActivities(
    LoadRecentActivitiesEvent event,
    Emitter<StudentDashboardState> emit,
  ) async {
    if (state is StudentDashboardLoaded) {
      final currentStats = (state as StudentDashboardLoaded).stats;

      try {
        final recentActivities =
            await studentDashboardRepository.getRecentActivities(
          event.studentId,
          limit: event.limit,
        );

        final updatedStats = StudentDashboardStats(
          enrolledCoursesCount: currentStats.enrolledCoursesCount,
          pendingTasksCount: currentStats.pendingTasksCount,
          aiUsage: currentStats.aiUsage,
          hasOutstandingPayments: currentStats.hasOutstandingPayments,
          upcomingClassesToday: currentStats.upcomingClassesToday,
          upcomingClassesThisWeek: currentStats.upcomingClassesThisWeek,
          recentTasks: currentStats.recentTasks,
          recentActivities: recentActivities,
        );

        emit(StudentDashboardLoaded(stats: updatedStats));
      } catch (e) {
        emit(StudentDashboardPartiallyLoaded(
          stats: currentStats,
          warning: 'Failed to update recent activities: $e',
        ));
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
