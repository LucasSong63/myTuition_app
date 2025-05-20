// lib/features/notifications/domain/repositories/notification_repository.dart

import '../entities/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/paginated_result.dart';

abstract class NotificationRepository {
  /// Creates a new notification
  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  });

  /// Marks a single notification as read
  Future<void> markNotificationAsRead(String notificationId);

  /// Marks all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId);

  /// Gets user notifications with pagination support
  Future<PaginatedResult<Notification>> getUserNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? filter,
    bool sortDescending = true,
  });

  /// Gets the unread notification count for a user (one-time)
  Future<int?> getUnreadNotificationCount(String userId);

  /// Gets a stream of unread notification counts for a user (real-time)
  Stream<int> getUnreadNotificationCountStream(String userId);

  /// Gets archived notifications for a user (if available)
  Future<PaginatedResult<Notification>> getArchivedNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? filter,
    bool sortDescending = true,
  });
}
