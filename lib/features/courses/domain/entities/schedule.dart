// lib/features/courses/domain/entities/schedule.dart
import 'package:equatable/equatable.dart';

enum ScheduleType {
  regular, // Weekly recurring schedule
  replacement, // One-time makeup class
  extension, // Extension of existing class
  cancelled, // Cancelled class
}

class Schedule extends Equatable {
  final String id;
  final String courseId;
  final DateTime startTime;
  final DateTime endTime;
  final String day;
  final String location;
  final String subject;
  final int grade;

  // New fields for replacement schedules
  final ScheduleType type;
  final DateTime? specificDate; // For one-time schedules (replacement)
  final String?
      replacesDate; // Which original class this replaces (YYYY-MM-DD format)
  final String? reason; // Reason for replacement
  final bool isActive; // Can disable without deleting
  final DateTime? createdAt; // When this schedule was created

  const Schedule({
    required this.id,
    required this.courseId,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.location,
    required this.subject,
    required this.grade,
    this.type = ScheduleType.regular,
    this.specificDate,
    this.replacesDate,
    this.reason,
    this.isActive = true,
    this.createdAt,
  });

  // Helper methods
  bool get isRegular => type == ScheduleType.regular;

  bool get isReplacement => type == ScheduleType.replacement;

  bool get isExtension => type == ScheduleType.extension;

  /// Check if this replacement schedule is expired (past its specific date)
  bool get isExpired {
    if (type != ScheduleType.replacement || specificDate == null) {
      return false;
    }
    final today = DateTime.now();
    final scheduleDate = DateTime(
      specificDate!.year,
      specificDate!.month,
      specificDate!.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return scheduleDate.isBefore(todayDate);
  }

  /// Check if this schedule is relevant for a specific date
  bool isRelevantForDate(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);

    if (type == ScheduleType.replacement) {
      // Replacement schedules are only relevant on their specific date
      if (specificDate == null) return false;
      final scheduleDate = DateTime(
        specificDate!.year,
        specificDate!.month,
        specificDate!.day,
      );
      return scheduleDate.isAtSameMomentAs(checkDate);
    } else {
      // Regular schedules are relevant if the day matches
      final dayOfWeek = _getDayOfWeek(date);
      return day.toLowerCase() == dayOfWeek.toLowerCase() && isActive;
    }
  }

  /// Get day of week name from DateTime
  String _getDayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  /// Get display title for the schedule
  String get displayTitle {
    switch (type) {
      case ScheduleType.regular:
        return '$day Class';
      case ScheduleType.replacement:
        return 'Replacement Class${reason != null ? ' ($reason)' : ''}';
      case ScheduleType.extension:
        return 'Extended Class${reason != null ? ' ($reason)' : ''}';
      case ScheduleType.cancelled:
        return 'Cancelled Class';
    }
  }

  /// Get display subtitle with more details
  String get displaySubtitle {
    if (type == ScheduleType.replacement && specificDate != null) {
      final dateStr =
          '${specificDate!.day}/${specificDate!.month}/${specificDate!.year}';
      if (replacesDate != null) {
        return 'Makeup for $replacesDate on $dateStr';
      }
      return 'One-time class on $dateStr';
    }
    return location;
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        startTime,
        endTime,
        day,
        location,
        subject,
        grade,
        type,
        specificDate,
        replacesDate,
        reason,
        isActive,
        createdAt,
      ];

  /// Copy with method for creating modified instances
  Schedule copyWith({
    String? id,
    String? courseId,
    DateTime? startTime,
    DateTime? endTime,
    String? day,
    String? location,
    String? subject,
    int? grade,
    ScheduleType? type,
    DateTime? specificDate,
    String? replacesDate,
    String? reason,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      day: day ?? this.day,
      location: location ?? this.location,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      type: type ?? this.type,
      specificDate: specificDate ?? this.specificDate,
      replacesDate: replacesDate ?? this.replacesDate,
      reason: reason ?? this.reason,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
