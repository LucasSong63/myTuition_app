import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required String id,
    required String courseId,
    required String studentId,
    required DateTime date,
    required AttendanceStatus status,
    String? remarks,
    required DateTime createdAt,
    required DateTime updatedAt,
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

    return AttendanceModel(
      id: docId,
      courseId: map['courseId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: parseTimestamp(map['date']),
      status: getStatus(map['status']),
      remarks: map['remarks'],
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
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

    return {
      'courseId': courseId,
      'studentId': studentId,
      'date': date,
      'status': getStatusString(status),
      'remarks': remarks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
