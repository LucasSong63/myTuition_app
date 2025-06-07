// lib/features/dashboard/domain/entities/dashboard_stats.dart

import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalStudents;
  final int activeCourses;
  final int pendingRegistrations;
  final PaymentOverview paymentOverview;
  final List<UpcomingClass> upcomingClassesToday;
  final List<UpcomingClass> upcomingClassesThisWeek;
  final List<RecentActivity> recentActivities;

  const DashboardStats({
    required this.totalStudents,
    required this.activeCourses,
    required this.pendingRegistrations,
    required this.paymentOverview,
    this.upcomingClassesToday = const [],
    this.upcomingClassesThisWeek = const [],
    this.recentActivities = const [],
  });

  @override
  List<Object?> get props => [
        totalStudents,
        activeCourses,
        pendingRegistrations,
        paymentOverview,
        upcomingClassesToday,
        upcomingClassesThisWeek,
        recentActivities,
      ];
}

class PaymentOverview extends Equatable {
  final int totalPayments;
  final int paidPayments;
  final int unpaidPayments;
  final int partialPayments;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  const PaymentOverview({
    required this.totalPayments,
    required this.paidPayments,
    required this.unpaidPayments,
    required this.partialPayments,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  double get paymentCompletionRate =>
      totalPayments > 0 ? (paidPayments / totalPayments) * 100 : 0;

  @override
  List<Object?> get props => [
        totalPayments,
        paidPayments,
        unpaidPayments,
        partialPayments,
        totalAmount,
        paidAmount,
        outstandingAmount,
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
  final int enrolledStudents;
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
    required this.enrolledStudents,
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
        enrolledStudents,
        isToday,
        isReplacement,
        reason,
      ];
}

class RecentActivity extends Equatable {
  final String id;
  final RecentActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const RecentActivity({
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

enum RecentActivityType {
  payment,
  taskSubmission,
  attendance,
  enrollment,
  registration,
}

extension RecentActivityTypeExtension on RecentActivityType {
  String get displayName {
    switch (this) {
      case RecentActivityType.payment:
        return 'Payment';
      case RecentActivityType.taskSubmission:
        return 'Task Submission';
      case RecentActivityType.attendance:
        return 'Attendance';
      case RecentActivityType.enrollment:
        return 'Enrollment';
      case RecentActivityType.registration:
        return 'Registration';
    }
  }

  String get icon {
    switch (this) {
      case RecentActivityType.payment:
        return '💰';
      case RecentActivityType.taskSubmission:
        return '📝';
      case RecentActivityType.attendance:
        return '✅';
      case RecentActivityType.enrollment:
        return '👥';
      case RecentActivityType.registration:
        return '📋';
    }
  }
}
