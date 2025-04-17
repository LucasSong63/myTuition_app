import 'package:equatable/equatable.dart';
import 'schedule.dart';

class Course extends Equatable {
  final String id;
  final String subject;
  final int grade;
  final String tutorId;
  final String tutorName;
  final List<Schedule> schedules;
  final bool isActive;

  const Course({
    required this.id,
    required this.subject,
    required this.grade,
    required this.tutorId,
    required this.tutorName,
    this.schedules = const [],
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [id, subject, grade, tutorId, tutorName, schedules, isActive];
}
