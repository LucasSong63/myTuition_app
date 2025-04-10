import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/courses/domain/usecases/get_tutor_courses_usecase.dart';
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

  CourseBloc({
    required this.getEnrolledCoursesUseCase,
    required this.getCourseByIdUseCase,
    required this.getUpcomingSchedulesUseCase,
    required this.getTutorCoursesUseCase,
  }) : super(CourseInitial()) {
    on<LoadEnrolledCoursesEvent>(_onLoadEnrolledCourses);
    on<LoadCourseDetailsEvent>(_onLoadCourseDetails);
    on<LoadUpcomingSchedulesEvent>(_onLoadUpcomingSchedules);
    on<LoadTutorCoursesEvent>(_onLoadTutorCourses);
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
}
