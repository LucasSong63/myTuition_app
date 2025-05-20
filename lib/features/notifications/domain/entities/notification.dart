// lib/features/notifications/domain/entities/notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;

  const Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });

  // Factory constructor for Firestore
  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract timestamp or use fallback date if missing
    final timestamp = data['createdAt'];
    final DateTime createdAt;

    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else {
      // Fallback to current date if timestamp is missing or invalid
      createdAt = DateTime.now();
    }

    // Extract read timestamp if available
    final readTimestamp = data['readAt'];
    final DateTime? readAt =
        readTimestamp is Timestamp ? readTimestamp.toDate() : null;

    return Notification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: createdAt,
      readAt: readAt,
      data: data['data'] ?? {},
    );
  }

  // Create a copy with read status
  Notification markAsRead() {
    return Notification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: true,
      createdAt: createdAt,
      readAt: DateTime.now(),
      data: data,
    );
  }

  // Create a copy with modified properties
  Notification copyWith({
    String? userId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, type, title, message, isRead, createdAt, readAt, data];
}
