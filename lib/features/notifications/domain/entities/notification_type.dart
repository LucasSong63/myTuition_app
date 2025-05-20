// lib/features/notifications/domain/entities/notification_type.dart

import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';

/// Centralized definition of notification types used throughout the app
class NotificationType {
  // Private constructor to prevent instantiation
  NotificationType._();

  // Authentication & Registration
  static const String registrationApproved = 'registration_approved';
  static const String registrationRejected = 'registration_rejected';

  // Payment related
  static const String paymentReminder = 'payment_reminder';
  static const String paymentConfirmed = 'payment_confirmed';
  static const String paymentOverdue = 'payment_overdue';

  // Task related
  static const String taskCreated = 'task_created';
  static const String taskReminder = 'task_reminder';
  static const String taskOverdue = 'task_overdue';
  static const String taskOverdueFinal = 'task_overdue_final';
  static const String taskFeedback = 'task_feedback';
  static const String taskCompleted = 'task_completed';

  // Class related
  static const String classAnnouncement = 'class_announcement';
  static const String scheduleChange = 'schedule_change';
  static const String attendanceRecorded = 'attendance_recorded';

  // Communication
  static const String tutorNotification = 'tutor_notification';
  static const String messageReceived = 'message_received';

  // System
  static const String testNotification = 'test_notification';
  static const String systemAnnouncement = 'system_announcement';

  /// Get icon data for a notification type
  static IconData getIcon(String type) {
    switch (type) {
      // Authentication & Registration
      case registrationApproved:
        return Icons.how_to_reg;
      case registrationRejected:
        return Icons.person_off;

      // Payment related
      case paymentReminder:
        return Icons.account_balance_wallet;
      case paymentConfirmed:
        return Icons.check_circle;
      case paymentOverdue:
        return Icons.money_off;

      // Task related
      case taskCreated:
        return Icons.assignment_add;
      case taskReminder:
        return Icons.assignment_late;
      case taskOverdue:
        return Icons.assignment_late;
      case taskOverdueFinal:
        return Icons.assignment_late;
      case taskFeedback:
        return Icons.rate_review;
      case taskCompleted:
        return Icons.assignment_turned_in;

      // Class related
      case classAnnouncement:
        return Icons.campaign;
      case scheduleChange:
        return Icons.event_available;
      case attendanceRecorded:
        return Icons.fact_check;

      // Communication
      case tutorNotification:
        return Icons.school;
      case messageReceived:
        return Icons.message;

      // System
      case testNotification:
        return Icons.bug_report;
      case systemAnnouncement:
        return Icons.announcement;

      default:
        return Icons.notifications;
    }
  }

  /// Get color for a notification type
  static Color getColor(String type) {
    switch (type) {
      // Authentication & Registration
      case registrationApproved:
        return AppColors.success;
      case registrationRejected:
        return AppColors.error;

      // Payment related
      case paymentReminder:
        return AppColors.warning;
      case paymentConfirmed:
        return AppColors.success;
      case paymentOverdue:
        return AppColors.error;

      // Task related
      case taskCreated:
        return AppColors.primaryBlue;
      case taskReminder:
        return AppColors.warning;
      case taskOverdue:
        return AppColors.accentOrange;
      case taskOverdueFinal:
        return AppColors.error;
      case taskFeedback:
        return AppColors.accentTeal;
      case taskCompleted:
        return AppColors.success;

      // Class related
      case classAnnouncement:
        return AppColors.primaryBlue;
      case scheduleChange:
        return AppColors.accentTeal;
      case attendanceRecorded:
        return AppColors.secondaryBlue;

      // Communication
      case tutorNotification:
        return AppColors.accentOrange;
      case messageReceived:
        return AppColors.primaryBlue;

      // System
      case testNotification:
        return Colors.purple;
      case systemAnnouncement:
        return AppColors.accentTeal;

      default:
        return AppColors.primaryBlue;
    }
  }

  /// Get description for a notification type
  static String getDescription(String type) {
    switch (type) {
      // Authentication & Registration
      case registrationApproved:
        return 'Registration Approved';
      case registrationRejected:
        return 'Registration Rejected';

      // Payment related
      case paymentReminder:
        return 'Payment Reminder';
      case paymentConfirmed:
        return 'Payment Confirmation';
      case paymentOverdue:
        return 'Payment Overdue';

      // Task related
      case taskCreated:
        return 'New Task';
      case taskReminder:
        return 'Task Reminder';
      case taskOverdue:
        return 'Task Overdue';
      case taskOverdueFinal:
        return 'Final Task Reminder';
      case taskFeedback:
        return 'Task Feedback';
      case taskCompleted:
        return 'Task Completed';

      // Class related
      case classAnnouncement:
        return 'Class Announcement';
      case scheduleChange:
        return 'Schedule Change';
      case attendanceRecorded:
        return 'Attendance Recorded';

      // Communication
      case tutorNotification:
        return 'Tutor Message';
      case messageReceived:
        return 'New Message';

      // System
      case testNotification:
        return 'Test Notification';
      case systemAnnouncement:
        return 'System Announcement';

      default:
        return 'Notification';
    }
  }

  /// Get a map with all info for a notification type
  static Map<String, dynamic> getTypeInfo(String type) {
    return {
      'icon': getIcon(type),
      'color': getColor(type),
      'description': getDescription(type),
    };
  }

  /// Get all notification types as a list
  static List<String> getAllTypes() {
    return [
      // Authentication & Registration
      registrationApproved,
      registrationRejected,

      // Payment related
      paymentReminder,
      paymentConfirmed,
      paymentOverdue,

      // Task related
      taskCreated,
      taskReminder,
      taskOverdue,
      taskOverdueFinal,
      taskFeedback,
      taskCompleted,

      // Class related
      classAnnouncement,
      scheduleChange,
      attendanceRecorded,

      // Communication
      tutorNotification,
      messageReceived,

      // System
      systemAnnouncement,
    ];
  }

  /// Get notification types grouped by category
  static Map<String, List<String>> getTypesByCategory() {
    return {
      'Authentication': [registrationApproved, registrationRejected],
      'Payments': [paymentReminder, paymentConfirmed, paymentOverdue],
      'Tasks': [
        taskCreated,
        taskReminder,
        taskOverdue,
        taskOverdueFinal,
        taskFeedback,
        taskCompleted
      ],
      'Classes': [classAnnouncement, scheduleChange, attendanceRecorded],
      'Communication': [tutorNotification, messageReceived],
      'System': [systemAnnouncement],
    };
  }
}
