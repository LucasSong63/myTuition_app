import 'package:equatable/equatable.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/activity.dart';

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

// Updated to include activities
class CourseDetailsLoaded extends CourseState {
  final Course course;
  final List<Activity>? recentActivities; // Add this field

  const CourseDetailsLoaded({
    required this.course,
    this.recentActivities,
  });

  // Add copyWith method
  CourseDetailsLoaded copyWith({
    Course? course,
    List<Activity>? recentActivities,
  }) {
    return CourseDetailsLoaded(
      course: course ?? this.course,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }

  @override
  List<Object?> get props => [course, recentActivities];
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

class CourseActionSuccess extends CourseState {
  final String message;

  const CourseActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

// Keep this for backward compatibility but it's no longer primary
class RecentActivitiesLoaded extends CourseState {
  final List<Activity> activities;

  const RecentActivitiesLoaded({required this.activities});

  @override
  List<Object?> get props => [activities];
}
