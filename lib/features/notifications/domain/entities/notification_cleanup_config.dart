// lib/features/notifications/domain/entities/notification_cleanup_config.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Configuration for automatic notification cleanup
class NotificationCleanupConfig extends Equatable {
  /// Retention period in days (how long to keep notifications)
  final int retentionPeriodDays;

  /// Whether to archive notifications instead of deleting them
  final bool archiveInsteadOfDelete;

  /// Notification types that should be preserved longer
  final List<String> preservedTypes;

  /// Retention period for preserved types (in days)
  final int preservedTypeRetentionDays;

  /// How often to run the cleanup process (in days)
  final int cleanupFrequencyDays;

  /// When the cleanup was last run
  final DateTime? lastCleanupTime;

  const NotificationCleanupConfig({
    this.retentionPeriodDays = 90,
    this.archiveInsteadOfDelete = true,
    this.preservedTypes = const ['payment_confirmed', 'payment_reminder'],
    this.preservedTypeRetentionDays = 365,
    this.cleanupFrequencyDays = 7,
    this.lastCleanupTime,
  });

  /// Create a config with default values
  factory NotificationCleanupConfig.defaultConfig() {
    return const NotificationCleanupConfig();
  }

  /// Create a config from Firestore data
  factory NotificationCleanupConfig.fromFirestore(Map<String, dynamic> data) {
    final Timestamp? lastCleanupTimestamp = data['lastCleanupTime'];

    return NotificationCleanupConfig(
      retentionPeriodDays: data['retentionPeriodDays'] ?? 90,
      archiveInsteadOfDelete: data['archiveInsteadOfDelete'] ?? true,
      preservedTypes: List<String>.from(
          data['preservedTypes'] ?? ['payment_confirmed', 'payment_reminder']),
      preservedTypeRetentionDays: data['preservedTypeRetentionDays'] ?? 365,
      cleanupFrequencyDays: data['cleanupFrequencyDays'] ?? 7,
      lastCleanupTime: lastCleanupTimestamp?.toDate(),
    );
  }

  /// Convert config to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'retentionPeriodDays': retentionPeriodDays,
      'archiveInsteadOfDelete': archiveInsteadOfDelete,
      'preservedTypes': preservedTypes,
      'preservedTypeRetentionDays': preservedTypeRetentionDays,
      'cleanupFrequencyDays': cleanupFrequencyDays,
      'lastCleanupTime':
          lastCleanupTime != null ? Timestamp.fromDate(lastCleanupTime!) : null,
    };
  }

  /// Create a copy with updated fields
  NotificationCleanupConfig copyWith({
    int? retentionPeriodDays,
    bool? archiveInsteadOfDelete,
    List<String>? preservedTypes,
    int? preservedTypeRetentionDays,
    int? cleanupFrequencyDays,
    DateTime? lastCleanupTime,
  }) {
    return NotificationCleanupConfig(
      retentionPeriodDays: retentionPeriodDays ?? this.retentionPeriodDays,
      archiveInsteadOfDelete:
          archiveInsteadOfDelete ?? this.archiveInsteadOfDelete,
      preservedTypes: preservedTypes ?? this.preservedTypes,
      preservedTypeRetentionDays:
          preservedTypeRetentionDays ?? this.preservedTypeRetentionDays,
      cleanupFrequencyDays: cleanupFrequencyDays ?? this.cleanupFrequencyDays,
      lastCleanupTime: lastCleanupTime ?? this.lastCleanupTime,
    );
  }

  /// Check if a cleanup should be run now based on the last cleanup time
  bool shouldRunCleanupNow() {
    if (lastCleanupTime == null) {
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(lastCleanupTime!);
    return difference.inDays >= cleanupFrequencyDays;
  }

  @override
  List<Object?> get props => [
        retentionPeriodDays,
        archiveInsteadOfDelete,
        preservedTypes,
        preservedTypeRetentionDays,
        cleanupFrequencyDays,
        lastCleanupTime,
      ];
}
