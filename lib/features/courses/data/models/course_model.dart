// lib/features/courses/data/models/course_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';
import 'schedule_model.dart';

class CourseModel extends Course {
  const CourseModel({
    required String id,
    required String subject,
    required int grade,
    required String tutorId,
    required String tutorName,
    List<Schedule> schedules = const [],
    bool isActive = true,
    int capacity = 20,
    List<String> students = const [],
  }) : super(
          id: id,
          subject: subject,
          grade: grade,
          tutorId: tutorId,
          tutorName: tutorName,
          schedules: schedules,
          isActive: isActive,
          capacity: capacity,
          students: students,
        );

  factory CourseModel.fromMap(Map<String, dynamic> map, String docId) {
    List<Schedule> schedules = [];

    if (map['schedules'] != null) {
      final schedulesList = map['schedules'] as List<dynamic>;
      for (int i = 0; i < schedulesList.length; i++) {
        final scheduleMap = schedulesList[i] as Map<String, dynamic>;
        schedules.add(
          ScheduleModel.fromMap(
            scheduleMap,
            '$docId-schedule-$i',
            courseId: docId,
            subject: map['subject'] ?? '',
            grade: map['grade'] ?? 0,
          ),
        );
      }
    }

    // Extract students list
    List<String> students = [];
    if (map['students'] != null) {
      students = List<String>.from(map['students']);
    }

    return CourseModel(
      id: docId,
      subject: map['subject'] ?? '',
      grade: map['grade'] ?? 0,
      tutorId: map['tutorId'] ?? '',
      tutorName: map['tutorName'] ?? '',
      schedules: schedules,
      isActive: map['isActive'] ?? true,
      capacity: map['capacity'] ?? 20,
      students: students,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'grade': grade,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'schedules': schedules.map((schedule) {
        if (schedule is ScheduleModel) {
          return schedule.toMap();
        }
        return {};
      }).toList(),
      'isActive': isActive,
      'capacity': capacity,
      'students': students,
    };
  }
}
