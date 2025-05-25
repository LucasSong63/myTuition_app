// lib/features/courses/data/models/schedule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/schedule.dart';

class ScheduleModel extends Schedule {
  const ScheduleModel({
    required String id,
    required String courseId,
    required DateTime startTime,
    required DateTime endTime,
    required String day,
    required String location,
    required String subject,
    required int grade,
    ScheduleType type = ScheduleType.regular,
    DateTime? specificDate,
    String? replacesDate,
    String? reason,
    bool isActive = true,
    DateTime? createdAt,
  }) : super(
          id: id,
          courseId: courseId,
          startTime: startTime,
          endTime: endTime,
          day: day,
          location: location,
          subject: subject,
          grade: grade,
          type: type,
          specificDate: specificDate,
          replacesDate: replacesDate,
          reason: reason,
          isActive: isActive,
          createdAt: createdAt,
        );

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String docId,
      {required String courseId, required String subject, required int grade}) {
    DateTime startTime;
    if (map['startTime'] is Timestamp) {
      startTime = (map['startTime'] as Timestamp).toDate();
    } else {
      startTime = DateTime.now();
    }

    DateTime endTime;
    if (map['endTime'] is Timestamp) {
      endTime = (map['endTime'] as Timestamp).toDate();
    } else {
      endTime = DateTime.now().add(const Duration(hours: 1));
    }

    // Parse schedule type (default to regular for backward compatibility)
    ScheduleType type = ScheduleType.regular;
    if (map['type'] != null) {
      switch (map['type'] as String) {
        case 'replacement':
          type = ScheduleType.replacement;
          break;
        case 'extension':
          type = ScheduleType.extension;
          break;
        case 'cancelled':
          type = ScheduleType.cancelled;
          break;
        default:
          type = ScheduleType.regular;
      }
    }

    // Parse specific date for replacement schedules
    DateTime? specificDate;
    if (map['specificDate'] is Timestamp) {
      specificDate = (map['specificDate'] as Timestamp).toDate();
    }

    // Parse created at
    DateTime? createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    }

    return ScheduleModel(
      id: map['id'] ?? docId,
      courseId: courseId,
      startTime: startTime,
      endTime: endTime,
      day: map['day'] ?? '',
      location: map['location'] ?? '',
      subject: subject,
      grade: grade,
      type: type,
      specificDate: specificDate,
      replacesDate: map['replacesDate'] as String?,
      reason: map['reason'] as String?,
      isActive: map['isActive'] ?? true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'courseId': courseId,
      'startTime': startTime,
      'endTime': endTime,
      'day': day,
      'location': location,
      'type': type.toString().split('.').last, // Convert enum to string
      'isActive': isActive,
    };

    // Add optional fields only if they have values
    if (specificDate != null) {
      map['specificDate'] = specificDate;
    }
    if (replacesDate != null) {
      map['replacesDate'] = replacesDate;
    }
    if (reason != null) {
      map['reason'] = reason;
    }
    if (createdAt != null) {
      map['createdAt'] = createdAt;
    }

    return map;
  }

  /// Create a regular schedule from basic parameters
  factory ScheduleModel.createRegular({
    required String id,
    required String courseId,
    required String day,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String subject,
    required int grade,
  }) {
    return ScheduleModel(
      id: id,
      courseId: courseId,
      startTime: startTime,
      endTime: endTime,
      day: day,
      location: location,
      subject: subject,
      grade: grade,
      type: ScheduleType.regular,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Create a replacement schedule
  factory ScheduleModel.createReplacement({
    required String id,
    required String courseId,
    required DateTime specificDate,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String subject,
    required int grade,
    String? replacesDate,
    String? reason,
  }) {
    // For replacement schedules, the day should match the specific date
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[specificDate.weekday - 1];

    return ScheduleModel(
      id: id,
      courseId: courseId,
      startTime: startTime,
      endTime: endTime,
      day: dayName,
      location: location,
      subject: subject,
      grade: grade,
      type: ScheduleType.replacement,
      specificDate: specificDate,
      replacesDate: replacesDate,
      reason: reason,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Create an extension schedule (extending existing class time)
  factory ScheduleModel.createExtension({
    required String id,
    required String courseId,
    required String day,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String subject,
    required int grade,
    String? reason,
    DateTime? specificDate,
  }) {
    return ScheduleModel(
      id: id,
      courseId: courseId,
      startTime: startTime,
      endTime: endTime,
      day: day,
      location: location,
      subject: subject,
      grade: grade,
      type: ScheduleType.extension,
      specificDate: specificDate,
      reason: reason,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}
