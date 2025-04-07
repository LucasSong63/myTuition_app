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
  }) : super(
          id: id,
          courseId: courseId,
          startTime: startTime,
          endTime: endTime,
          day: day,
          location: location,
          subject: subject,
          grade: grade,
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

    return ScheduleModel(
      id: map['id'] ?? docId,
      courseId: courseId,
      startTime: startTime,
      endTime: endTime,
      day: map['day'] ?? '',
      location: map['location'] ?? '',
      subject: subject,
      // Pass the subject from the course
      grade: grade, // Pass the grade from the course
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'startTime': startTime,
      'endTime': endTime,
      'day': day,
      'location': location,
    };
  }
}
