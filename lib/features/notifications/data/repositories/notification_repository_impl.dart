// lib/features/notifications/data/repositories/notification_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/features/notifications/data/services/notifications_service.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification.dart';
import '../../../../core/models/paginated_result.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService _notificationService;
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl(this._firestore)
      : _notificationService = NotificationService(_firestore);

  @override
  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return _notificationService.createNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
    );
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) {
    return _notificationService.markNotificationAsRead(notificationId);
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) {
    return _notificationService.markAllNotificationsAsRead(userId);
  }

  @override
  Future<PaginatedResult<Notification>> getUserNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? filter,
    bool sortDescending = true,
  }) async {
    try {
      // Start building the query
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId);

      // Apply type filter if specified
      if (filter != null && filter.isNotEmpty) {
        query = query.where('type', isEqualTo: filter);
      }

      // Apply sorting
      query = query.orderBy('createdAt', descending: sortDescending);

      // Apply pagination if startAfter is provided
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Apply limit
      query = query.limit(limit);

      // Execute query
      final snapshot = await query.get();

      // Check if there are more results to load
      bool hasMore = snapshot.docs.length >= limit;

      // Get the last document for pagination
      DocumentSnapshot? lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      // Convert to notification objects
      final notifications =
          snapshot.docs.map((doc) => Notification.fromFirestore(doc)).toList();

      return PaginatedResult<Notification>(
        items: notifications,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      // Return empty result on error
      return PaginatedResult<Notification>(
        items: [],
        hasMore: false,
      );
    }
  }

  @override
  Future<int?> getUnreadNotificationCount(String userId) {
    return _notificationService.getUnreadNotificationCount(userId);
  }

  @override
  Stream<int> getUnreadNotificationCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<PaginatedResult<Notification>> getArchivedNotifications(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? filter,
    bool sortDescending = true,
  }) async {
    try {
      // Start building the query
      Query query = _firestore
          .collection('archived_notifications')
          .where('userId', isEqualTo: userId);

      // Apply type filter if specified
      if (filter != null && filter.isNotEmpty) {
        query = query.where('type', isEqualTo: filter);
      }

      // Apply sorting
      query = query.orderBy('createdAt', descending: sortDescending);

      // Apply pagination if startAfter is provided
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Apply limit
      query = query.limit(limit);

      // Execute query
      final snapshot = await query.get();

      // Check if there are more results to load
      bool hasMore = snapshot.docs.length >= limit;

      // Get the last document for pagination
      DocumentSnapshot? lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      // Convert to notification objects
      final notifications =
          snapshot.docs.map((doc) => Notification.fromFirestore(doc)).toList();

      return PaginatedResult<Notification>(
        items: notifications,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      // Return empty result on error
      return PaginatedResult<Notification>(
        items: [],
        hasMore: false,
      );
    }
  }
}
