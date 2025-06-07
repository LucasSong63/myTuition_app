// lib/features/student_dashboard/domain/usecases/get_student_dashboard_stats_usecase.dart

import '../../data/repositories/student_dashboard_repository_impl.dart';
import '../entities/student_dashboard_stats.dart';
import '../repositories/student_dashboard_repository.dart';
import '../../../ai_chat/domain/repositories/ai_usage_repository.dart';

class GetStudentDashboardStatsUseCase {
  final StudentDashboardRepository studentDashboardRepository;
  final AIUsageRepository aiUsageRepository;

  GetStudentDashboardStatsUseCase({
    required this.studentDashboardRepository,
    required this.aiUsageRepository,
  });

  Future<StudentDashboardStats> execute(String studentId) async {
    try {
      print("🔍 Starting dashboard stats for studentId: '$studentId'");

      // DEBUGGING: Call the debug method first
      if (studentDashboardRepository is StudentDashboardRepositoryImpl) {
        await (studentDashboardRepository as StudentDashboardRepositoryImpl)
            .debugStudentData(studentId);
      }

      // Get all data in parallel for better performance - ALL FUNCTIONALITY ENABLED
      final results = await Future.wait([
        studentDashboardRepository.getEnrolledCoursesCount(studentId),
        studentDashboardRepository.getPendingTasksCount(studentId),
        studentDashboardRepository.hasOutstandingPayments(studentId),
        studentDashboardRepository.getUpcomingClasses(studentId),
        // ✅ Re-enabled
        studentDashboardRepository.getRecentPendingTasks(studentId, limit: 5),
        // ✅ Re-enabled
        studentDashboardRepository.getRecentActivities(studentId, limit: 10),
        // ✅ Re-enabled
      ]);

      final enrolledCoursesCount = results[0] as int;
      final pendingTasksCount = results[1] as int;
      final hasOutstandingPayments = results[2] as bool;
      final upcomingClasses = results[3] as List<UpcomingClass>;
      final recentTasks = results[4] as List<PendingTask>;
      final recentActivities = results[5] as List<StudentActivity>;

      // Filter today's classes
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcomingClassesToday = upcomingClasses
          .where((c) => c.isToday || _isSameDay(c.startTime, today))
          .toList();

      print("📊 Results Summary:");
      print("  - Enrolled Courses: $enrolledCoursesCount");
      print("  - Pending Tasks: $pendingTasksCount");
      print("  - Outstanding Payments: $hasOutstandingPayments");
      print("  - Upcoming Classes (Total): ${upcomingClasses.length}");
      print("  - Upcoming Classes (Today): ${upcomingClassesToday.length}");
      print("  - Recent Tasks: ${recentTasks.length}");
      print("  - Recent Activities: ${recentActivities.length}");

      // Get AI usage separately as it needs different error handling
      final aiUsageResult = await aiUsageRepository.getAIUsage(studentId);
      final aiUsage = aiUsageResult.fold(
        (error) => throw Exception('Failed to get AI usage: $error'),
        (usage) => usage,
      );

      print("  - AI Usage: ${aiUsage.dailyCount}/${aiUsage.dailyLimit}");

      // Create and return the complete dashboard stats
      final dashboardStats = StudentDashboardStats(
        enrolledCoursesCount: enrolledCoursesCount,
        pendingTasksCount: pendingTasksCount,
        aiUsage: aiUsage,
        hasOutstandingPayments: hasOutstandingPayments,
        upcomingClassesToday: upcomingClassesToday,
        upcomingClassesThisWeek: upcomingClasses,
        recentTasks: recentTasks,
        recentActivities: recentActivities,
      );

      print("✅ Dashboard stats loaded successfully");
      return dashboardStats;
    } catch (e) {
      print("❌ Error in GetStudentDashboardStatsUseCase: $e");
      print("Stack trace: ${StackTrace.current}");

      // Re-throw with more context
      throw Exception('Failed to load student dashboard stats: $e');
    }
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Optional: Add a method to get partial stats if some fail
  Future<StudentDashboardStats> executeWithFallback(String studentId) async {
    try {
      print(
          "🔍 Starting dashboard stats with fallback for studentId: '$studentId'");

      // Initialize with default values
      int enrolledCoursesCount = 0;
      int pendingTasksCount = 0;
      bool hasOutstandingPayments = false;
      List<UpcomingClass> upcomingClasses = [];
      List<PendingTask> recentTasks = [];
      List<StudentActivity> recentActivities = [];

      // Try to get each piece of data individually with fallbacks
      try {
        enrolledCoursesCount =
            await studentDashboardRepository.getEnrolledCoursesCount(studentId);
        print("✅ Enrolled courses loaded: $enrolledCoursesCount");
      } catch (e) {
        print("⚠️ Failed to load enrolled courses: $e");
      }

      try {
        pendingTasksCount =
            await studentDashboardRepository.getPendingTasksCount(studentId);
        print("✅ Pending tasks loaded: $pendingTasksCount");
      } catch (e) {
        print("⚠️ Failed to load pending tasks: $e");
      }

      try {
        hasOutstandingPayments =
            await studentDashboardRepository.hasOutstandingPayments(studentId);
        print("✅ Outstanding payments loaded: $hasOutstandingPayments");
      } catch (e) {
        print("⚠️ Failed to load outstanding payments: $e");
      }

      try {
        upcomingClasses =
            await studentDashboardRepository.getUpcomingClasses(studentId);
        print("✅ Upcoming classes loaded: ${upcomingClasses.length}");
      } catch (e) {
        print("⚠️ Failed to load upcoming classes: $e");
      }

      try {
        recentTasks = await studentDashboardRepository
            .getRecentPendingTasks(studentId, limit: 5);
        print("✅ Recent tasks loaded: ${recentTasks.length}");
      } catch (e) {
        print("⚠️ Failed to load recent tasks: $e");
      }

      try {
        recentActivities = await studentDashboardRepository
            .getRecentActivities(studentId, limit: 10);
        print("✅ Recent activities loaded: ${recentActivities.length}");
      } catch (e) {
        print("⚠️ Failed to load recent activities: $e");
      }

      // Filter today's classes
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcomingClassesToday = upcomingClasses
          .where((c) => c.isToday || _isSameDay(c.startTime, today))
          .toList();

      // Get AI usage with fallback
      late dynamic aiUsage;
      try {
        final aiUsageResult = await aiUsageRepository.getAIUsage(studentId);
        aiUsage = aiUsageResult.fold(
          (error) => throw Exception('Failed to get AI usage: $error'),
          (usage) => usage,
        );
        print("✅ AI usage loaded: ${aiUsage.dailyCount}/${aiUsage.dailyLimit}");
      } catch (e) {
        print("⚠️ Failed to load AI usage: $e");
        // Create a default AI usage object
        aiUsage = _createDefaultAIUsage();
      }

      print("📊 Fallback Results Summary:");
      print("  - Enrolled Courses: $enrolledCoursesCount");
      print("  - Pending Tasks: $pendingTasksCount");
      print("  - Outstanding Payments: $hasOutstandingPayments");
      print("  - Upcoming Classes (Total): ${upcomingClasses.length}");
      print("  - Upcoming Classes (Today): ${upcomingClassesToday.length}");
      print("  - Recent Tasks: ${recentTasks.length}");
      print("  - Recent Activities: ${recentActivities.length}");

      final dashboardStats = StudentDashboardStats(
        enrolledCoursesCount: enrolledCoursesCount,
        pendingTasksCount: pendingTasksCount,
        aiUsage: aiUsage,
        hasOutstandingPayments: hasOutstandingPayments,
        upcomingClassesToday: upcomingClassesToday,
        upcomingClassesThisWeek: upcomingClasses,
        recentTasks: recentTasks,
        recentActivities: recentActivities,
      );

      print("✅ Dashboard stats loaded with fallback");
      return dashboardStats;
    } catch (e) {
      print("❌ Error in executeWithFallback: $e");
      throw Exception(
          'Failed to load student dashboard stats even with fallback: $e');
    }
  }

  // Helper to create a default AI usage object when it fails to load
  dynamic _createDefaultAIUsage() {
    // This would depend on your AIUsage class structure
    // You might need to import the AIUsage class and create a default instance
    // For now, this is a placeholder that you should replace with actual implementation
    throw UnimplementedError(
        'Implement default AI usage creation based on your AIUsage class');
  }

  // Helper method for retry logic
  Future<T> _retryOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 2,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        print("Attempt $attempt/$maxRetries failed for $operationName: $e");

        if (attempt == maxRetries) {
          rethrow;
        }

        await Future.delayed(delay);
      }
    }

    throw Exception('All retry attempts failed for $operationName');
  }
}
