// lib/core/services/notification_navigation_service.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/core/utils/logger.dart';

/// Service to handle navigation when notifications are tapped
class NotificationNavigationService {
  static final NotificationNavigationService _instance = 
      NotificationNavigationService._internal();
  
  factory NotificationNavigationService() => _instance;
  
  NotificationNavigationService._internal();

  /// Navigate based on notification data
  void handleNotificationNavigation(
    BuildContext context, 
    Map<String, dynamic> data,
  ) {
    try {
      final type = data['type'] as String?;
      
      if (type == null) {
        // Default to notifications list
        context.push('/notifications');
        return;
      }

      Logger.info('Handling notification navigation for type: $type');

      switch (type) {
        case 'task_created':
        case 'task_reminder':
          final taskId = data['taskId'] as String?;
          if (taskId != null) {
            context.pushNamed(
              RouteNames.studentTaskDetails,
              pathParameters: {'taskId': taskId},
            );
          } else {
            context.pushNamed(RouteNames.studentTasks);
          }
          break;

        case 'task_feedback':
          final taskId = data['taskId'] as String?;
          if (taskId != null) {
            context.pushNamed(
              RouteNames.studentTaskDetails,
              pathParameters: {'taskId': taskId},
            );
          } else {
            context.pushNamed(RouteNames.studentTasks);
          }
          break;

        case 'schedule_change':
        case 'schedule_replacement':
          final courseId = data['courseId'] as String?;
          if (courseId != null) {
            context.pushNamed(
              RouteNames.studentCourseDetails,
              pathParameters: {'courseId': courseId},
            );
          } else {
            context.pushNamed(RouteNames.studentCourses);
          }
          break;

        case 'payment_reminder':
          // Navigate to profile page where payment info is shown
          context.pushNamed(RouteNames.studentProfile);
          break;

        case 'class_announcement':
          final courseId = data['courseId'] as String?;
          if (courseId != null) {
            context.pushNamed(
              RouteNames.studentCourseDetails,
              pathParameters: {'courseId': courseId},
            );
          } else {
            context.pushNamed(RouteNames.studentCourses);
          }
          break;

        case 'tutor_notification':
        default:
          // Navigate to notifications list
          context.push('/notifications');
          break;
      }
    } catch (e) {
      Logger.error('Error handling notification navigation: $e');
      // Fallback to notifications list
      context.push('/notifications');
    }
  }

  /// Handle initial notification (app opened from notification)
  void handleInitialNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Add a delay to ensure navigation context is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      handleNotificationNavigation(context, data);
    });
  }
}
