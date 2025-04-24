// lib/features/courses/presentation/bloc/course_event.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/schedule.dart';

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

class LoadTutorCoursesEvent extends CourseEvent {
  final String tutorId;

  const LoadTutorCoursesEvent({required this.tutorId});

  @override
  List<Object?> get props => [tutorId];
}

class AddScheduleEvent extends CourseEvent {
  final String courseId;
  final Schedule schedule;

  const AddScheduleEvent({
    required this.courseId,
    required this.schedule,
  });

  @override
  List<Object?> get props => [courseId, schedule];
}

class UpdateScheduleEvent extends CourseEvent {
  final String courseId;
  final String scheduleId;
  final Schedule updatedSchedule;

  const UpdateScheduleEvent({
    required this.courseId,
    required this.scheduleId,
    required this.updatedSchedule,
  });

  @override
  List<Object?> get props => [courseId, scheduleId, updatedSchedule];
}

class DeleteScheduleEvent extends CourseEvent {
  final String courseId;
  final String scheduleId;

  const DeleteScheduleEvent({
    required this.courseId,
    required this.scheduleId,
  });

  @override
  List<Object?> get props => [courseId, scheduleId];
}

class UpdateCourseActiveStatusEvent extends CourseEvent {
  final String courseId;
  final bool isActive;

  const UpdateCourseActiveStatusEvent({
    required this.courseId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [courseId, isActive];
}

class UpdateCourseCapacityEvent extends CourseEvent {
  final String courseId;
  final int capacity;

  const UpdateCourseCapacityEvent({
    required this.courseId,
    required this.capacity,
  });

  @override
  List<Object?> get props => [courseId, capacity];
}
