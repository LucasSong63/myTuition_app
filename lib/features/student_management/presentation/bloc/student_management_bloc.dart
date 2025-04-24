import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_event.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_state.dart';
import '../../domain/usecases/get_all_students_usecase.dart';
import '../../domain/usecases/get_student_by_id_usecase.dart';
import '../../domain/usecases/get_enrolled_courses_usecase.dart';
import '../../domain/usecases/get_available_courses_usecase.dart';
import '../../domain/usecases/enroll_student_in_course_usecase.dart';
import '../../domain/usecases/remove_student_from_course_usecase.dart';
import '../../domain/usecases/update_student_profile_usecase.dart';

class StudentManagementBloc
    extends Bloc<StudentManagementEvent, StudentManagementState> {
  final GetAllStudentsUseCase getAllStudentsUseCase;
  final GetStudentByIdUseCase getStudentByIdUseCase;
  final GetEnrolledCoursesUseCase getEnrolledCoursesUseCase;
  final GetAvailableCoursesUseCase getAvailableCoursesUseCase;
  final EnrollStudentInCourseUseCase enrollStudentInCourseUseCase;
  final RemoveStudentFromCourseUseCase removeStudentFromCourseUseCase;
  final UpdateStudentProfileUseCase updateStudentProfileUseCase;

  StudentManagementBloc({
    required this.getAllStudentsUseCase,
    required this.getStudentByIdUseCase,
    required this.getEnrolledCoursesUseCase,
    required this.getAvailableCoursesUseCase,
    required this.enrollStudentInCourseUseCase,
    required this.removeStudentFromCourseUseCase,
    required this.updateStudentProfileUseCase,
  }) : super(StudentManagementInitial()) {
    on<LoadAllStudentsEvent>(_onLoadAllStudents);
    on<LoadStudentDetailsEvent>(_onLoadStudentDetails);
    on<LoadEnrolledCoursesEvent>(_onLoadEnrolledCourses);
    on<LoadAvailableCoursesEvent>(_onLoadAvailableCourses);
    on<EnrollStudentEvent>(_onEnrollStudent);
    on<RemoveStudentFromCourseEvent>(_onRemoveStudentFromCourse);
    on<UpdateStudentProfileEvent>(_onUpdateStudentProfile);
  }

  Future<void> _onLoadAllStudents(
    LoadAllStudentsEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    emit(StudentManagementLoading());

    try {
      final students = await getAllStudentsUseCase.execute();
      emit(AllStudentsLoaded(students: students));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }

  Future<void> _onLoadStudentDetails(
    LoadStudentDetailsEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    emit(StudentManagementLoading());

    try {
      final student = await getStudentByIdUseCase.execute(event.studentId);
      emit(StudentDetailsLoaded(student: student));

      // Also load enrolled courses
      add(LoadEnrolledCoursesEvent(studentId: student.studentId));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }

  Future<void> _onLoadEnrolledCourses(
    LoadEnrolledCoursesEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    // Check if already loaded
    if (state is EnrolledCoursesLoaded &&
        (state as EnrolledCoursesLoaded).studentId == event.studentId) {
      return; // Already loaded
    }

    // Only emit loading if we don't have the specific data yet
    if (!(state is EnrolledCoursesLoaded) ||
        (state as EnrolledCoursesLoaded).studentId != event.studentId) {
      emit(StudentManagementLoading());
    }

    try {
      final enrolledCourses =
          await getEnrolledCoursesUseCase.execute(event.studentId);
      emit(EnrolledCoursesLoaded(
        studentId: event.studentId,
        enrolledCourses: enrolledCourses,
      ));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }

  Future<void> _onLoadAvailableCourses(
    LoadAvailableCoursesEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    // Check if we already have the available courses for this student
    // to avoid unnecessary state transitions
    if (state is AvailableCoursesLoaded &&
        (state as AvailableCoursesLoaded).studentId == event.studentId) {
      return; // Already loaded, don't emit new state to prevent flicker
    }

    // Only emit loading state if we don't already have data
    if (!(state is AvailableCoursesLoaded) ||
        (state as AvailableCoursesLoaded).studentId != event.studentId) {
      emit(StudentManagementLoading());
    }

    try {
      final availableCourses =
          await getAvailableCoursesUseCase.execute(event.studentId);

      // Always emit the new available courses state
      emit(AvailableCoursesLoaded(
        studentId: event.studentId,
        availableCourses: availableCourses,
      ));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }

  Future<void> _onEnrollStudent(
    EnrollStudentEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    emit(StudentManagementLoading(operation: 'enrolling'));

    try {
      await enrollStudentInCourseUseCase.execute(
        event.studentId,
        event.courseId,
      );

      emit(const StudentManagementActionSuccess(
        message: 'Student enrolled successfully',
      ));

      // Immediately fetch and emit the updated enrolled courses
      // This ensures the UI will update with the new course
      final enrolledCourses =
          await getEnrolledCoursesUseCase.execute(event.studentId);

      emit(EnrolledCoursesLoaded(
        studentId: event.studentId,
        enrolledCourses: enrolledCourses,
      ));

      // Then reload available courses as they've changed too
      final availableCourses =
          await getAvailableCoursesUseCase.execute(event.studentId);

      emit(AvailableCoursesLoaded(
        studentId: event.studentId,
        availableCourses: availableCourses,
      ));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }

  Future<void> _onRemoveStudentFromCourse(
    RemoveStudentFromCourseEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    emit(StudentManagementLoading());

    try {
      await removeStudentFromCourseUseCase.execute(
        event.studentId,
        event.courseId,
      );

      emit(const StudentManagementActionSuccess(
        message: 'Student removed from course successfully',
      ));

      // Reload enrolled courses
      add(LoadEnrolledCoursesEvent(studentId: event.studentId));
      add(LoadAvailableCoursesEvent(studentId: event.studentId));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }

  Future<void> _onUpdateStudentProfile(
    UpdateStudentProfileEvent event,
    Emitter<StudentManagementState> emit,
  ) async {
    emit(StudentManagementLoading());

    try {
      await updateStudentProfileUseCase.execute(
        userId: event.userId,
        name: event.name,
        phone: event.phone,
        grade: event.grade,
        subjects: event.subjects,
      );

      emit(const StudentManagementActionSuccess(
        message: 'Student profile updated successfully',
      ));

      // Reload student details
      add(LoadStudentDetailsEvent(studentId: event.userId));
    } catch (e) {
      emit(StudentManagementError(message: e.toString()));
    }
  }
}
