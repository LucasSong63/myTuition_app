import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_attendance_by_date_usecase.dart';
import '../../domain/usecases/get_enrolled_students_usecase.dart';
import '../../domain/usecases/record_bulk_attendance_usecase.dart';
import '../../domain/usecases/get_student_attendance_usecase.dart';
import '../../domain/usecases/get_course_attendance_stats_usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendanceByDateUseCase getAttendanceByDateUseCase;
  final GetEnrolledStudentsUseCase getEnrolledStudentsUseCase;
  final RecordBulkAttendanceUseCase recordBulkAttendanceUseCase;
  final GetStudentAttendanceUseCase getStudentAttendanceUseCase;
  final GetCourseAttendanceStatsUseCase getCourseAttendanceStatsUseCase;

  AttendanceBloc({
    required this.getAttendanceByDateUseCase,
    required this.getEnrolledStudentsUseCase,
    required this.recordBulkAttendanceUseCase,
    required this.getStudentAttendanceUseCase,
    required this.getCourseAttendanceStatsUseCase,
  }) : super(AttendanceInitial()) {
    on<LoadAttendanceByDateEvent>(_onLoadAttendanceByDate);
    on<LoadEnrolledStudentsEvent>(_onLoadEnrolledStudents);
    on<RecordBulkAttendanceEvent>(_onRecordBulkAttendance);
    on<LoadStudentAttendanceEvent>(_onLoadStudentAttendance);
    on<LoadCourseAttendanceStatsEvent>(_onLoadCourseAttendanceStats);
  }

  Future<void> _onLoadAttendanceByDate(
    LoadAttendanceByDateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final attendanceRecords = await getAttendanceByDateUseCase.execute(
        event.courseId,
        event.date,
      );
      emit(AttendanceByDateLoaded(
        attendanceRecords: attendanceRecords,
        date: event.date,
      ));
    } catch (e) {
      // Improved error handling with user-friendly messages
      String errorMessage = 'Failed to load attendance data';

      if (e.toString().contains('permission-denied')) {
        errorMessage =
            'You don\'t have permission to access attendance records';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again';
      }

      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadEnrolledStudents(
    LoadEnrolledStudentsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final students = await getEnrolledStudentsUseCase.execute(event.courseId);
      emit(EnrolledStudentsLoaded(students: students));
    } catch (e) {
      // User-friendly error message
      String errorMessage = 'Failed to load student data';

      if (e.toString().contains('permission-denied')) {
        errorMessage = 'You don\'t have permission to access student data';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again';
      }

      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onRecordBulkAttendance(
    RecordBulkAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      await recordBulkAttendanceUseCase.execute(
        event.courseId,
        event.date,
        event.studentAttendances,
        remarks: event.remarks,
      );
      emit(const AttendanceRecordSuccess(
        message: 'Attendance recorded successfully',
      ));

      // Reload the attendance for this date
      add(LoadAttendanceByDateEvent(
        courseId: event.courseId,
        date: event.date,
      ));
    } catch (e) {
      // User-friendly error message
      String errorMessage = 'Failed to save attendance records';

      if (e.toString().contains('permission-denied')) {
        errorMessage = 'You don\'t have permission to record attendance';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again';
      }

      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadStudentAttendance(
    LoadStudentAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final attendanceRecords = await getStudentAttendanceUseCase.execute(
        event.courseId,
        event.studentId,
      );
      emit(StudentAttendanceLoaded(
        attendanceRecords: attendanceRecords,
        studentId: event.studentId,
      ));
    } catch (e) {
      // User-friendly error message
      String errorMessage = 'Failed to load student attendance history';

      if (e.toString().contains('permission-denied')) {
        errorMessage = 'You don\'t have permission to view attendance history';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again';
      }

      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadCourseAttendanceStats(
    LoadCourseAttendanceStatsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final stats =
          await getCourseAttendanceStatsUseCase.execute(event.courseId);
      emit(CourseAttendanceStatsLoaded(stats: stats));
    } catch (e) {
      // User-friendly error message
      String errorMessage = 'Failed to load attendance statistics';

      if (e.toString().contains('permission-denied')) {
        errorMessage =
            'You don\'t have permission to view attendance statistics';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again';
      }

      emit(AttendanceError(message: errorMessage));
    }
  }
}
