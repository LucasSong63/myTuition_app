import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/courses/domain/usecases/add_schedule_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/delete_schedule_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/get_tutor_courses_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/update_course_active_status_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/update_course_capacity_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/update_schedule_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/get_recent_activities_usecase.dart';
import '../../domain/usecases/get_course_by_id_usecase.dart';
import '../../domain/usecases/get_enrolled_courses_usecase.dart';
import '../../domain/usecases/get_upcoming_schedules_usecase.dart';
import 'course_event.dart';
import 'course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetEnrolledCoursesUseCase getEnrolledCoursesUseCase;
  final GetCourseByIdUseCase getCourseByIdUseCase;
  final GetUpcomingSchedulesUseCase getUpcomingSchedulesUseCase;
  final GetTutorCoursesUseCase getTutorCoursesUseCase;
  final AddScheduleUseCase addScheduleUseCase;
  final UpdateScheduleUseCase updateScheduleUseCase;
  final DeleteScheduleUseCase deleteScheduleUseCase;
  final UpdateCourseActiveStatusUseCase updateCourseActiveStatusUseCase;
  final UpdateCourseCapacityUseCase updateCourseCapacityUseCase;
  final GetRecentActivitiesUseCase getRecentActivitiesUseCase;

  CourseBloc({
    required this.getEnrolledCoursesUseCase,
    required this.getCourseByIdUseCase,
    required this.getUpcomingSchedulesUseCase,
    required this.getTutorCoursesUseCase,
    required this.addScheduleUseCase,
    required this.updateScheduleUseCase,
    required this.deleteScheduleUseCase,
    required this.updateCourseActiveStatusUseCase,
    required this.updateCourseCapacityUseCase,
    required this.getRecentActivitiesUseCase,
  }) : super(CourseInitial()) {
    on<LoadEnrolledCoursesEvent>(_onLoadEnrolledCourses);
    on<LoadCourseDetailsEvent>(_onLoadCourseDetails);
    on<LoadUpcomingSchedulesEvent>(_onLoadUpcomingSchedules);
    on<LoadTutorCoursesEvent>(_onLoadTutorCourses);
    on<AddScheduleEvent>(_onAddSchedule);
    on<UpdateScheduleEvent>(_onUpdateSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
    on<UpdateCourseActiveStatusEvent>(_onUpdateCourseActiveStatus);
    on<UpdateCourseCapacityEvent>(_onUpdateCourseCapacity);
    on<LoadRecentActivitiesEvent>(_onLoadRecentActivities);
  }

  Future<void> _onLoadEnrolledCourses(
    LoadEnrolledCoursesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final courses = await getEnrolledCoursesUseCase.execute(event.studentId);
      emit(CoursesLoaded(courses: courses));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onLoadCourseDetails(
    LoadCourseDetailsEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final course = await getCourseByIdUseCase.execute(event.courseId);
      emit(CourseDetailsLoaded(course: course));

      // Automatically load recent activities after course details
      add(LoadRecentActivitiesEvent(courseId: event.courseId));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onLoadUpcomingSchedules(
    LoadUpcomingSchedulesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final schedules =
          await getUpcomingSchedulesUseCase.execute(event.studentId);
      emit(SchedulesLoaded(schedules: schedules));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onLoadTutorCourses(
    LoadTutorCoursesEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      // Use the new use case
      final courses = await getTutorCoursesUseCase.execute(event.tutorId);
      emit(CoursesLoaded(courses: courses));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onAddSchedule(
    AddScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      await addScheduleUseCase.execute(event.courseId, event.schedule);
      emit(const CourseActionSuccess(message: 'Schedule added successfully'));
      add(LoadCourseDetailsEvent(courseId: event.courseId));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      await updateScheduleUseCase.execute(
        event.courseId,
        event.scheduleId,
        event.updatedSchedule,
      );
      emit(const CourseActionSuccess(message: 'Schedule updated successfully'));
      add(LoadCourseDetailsEvent(courseId: event.courseId));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSchedule(
    DeleteScheduleEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      await deleteScheduleUseCase.execute(event.courseId, event.scheduleId);
      emit(const CourseActionSuccess(message: 'Schedule deleted successfully'));
      add(LoadCourseDetailsEvent(courseId: event.courseId));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCourseActiveStatus(
    UpdateCourseActiveStatusEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      await updateCourseActiveStatusUseCase.execute(
        event.courseId,
        event.isActive,
      );
      emit(CourseActionSuccess(
        message: event.isActive
            ? 'Course activated successfully'
            : 'Course deactivated successfully',
      ));
      add(LoadCourseDetailsEvent(courseId: event.courseId));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCourseCapacity(
    UpdateCourseCapacityEvent event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      await updateCourseCapacityUseCase.execute(
        event.courseId,
        event.capacity,
      );
      emit(CourseActionSuccess(
        message: 'Class capacity updated to ${event.capacity} students',
      ));
      add(LoadCourseDetailsEvent(courseId: event.courseId));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> _onLoadRecentActivities(
    LoadRecentActivitiesEvent event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final activities =
          await getRecentActivitiesUseCase.execute(event.courseId);

      // If current state is CourseDetailsLoaded, update it with activities
      if (state is CourseDetailsLoaded) {
        final currentState = state as CourseDetailsLoaded;
        emit(currentState.copyWith(recentActivities: activities));
      } else {
        // Otherwise emit the separate state (for backward compatibility)
        emit(RecentActivitiesLoaded(activities: activities));
      }
    } catch (e) {
      print('Error loading recent activities: $e');
      // Don't emit error state to avoid disrupting the UI
      // Just log the error
    }
  }
}
