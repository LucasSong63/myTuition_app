// lib/features/courses/domain/entities/activity.dart
import 'package:equatable/equatable.dart';

enum ActivityType {
  attendance,
  task,
  schedule,
}

class Activity extends Equatable {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final String courseId;
  final Map<String, dynamic>? metadata;

  const Activity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.courseId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        createdAt,
        courseId,
        metadata,
      ];

  /// Get relative time string (e.g., "2 hours ago", "Yesterday")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }

  /// Get appropriate icon for activity type
  String get iconName {
    switch (type) {
      case ActivityType.attendance:
        return 'people';
      case ActivityType.task:
        return 'assignment';
      case ActivityType.schedule:
        return 'schedule';
    }
  }

  /// Get appropriate color for activity type
  String get colorType {
    switch (type) {
      case ActivityType.attendance:
        return 'success';
      case ActivityType.task:
        return 'primary';
      case ActivityType.schedule:
        return 'orange';
    }
  }
}
