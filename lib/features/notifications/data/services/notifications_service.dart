// lib/features/notifications/data/services/notifications_service.dart (simplified)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/core/utils/logger.dart';
import '../../domain/entities/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService(this._firestore);

  // Create a notification
  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });

      Logger.info('Notification created: ${notificationRef.id}');
      return notificationRef.id;
    } catch (e) {
      Logger.error('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      Logger.info('Notification marked as read: $notificationId');
    } catch (e) {
      Logger.error('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      if (notifications.docs.isNotEmpty) {
        await batch.commit();
        Logger.info('All notifications marked as read for user: $userId');
      }
    } catch (e) {
      Logger.error('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Get user notifications
  Future<List<Notification>> getUserNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      Logger.info(
          'Retrieved ${snapshot.docs.length} notifications for user: $userId');

      return snapshot.docs
          .map((doc) => Notification.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Error getting user notifications: $e');
      throw Exception('Failed to get user notifications: $e');
    }
  }

  // Get unread notification count
  Future<int?> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count;
    } catch (e) {
      Logger.error('Error getting unread notification count: $e');
      // Return 0 instead of throwing to prevent UI issues
      return 0;
    }
  }
}
