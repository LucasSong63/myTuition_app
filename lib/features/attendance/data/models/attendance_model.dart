// lib/features/attendance/data/models/attendance_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  final Map<String, dynamic>? scheduleMetadata;

  const AttendanceModel({
    required String id,
    required String courseId,
    required String studentId,
    required DateTime date,
    required AttendanceStatus status,
    String? remarks,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.scheduleMetadata,
  }) : super(
          id: id,
          courseId: courseId,
          studentId: studentId,
          date: date,
          status: status,
          remarks: remarks,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    // Convert string status to enum
    AttendanceStatus getStatus(String? statusStr) {
      switch (statusStr) {
        case 'present':
          return AttendanceStatus.present;
        case 'absent':
          return AttendanceStatus.absent;
        case 'late':
          return AttendanceStatus.late;
        case 'excused':
          return AttendanceStatus.excused;
        default:
          return AttendanceStatus.absent; // Default value
      }
    }

    // Handle Firestore timestamps
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return DateTime.now();
    }

    // FIXED: Extract scheduleMetadata from Firebase
    Map<String, dynamic>? scheduleMetadata;
    if (map['scheduleMetadata'] != null) {
      scheduleMetadata =
          Map<String, dynamic>.from(map['scheduleMetadata'] as Map);
    }

    return AttendanceModel(
      id: docId,
      courseId: map['courseId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: parseTimestamp(map['date']),
      status: getStatus(map['status']),
      remarks: map['remarks'],
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
      scheduleMetadata: scheduleMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    // Convert enum status to string
    String getStatusString(AttendanceStatus status) {
      switch (status) {
        case AttendanceStatus.present:
          return 'present';
        case AttendanceStatus.absent:
          return 'absent';
        case AttendanceStatus.late:
          return 'late';
        case AttendanceStatus.excused:
          return 'excused';
      }
    }

    final map = {
      'courseId': courseId,
      'studentId': studentId,
      'date': date,
      'status': getStatusString(status),
      'remarks': remarks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    // Add scheduleMetadata if available
    if (scheduleMetadata != null) {
      map['scheduleMetadata'] = scheduleMetadata!;
    }

    return map;
  }

  // Helper methods to access schedule information easily
  String? get scheduleId => scheduleMetadata?['scheduleId'];

  String? get scheduleDay => scheduleMetadata?['scheduleDay'];

  String? get scheduleLocation => scheduleMetadata?['scheduleLocation'];

  String? get scheduleType => scheduleMetadata?['scheduleType'];

  // FIXED: Proper schedule time parsing
  DateTime? get scheduleStartTime {
    if (scheduleMetadata?['scheduleStartTime'] != null) {
      try {
        return DateTime.parse(scheduleMetadata!['scheduleStartTime'] as String);
      } catch (e) {
        print('Error parsing scheduleStartTime: $e');
        return null;
      }
    }
    return null;
  }

  DateTime? get scheduleEndTime {
    if (scheduleMetadata?['scheduleEndTime'] != null) {
      try {
        return DateTime.parse(scheduleMetadata!['scheduleEndTime'] as String);
      } catch (e) {
        print('Error parsing scheduleEndTime: $e');
        return null;
      }
    }
    return null;
  }

  // Get formatted time display
  String get scheduleTimeDisplay {
    final start = scheduleStartTime;
    final end = scheduleEndTime;

    if (start != null && end != null) {
      final startTime = _formatTime(start);
      final endTime = _formatTime(end);
      return '$startTime - $endTime';
    }

    return 'Session Time';
  }

  // Helper to format time consistently
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }

  // Create a copy with updated schedule metadata
  AttendanceModel copyWith({
    String? id,
    String? courseId,
    String? studentId,
    DateTime? date,
    AttendanceStatus? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? scheduleMetadata,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduleMetadata: scheduleMetadata ?? this.scheduleMetadata,
    );
  }
}
