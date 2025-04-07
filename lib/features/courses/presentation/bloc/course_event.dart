// lib/features/courses/presentation/bloc/course_event.dart
import 'package:equatable/equatable.dart';

abstract class CourseEvent extends Equatable {
  const CourseEvent();

  @override
  List<Object?> get props => [];
}

class LoadEnrolledCoursesEvent extends CourseEvent {
  final String studentId;

  const LoadEnrolledCoursesEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class LoadCourseDetailsEvent extends CourseEvent {
  final String courseId;

  const LoadCourseDetailsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class LoadUpcomingSchedulesEvent extends CourseEvent {
  final String studentId;

  const LoadUpcomingSchedulesEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}
