// lib/features/courses/presentation/bloc/course_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';

abstract class CourseState extends Equatable {
  const CourseState();

  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CoursesLoaded extends CourseState {
  final List<Course> courses;

  const CoursesLoaded({required this.courses});

  @override
  List<Object?> get props => [courses];
}

class CourseDetailsLoaded extends CourseState {
  final Course course;

  const CourseDetailsLoaded({required this.course});

  @override
  List<Object?> get props => [course];
}

class SchedulesLoaded extends CourseState {
  final List<Schedule> schedules;

  const SchedulesLoaded({required this.schedules});

  @override
  List<Object?> get props => [schedules];
}

class CourseError extends CourseState {
  final String message;

  const CourseError({required this.message});

  @override
  List<Object?> get props => [message];
}
