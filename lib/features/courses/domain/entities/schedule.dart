// lib/features/courses/domain/entities/schedule.dart
import 'package:equatable/equatable.dart';

class Schedule extends Equatable {
  final String id;
  final String courseId;
  final DateTime startTime;
  final DateTime endTime;
  final String day;
  final String location;
  final String subject; // Added field for display
  final int grade; // Added field for display

  const Schedule({
    required this.id,
    required this.courseId,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.location,
    required this.subject,
    required this.grade,
  });

  @override
  List<Object?> get props =>
      [id, courseId, startTime, endTime, day, location, subject, grade];
}
