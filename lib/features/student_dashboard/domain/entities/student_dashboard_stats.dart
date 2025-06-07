// lib/features/student_dashboard/domain/entities/student_dashboard_stats.dart

import 'package:equatable/equatable.dart';
import '../../../courses/domain/entities/schedule.dart';
import '../../../ai_chat/domain/entities/ai_usage.dart';

class StudentDashboardStats extends Equatable {
  final int enrolledCoursesCount;
  final int pendingTasksCount;
  final AIUsage aiUsage;
  final bool hasOutstandingPayments;
  final List<UpcomingClass> upcomingClassesToday;
  final List<UpcomingClass> upcomingClassesThisWeek;
  final List<PendingTask> recentTasks;
  final List<StudentActivity> recentActivities;

  const StudentDashboardStats({
    required this.enrolledCoursesCount,
    required this.pendingTasksCount,
    required this.aiUsage,
    required this.hasOutstandingPayments,
    this.upcomingClassesToday = const [],
    this.upcomingClassesThisWeek = const [],
    this.recentTasks = const [],
    this.recentActivities = const [],
  });

  @override
  List<Object?> get props => [
        enrolledCoursesCount,
        pendingTasksCount,
        aiUsage,
        hasOutstandingPayments,
        upcomingClassesToday,
        upcomingClassesThisWeek,
        recentTasks,
        recentActivities,
      ];
}

class UpcomingClass extends Equatable {
  final String id;
  final String courseId;
  final String courseName;
  final String subject;
  final int grade;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String day;
  final bool isToday;
  final bool isReplacement;
  final String? reason;

  const UpcomingClass({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.subject,
    required this.grade,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.day,
    required this.isToday,
    this.isReplacement = false,
    this.reason,
  });

  String get timeRange {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get displayTitle {
    if (isReplacement && reason != null) {
      return '$subject Grade $grade (Replacement - $reason)';
    }
    return '$subject Grade $grade';
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        subject,
        grade,
        startTime,
        endTime,
        location,
        day,
        isToday,
        isReplacement,
        reason,
      ];
}

class PendingTask extends Equatable {
  final String id;
  final String taskId;
  final String title;
  final String description;
  final String courseId;
  final String courseName;
  final String subject;
  final DateTime? dueDate;
  final DateTime createdAt;
  final bool isOverdue;

  const PendingTask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.description,
    required this.courseId,
    required this.courseName,
    required this.subject,
    this.dueDate,
    required this.createdAt,
    required this.isOverdue,
  });

  String get dueDateText {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDue = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    final difference = taskDue.difference(today).inDays;

    if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference > 0) {
      return 'Due in $difference days';
    } else {
      final overdue = difference.abs();
      return overdue == 1 ? 'Overdue by 1 day' : 'Overdue by $overdue days';
    }
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        title,
        courseId,
        dueDate,
        createdAt,
        isOverdue,
      ];
}

class StudentActivity extends Equatable {
  final String id;
  final StudentActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const StudentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.data,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [id, type, title, description, timestamp, data];
}

enum StudentActivityType {
  taskAssigned,
  taskRemarks,
  scheduleChange,
  scheduleReplacement,
}

extension StudentActivityTypeExtension on StudentActivityType {
  String get displayName {
    switch (this) {
      case StudentActivityType.taskAssigned:
        return 'New Task';
      case StudentActivityType.taskRemarks:
        return 'Task Update';
      case StudentActivityType.scheduleChange:
        return 'Schedule Change';
      case StudentActivityType.scheduleReplacement:
        return 'Class Replacement';
    }
  }

  String get icon {
    switch (this) {
      case StudentActivityType.taskAssigned:
        return '📝';
      case StudentActivityType.taskRemarks:
        return '💬';
      case StudentActivityType.scheduleChange:
        return '📅';
      case StudentActivityType.scheduleReplacement:
        return '🔄';
    }
  }
}
