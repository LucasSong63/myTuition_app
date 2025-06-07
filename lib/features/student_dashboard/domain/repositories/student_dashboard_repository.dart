// lib/features/student_dashboard/domain/repositories/student_dashboard_repository.dart

import '../entities/student_dashboard_stats.dart';

abstract class StudentDashboardRepository {
  /// Get complete dashboard stats for a student
  Future<StudentDashboardStats> getStudentDashboardStats(String studentId);

  /// Get count of enrolled courses for a student
  Future<int> getEnrolledCoursesCount(String studentId);

  /// Get count of pending tasks for a student
  Future<int> getPendingTasksCount(String studentId);

  /// Get upcoming classes for a student (today and this week)
  Future<List<UpcomingClass>> getUpcomingClasses(String studentId);

  /// Get recent pending tasks for a student (sorted by due date)
  Future<List<PendingTask>> getRecentPendingTasks(String studentId,
      {int limit = 5});

  /// Get recent activities for a student (task-related and schedule changes)
  Future<List<StudentActivity>> getRecentActivities(String studentId,
      {int limit = 10});

  /// Check if student has outstanding payments
  Future<bool> hasOutstandingPayments(String studentId);
}
