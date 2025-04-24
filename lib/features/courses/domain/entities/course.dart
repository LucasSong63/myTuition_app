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
  final int capacity;
  final List<String> students;

  const Course({
    required this.id,
    required this.subject,
    required this.grade,
    required this.tutorId,
    required this.tutorName,
    this.schedules = const [],
    this.isActive = true,
    this.capacity = 20,
    this.students = const [],
  });

  int get enrollmentCount => students.length;

  double get enrollmentPercentage =>
      capacity > 0 ? (students.length / capacity) * 100 : 0;

  bool get isAtCapacity => students.length >= capacity;

  bool get isNearCapacity =>
      capacity > 0 && students.length >= (capacity * 0.8) && !isAtCapacity;

  @override
  List<Object?> get props => [
        id,
        subject,
        grade,
        tutorId,
        tutorName,
        schedules,
        isActive,
        capacity,
        students
      ];
}
