import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/usecases/get_all_student_attendance_usecase.dart';
import 'student_attendance_history_event.dart';
import 'student_attendance_history_state.dart';

class StudentAttendanceHistoryBloc
    extends Bloc<StudentAttendanceHistoryEvent, StudentAttendanceHistoryState> {
  final GetAllStudentAttendanceUseCase getAllStudentAttendanceUseCase;

  StudentAttendanceHistoryBloc({
    required this.getAllStudentAttendanceUseCase,
  }) : super(StudentAttendanceHistoryInitial()) {
    on<LoadStudentAttendanceHistoryEvent>(_onLoadStudentAttendanceHistory);
    on<FilterAttendanceByStatusEvent>(_onFilterByStatus);
    on<FilterAttendanceByCourseEvent>(_onFilterByCourse);
    on<FilterAttendanceByDateRangeEvent>(_onFilterByDateRange);
  }

  Future<void> _onLoadStudentAttendanceHistory(
    LoadStudentAttendanceHistoryEvent event,
    Emitter<StudentAttendanceHistoryState> emit,
  ) async {
    emit(StudentAttendanceHistoryLoading());

    try {
      final attendanceList = await getAllStudentAttendanceUseCase.execute(event.studentId);
      
      // Convert Attendance to AttendanceModel
      final attendanceModels = attendanceList.map((attendance) {
        if (attendance is AttendanceModel) {
          return attendance;
        } else {
          // Create AttendanceModel from Attendance entity
          return AttendanceModel(
            id: attendance.id,
            courseId: attendance.courseId,
            studentId: attendance.studentId,
            date: attendance.date,
            status: attendance.status,
            remarks: attendance.remarks,
            createdAt: attendance.createdAt,
            updatedAt: attendance.updatedAt,
          );
        }
      }).toList();

      // Sort by date descending (most recent first)
      attendanceModels.sort((a, b) => b.date.compareTo(a.date));

      // Calculate statistics
      final statistics = _calculateStatistics(attendanceModels);

      emit(StudentAttendanceHistoryLoaded(
        allAttendance: attendanceModels,
        filteredAttendance: attendanceModels,
        statistics: statistics,
      ));
    } catch (e) {
      emit(StudentAttendanceHistoryError(message: e.toString()));
    }
  }

  Future<void> _onFilterByStatus(
    FilterAttendanceByStatusEvent event,
    Emitter<StudentAttendanceHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is StudentAttendanceHistoryLoaded) {
      final filtered = _applyFilters(
        currentState.allAttendance,
        statusFilter: event.statusFilter,
        courseFilter: currentState.activeCourseFilter,
        startDate: currentState.startDateFilter,
        endDate: currentState.endDateFilter,
      );

      emit(currentState.copyWith(
        filteredAttendance: filtered,
        activeStatusFilter: event.statusFilter,
      ));
    }
  }

  Future<void> _onFilterByCourse(
    FilterAttendanceByCourseEvent event,
    Emitter<StudentAttendanceHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is StudentAttendanceHistoryLoaded) {
      final filtered = _applyFilters(
        currentState.allAttendance,
        statusFilter: currentState.activeStatusFilter,
        courseFilter: event.courseFilter,
        startDate: currentState.startDateFilter,
        endDate: currentState.endDateFilter,
      );

      emit(currentState.copyWith(
        filteredAttendance: filtered,
        activeCourseFilter: event.courseFilter,
      ));
    }
  }

  Future<void> _onFilterByDateRange(
    FilterAttendanceByDateRangeEvent event,
    Emitter<StudentAttendanceHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is StudentAttendanceHistoryLoaded) {
      final filtered = _applyFilters(
        currentState.allAttendance,
        statusFilter: currentState.activeStatusFilter,
        courseFilter: currentState.activeCourseFilter,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(currentState.copyWith(
        filteredAttendance: filtered,
        startDateFilter: event.startDate,
        endDateFilter: event.endDate,
      ));
    }
  }

  List<AttendanceModel> _applyFilters(
    List<AttendanceModel> attendance, {
    String? statusFilter,
    String? courseFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = attendance;

    // Apply status filter
    if (statusFilter != null && statusFilter.isNotEmpty) {
      filtered = filtered.where((a) => a.status.toString().split('.').last == statusFilter).toList();
    }

    // Apply course filter
    if (courseFilter != null && courseFilter.isNotEmpty) {
      filtered = filtered.where((a) => a.courseId == courseFilter).toList();
    }

    // Apply date range filter
    if (startDate != null) {
      filtered = filtered.where((a) => a.date.isAfter(startDate) || 
          a.date.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((a) => a.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    return filtered;
  }

  Map<String, dynamic> _calculateStatistics(List<AttendanceModel> attendance) {
    if (attendance.isEmpty) {
      return {
        'totalClasses': 0,
        'presentCount': 0,
        'absentCount': 0,
        'lateCount': 0,
        'excusedCount': 0,
        'attendanceRate': 0.0,
      };
    }

    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    int excusedCount = 0;

    for (var record in attendance) {
      switch (record.status) {
        case AttendanceStatus.present:
          presentCount++;
          break;
        case AttendanceStatus.absent:
          absentCount++;
          break;
        case AttendanceStatus.late:
          lateCount++;
          break;
        case AttendanceStatus.excused:
          excusedCount++;
          break;
      }
    }

    final totalClasses = attendance.length;
    final attendanceRate = totalClasses > 0 
        ? ((presentCount + lateCount) / totalClasses * 100) 
        : 0.0;

    return {
      'totalClasses': totalClasses,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'excusedCount': excusedCount,
      'attendanceRate': attendanceRate,
    };
  }
}
