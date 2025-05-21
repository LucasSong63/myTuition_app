// lib/features/notifications/domain/notification_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mytuition/core/utils/logger.dart';
import 'package:mytuition/features/notifications/domain/repositories/notification_repository.dart';
import '../../../core/models/paginated_result.dart';
import '../domain/entities/notification.dart' as app_notification;

/// A manager class for notifications that provides business logic layer above repositories
class NotificationManager {
  final NotificationRepository _notificationRepository;
  final http.Client _httpClient;

  static const String _fcmFunctionUrl =
      'https://asia-southeast1-mytuition-fyp.cloudfunctions.net/sendPushNotification';

  NotificationManager(
    this._notificationRepository, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Send a notification to a single student - now sends both in-app and push notification
  Future<bool> sendStudentNotification({
    required String studentId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool createInApp = false,
  }) async {
    print('Sending push to studentId: $studentId');
    try {
      // First create in-app notification
      await _notificationRepository.createNotification(
        userId: studentId,
        type: type,
        title: title,
        message: message,
        data: data,
      );

      // Then attempt to send push notification (failure here shouldn't affect in-app)
      try {
        await _sendPushNotification(
          studentId: studentId,
          title: title,
          message: message,
          data: data,
          type: type,
        );
      } catch (pushError) {
        // Log but don't fail the whole operation
        Logger.error(
            'Push notification failed but in-app succeeded: $pushError');
      }

      Logger.info('Notification sent to $studentId');
      return true;
    } catch (e) {
      Logger.error('Error sending notification: $e');
      return false;
    }
  }

  /// Private helper to send push notification via cloud function
  Future<void> _sendPushNotification({
    required String studentId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    // Build the URL with parameters
    final uri = Uri.parse(_fcmFunctionUrl).replace(
      queryParameters: {
        'studentId': studentId,
        'title': title,
        'message': message,
        'type': type,
        'createInApp': 'false',
        // Don't create in-app notification in the cloud function
        // Convert data map to JSON string if present
        if (data != null) 'data': jsonEncode(data),
      },
    );

    // Make the HTTP request to the cloud function
    final response = await _httpClient.get(uri);

    // Check for errors
    if (response.statusCode != 200) {
      throw Exception(
          'FCM HTTP function returned status ${response.statusCode}: ${response.body}');
    }

    Logger.info('Push notification sent to $studentId');
  }

  /// Get all notifications for a user with filtering and pagination
  Future<PaginatedResult<app_notification.Notification>> getUserNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? filter,
    bool sortDescending = true,
  }) async {
    try {
      return await _notificationRepository.getUserNotifications(
        userId,
        limit: limit,
        startAfter: startAfter,
        filter: filter,
        sortDescending: sortDescending,
      );
    } catch (e) {
      Logger.error('Error getting user notifications: $e');
      return PaginatedResult<app_notification.Notification>(
        items: [],
        hasMore: false,
      );
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markNotificationAsRead(notificationId);
      return true;
    } catch (e) {
      Logger.error('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _notificationRepository.markAllNotificationsAsRead(userId);
      return true;
    } catch (e) {
      Logger.error('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Get unread notification count for a user (one-time fetch)
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _notificationRepository.getUnreadNotificationCount(userId) ??
          0;
    } catch (e) {
      Logger.error('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get a stream of unread notification counts for a user (real-time updates)
  Stream<int> getUnreadCountStream(String userId) {
    try {
      return _notificationRepository.getUnreadNotificationCountStream(userId);
    } catch (e) {
      Logger.error('Error creating unread count stream: $e');
      return Stream.value(0);
    }
  }

  /// Get archived notifications for a user
  Future<PaginatedResult<app_notification.Notification>>
      getArchivedNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? filter,
    bool sortDescending = true,
  }) async {
    try {
      return await _notificationRepository.getArchivedNotifications(
        userId,
        limit: limit,
        startAfter: startAfter,
        filter: filter,
        sortDescending: sortDescending,
      );
    } catch (e) {
      Logger.error('Error getting archived notifications: $e');
      return PaginatedResult<app_notification.Notification>(
        items: [],
        hasMore: false,
      );
    }
  }
}
