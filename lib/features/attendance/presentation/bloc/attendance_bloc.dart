// lib/features/attendance/presentation/bloc/attendance_bloc.dart
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/attendance/domain/usecases/check_schedule_attendance_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_schedule_attendance_status_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/update_attendance_usecase.dart';
import 'package:mytuition/features/attendance/domain/utils/schedule_date_utils.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytuition/core/errors/error_handler.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/usecases/get_attendance_by_date_usecase.dart';
import '../../domain/usecases/get_course_schedules_usecase.dart';
import '../../domain/usecases/get_enrolled_students_usecase.dart';
import '../../domain/usecases/get_past_seven_days_attendance_usecase.dart';
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
  final GetCourseSchedulesUseCase getCourseSchedulesUseCase;
  final CheckScheduleAttendanceUseCase checkScheduleAttendanceUseCase;
  final GetScheduleAttendanceStatusUseCase getScheduleAttendanceStatusUseCase;
  final GetPast7DaysAttendanceUseCase getPast7DaysAttendanceUseCase;
  final UpdateAttendanceUseCase updateAttendanceUseCase;

  AttendanceBloc({
    required this.getAttendanceByDateUseCase,
    required this.getEnrolledStudentsUseCase,
    required this.recordBulkAttendanceUseCase,
    required this.getStudentAttendanceUseCase,
    required this.getCourseAttendanceStatsUseCase,
    required this.getCourseSchedulesUseCase,
    // NEW: Add these to constructor
    required this.checkScheduleAttendanceUseCase,
    required this.getScheduleAttendanceStatusUseCase,
    required this.getPast7DaysAttendanceUseCase,
    required this.updateAttendanceUseCase,
  }) : super(AttendanceInitial()) {
    // Existing event handlers
    on<LoadAttendanceByDateEvent>(_onLoadAttendanceByDate);
    on<LoadEnrolledStudentsEvent>(_onLoadEnrolledStudents);
    on<LoadStudentAttendanceEvent>(_onLoadStudentAttendance);
    on<LoadCourseAttendanceStatsEvent>(_onLoadCourseAttendanceStats);
    on<LoadCourseSchedulesEvent>(_onLoadCourseSchedules);
    on<RecordScheduledAttendanceEvent>(_onRecordScheduledAttendance);
    on<CheckConnectionStatusEvent>(_onCheckConnectionStatus);
    on<SyncAttendanceDataEvent>(_onSyncAttendanceData);
    on<LoadCourseAttendanceStatsWithDateRangeEvent>(
        _onLoadCourseAttendanceStatsWithDateRange);
    on<LoadAttendanceWeeklyTrendsEvent>(_onLoadAttendanceWeeklyTrends);

    // NEW: Add new event handlers
    on<CheckScheduleAttendanceStatusEvent>(_onCheckScheduleAttendanceStatus);
    on<LoadMultipleScheduleAttendanceStatusEvent>(
        _onLoadMultipleScheduleAttendanceStatus);
    on<LoadPast7DaysAttendanceEvent>(_onLoadPast7DaysAttendance);
    on<LoadPast7DaysAttendanceWithSummaryEvent>(
        _onLoadPast7DaysAttendanceWithSummary);
    on<LoadScheduleAttendanceStatusEvent>(_onLoadScheduleAttendanceStatus);
    on<CheckScheduleAttendanceBeforeTakingEvent>(
        _onCheckScheduleAttendanceBeforeTaking);
    on<RecordScheduledAttendanceWithDateResolutionEvent>(
        _onRecordScheduledAttendanceWithDateResolution);
    on<LoadMultipleScheduleStatusEvent>(_onLoadMultipleScheduleStatus);
    on<LoadAttendanceForEditEvent>(_onLoadAttendanceForEdit);
    on<UpdateAttendanceRecordsEvent>(_onUpdateAttendanceRecords);
    on<ValidateEditPermissionEvent>(_onValidateEditPermission);
  }

  // NEW: Event handler implementations

  Future<void> _onCheckScheduleAttendanceStatus(
    CheckScheduleAttendanceStatusEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final status = await getScheduleAttendanceStatusUseCase.execute(
        event.courseId,
        event.date,
        event.scheduleId,
      );

      emit(ScheduleAttendanceStatusLoaded(
        scheduleId: event.scheduleId,
        isTaken: status['isTaken'] as bool,
        attendanceCount: status['count'] as int,
        totalStudents: status['totalStudents'] as int,
        completionRate: status['completionRate'] as double,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadMultipleScheduleAttendanceStatus(
    LoadMultipleScheduleAttendanceStatusEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final scheduleStatuses =
          await getScheduleAttendanceStatusUseCase.executeForMultipleSchedules(
        event.courseId,
        event.date,
        event.scheduleIds,
      );

      emit(MultipleScheduleAttendanceStatusLoaded(
        scheduleStatuses: scheduleStatuses,
        date: event.date,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadPast7DaysAttendance(
    LoadPast7DaysAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      // Check connectivity
      final isConnected = await ErrorHandler.isConnected();
      if (!isConnected) {
        // Try to get cached data
        final cachedAttendance =
            await _getCachedPast7DaysAttendance(event.courseId);

        if (cachedAttendance.isNotEmpty) {
          emit(Past7DaysAttendanceLoaded(attendanceMap: cachedAttendance));

          final lastSynced = await _getLastSyncTime();
          final hasUnsynced = await _hasUnsyncedData();

          emit(AttendanceOfflineMode(
            lastSynced: lastSynced,
            hasUnsynced: hasUnsynced,
          ));
          return;
        }
      }

      final attendanceMap = await ErrorHandler.retryWithBackoff(
        operation: () => getPast7DaysAttendanceUseCase.execute(event.courseId),
      );

      // Cache the result
      await _cachePast7DaysAttendance(event.courseId, attendanceMap);

      emit(Past7DaysAttendanceLoaded(attendanceMap: attendanceMap));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadPast7DaysAttendanceWithSummary(
    LoadPast7DaysAttendanceWithSummaryEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final result = await ErrorHandler.retryWithBackoff(
        operation: () =>
            getPast7DaysAttendanceUseCase.executeWithSummary(event.courseId),
      );

      emit(Past7DaysAttendanceWithSummaryLoaded(
        attendanceMap: result['attendanceMap'] as Map<String, List<Attendance>>,
        summary: result['summary'] as Map<String, dynamic>,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadScheduleAttendanceStatus(
    LoadScheduleAttendanceStatusEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // Extract schedule IDs from schedules
      final scheduleIds = event.schedules.map((s) => s.id).toList();

      final scheduleStatuses =
          await getScheduleAttendanceStatusUseCase.executeForMultipleSchedules(
        event.courseId,
        event.date,
        scheduleIds,
      );

      // Convert to simpler maps for UI consumption
      final Map<String, bool> statusMap = {};
      final Map<String, int> countMap = {};

      scheduleStatuses.forEach((scheduleId, status) {
        statusMap[scheduleId] = status['isTaken'] as bool;
        countMap[scheduleId] = status['count'] as int;
      });

      emit(ScheduleAttendanceStatusForTakeAttendanceLoaded(
        schedules: event.schedules,
        scheduleStatuses: statusMap,
        attendanceCounts: countMap,
        date: event.date,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  // Helper methods for caching (add these to your existing helper methods)

  Future<Map<String, List<Attendance>>> _getCachedPast7DaysAttendance(
    String courseId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'past_7_days_attendance_$courseId';
      final cached = prefs.getString(key);

      if (cached != null) {
        final Map<String, dynamic> rawData =
            jsonDecode(cached) as Map<String, dynamic>;
        final Map<String, List<Attendance>> result = {};

        rawData.forEach((dateKey, recordsList) {
          final List<dynamic> records = recordsList as List<dynamic>;
          result[dateKey] = records.map<Attendance>((item) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(item as Map);
            return Attendance(
              id: data['id'] as String,
              courseId: data['courseId'] as String,
              studentId: data['studentId'] as String,
              date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
              status: _parseAttendanceStatus(data['status'] as String),
              remarks: data['remarks'] as String?,
              createdAt:
                  DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
              updatedAt:
                  DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
            );
          }).toList();
        });

        return result;
      }
    } catch (e) {
      print('Error getting cached past 7 days attendance: $e');
    }
    return {};
  }

  Future<void> _cachePast7DaysAttendance(
    String courseId,
    Map<String, List<Attendance>> attendanceMap,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'past_7_days_attendance_$courseId';

      // Convert to JSON-serializable format
      final Map<String, dynamic> serializedData = {};

      attendanceMap.forEach((dateKey, records) {
        serializedData[dateKey] = records
            .map((record) => {
                  'id': record.id,
                  'courseId': record.courseId,
                  'studentId': record.studentId,
                  'date': record.date.millisecondsSinceEpoch,
                  'status': record.status.toString().split('.').last,
                  'remarks': record.remarks,
                  'createdAt': record.createdAt.millisecondsSinceEpoch,
                  'updatedAt': record.updatedAt.millisecondsSinceEpoch,
                })
            .toList();
      });

      await prefs.setString(key, jsonEncode(serializedData));
    } catch (e) {
      print('Error caching past 7 days attendance: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<void> _onLoadAttendanceByDate(
    LoadAttendanceByDateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      // First check connectivity
      final isConnected = await ErrorHandler.isConnected();
      if (!isConnected) {
        final lastSynced = await _getLastSyncTime();
        final hasUnsynced = await _hasUnsyncedData();

        emit(AttendanceOfflineMode(
          lastSynced: lastSynced,
          hasUnsynced: hasUnsynced,
        ));

        // Try to get cached data
        final cachedAttendance = await _getCachedAttendanceData(
          event.courseId,
          event.date,
        );

        if (cachedAttendance.isNotEmpty) {
          emit(AttendanceByDateLoaded(
            attendanceRecords: cachedAttendance,
            date: event.date,
          ));
        }

        return;
      }

      // Use the retry utility for network operations
      final attendanceRecords = await ErrorHandler.retryWithBackoff(
        operation: () => getAttendanceByDateUseCase.execute(
          event.courseId,
          event.date,
        ),
      );

      // Cache the result
      await _cacheAttendanceData(
        event.courseId,
        event.date,
        attendanceRecords,
      );

      emit(AttendanceByDateLoaded(
        attendanceRecords: attendanceRecords,
        date: event.date,
      ));
    } catch (e) {
      // Handle both Exception and other error types
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
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
      // Check connectivity
      final isConnected = await ErrorHandler.isConnected();
      if (!isConnected) {
        final cachedStudents = await _getCachedStudents(event.courseId);

        if (cachedStudents.isNotEmpty) {
          emit(EnrolledStudentsLoaded(students: cachedStudents));

          final lastSynced = await _getLastSyncTime();
          final hasUnsynced = await _hasUnsyncedData();

          emit(AttendanceOfflineMode(
            lastSynced: lastSynced,
            hasUnsynced: hasUnsynced,
          ));

          return;
        }
      }

      final students = await ErrorHandler.retryWithBackoff(
        operation: () => getEnrolledStudentsUseCase.execute(event.courseId),
      );

      // Cache students for offline use
      await _cacheStudents(event.courseId, students);

      emit(EnrolledStudentsLoaded(students: students));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
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
      // Check connectivity
      final isConnected = await ErrorHandler.isConnected();
      if (!isConnected) {
        final cachedAttendance = await _getCachedStudentAttendance(
          event.courseId,
          event.studentId,
        );

        if (cachedAttendance.isNotEmpty) {
          emit(StudentAttendanceLoaded(
            attendanceRecords: cachedAttendance,
            studentId: event.studentId,
          ));

          final lastSynced = await _getLastSyncTime();
          final hasUnsynced = await _hasUnsyncedData();

          emit(AttendanceOfflineMode(
            lastSynced: lastSynced,
            hasUnsynced: hasUnsynced,
          ));

          return;
        }
      }

      final attendanceRecords = await ErrorHandler.retryWithBackoff(
        operation: () => getStudentAttendanceUseCase.execute(
          event.courseId,
          event.studentId,
        ),
      );

      // Cache student attendance
      await _cacheStudentAttendance(
        event.courseId,
        event.studentId,
        attendanceRecords,
      );

      emit(StudentAttendanceLoaded(
        attendanceRecords: attendanceRecords,
        studentId: event.studentId,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
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
      // Check connectivity
      final isConnected = await ErrorHandler.isConnected();
      if (!isConnected) {
        final cachedStats = await _getCachedStats(event.courseId);

        if (cachedStats != null) {
          emit(CourseAttendanceStatsLoaded(stats: cachedStats));

          final lastSynced = await _getLastSyncTime();
          final hasUnsynced = await _hasUnsyncedData();

          emit(AttendanceOfflineMode(
            lastSynced: lastSynced,
            hasUnsynced: hasUnsynced,
          ));

          return;
        }
      }

      final stats = await ErrorHandler.retryWithBackoff(
        operation: () =>
            getCourseAttendanceStatsUseCase.execute(event.courseId),
      );

      // Cache stats
      await _cacheStats(event.courseId, stats);

      // Also load weekly trends
      add(LoadAttendanceWeeklyTrendsEvent(courseId: event.courseId));

      emit(CourseAttendanceStatsLoaded(stats: stats));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadCourseAttendanceStatsWithDateRange(
    LoadCourseAttendanceStatsWithDateRangeEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      // This would be a new method in your repository and use case
      // For now, we'll simulate it with the regular stats
      final stats = await ErrorHandler.retryWithBackoff(
        operation: () =>
            getCourseAttendanceStatsUseCase.execute(event.courseId),
      );

      // In a real implementation, you would filter by date range here

      emit(CourseAttendanceStatsLoaded(stats: stats));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onLoadAttendanceWeeklyTrends(
    LoadAttendanceWeeklyTrendsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // This would be a new method in your repository and use case
      // For now, we'll create some sample data
      final weeklyData = [
        {'week': 'Week 1', 'attendanceRate': 0.85},
        {'week': 'Week 2', 'attendanceRate': 0.90},
        {'week': 'Week 3', 'attendanceRate': 0.82},
        {'week': 'Week 4', 'attendanceRate': 0.88},
      ];

      emit(AttendanceWeeklyTrendsLoaded(weeklyData: weeklyData));
    } catch (e) {
      // No need to show error for this supplementary data
    }
  }

  Future<void> _onLoadCourseSchedules(
    LoadCourseSchedulesEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // Check connectivity
      final isConnected = await ErrorHandler.isConnected();
      if (!isConnected) {
        final cachedSchedules = await _getCachedSchedules(event.courseId);

        if (cachedSchedules.isNotEmpty) {
          emit(CourseSchedulesLoaded(schedules: cachedSchedules));
          return;
        }
      }

      final schedules = await ErrorHandler.retryWithBackoff(
        operation: () => getCourseSchedulesUseCase.execute(event.courseId),
      );

      // Cache schedules
      await _cacheSchedules(event.courseId, schedules);

      emit(CourseSchedulesLoaded(schedules: schedules));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onRecordScheduledAttendance(
    RecordScheduledAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      // Check connectivity
      final isConnected = await ErrorHandler.isConnected();

      if (isConnected) {
        // Get schedules to add schedule metadata
        final allSchedules =
            await getCourseSchedulesUseCase.execute(event.courseId);

        // IMPORTANT FIX: Filter schedules relevant for the attendance date
        final relevantSchedules = allSchedules.where((schedule) {
          return schedule.isRelevantForDate(event.date) && schedule.isActive;
        }).toList();

        // Use the filtered schedules list with the selectedScheduleIndex
        if (event.scheduleIndex >= 0 &&
            event.scheduleIndex < relevantSchedules.length) {
          final schedule =
              relevantSchedules[event.scheduleIndex]; // Use filtered list
          final scheduleMeta = {
            'scheduleIndex': event.scheduleIndex,
            'scheduleId': schedule.id,
            'scheduleDay': schedule.day,
            'scheduleLocation': schedule.location,
            'scheduleType': schedule.type.toString().split('.').last,
            'scheduleStartTime': schedule.startTime.toIso8601String(),
            'scheduleEndTime': schedule.endTime.toIso8601String(),
          };

          // Add schedule metadata to remarks for proper database recording
          Map<String, String> extendedRemarks =
              event.remarks?.map((k, v) => MapEntry(k, v)) ?? {};
          extendedRemarks['_scheduleMeta'] = jsonEncode(scheduleMeta);

          // Use the existing recordBulkAttendance but with schedule metadata
          await recordBulkAttendanceUseCase.execute(
            event.courseId,
            event.date,
            event.studentAttendances,
            remarks: extendedRemarks,
          );

          // Update last sync time
          await _updateLastSyncTime();

          emit(const AttendanceRecordSuccess(
            message: 'Attendance recorded successfully for this session',
          ));
        } else {
          emit(const AttendanceError(
            message: 'Invalid schedule selected',
          ));
        }
      } else {
        // Store attendance record locally for later sync
        await _storeOfflineAttendance(
          event.courseId,
          event.date,
          event.studentAttendances,
          event.remarks,
          scheduleIndex: event.scheduleIndex,
        );

        emit(const AttendanceRecordSuccess(
          message: 'Attendance stored offline. Will sync when online.',
        ));

        final lastSynced = await _getLastSyncTime();
        emit(AttendanceOfflineMode(
          lastSynced: lastSynced,
          hasUnsynced: true,
        ));
      }

      // Reload the attendance for this date
      add(LoadAttendanceByDateEvent(
        courseId: event.courseId,
        date: event.date,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  Future<void> _onCheckConnectionStatus(
    CheckConnectionStatusEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final hasConnection = await ErrorHandler.isConnected();
      final lastSynced = await _getLastSyncTime();
      final hasUnsynced = await _hasUnsyncedData();

      if (!hasConnection) {
        emit(AttendanceOfflineMode(
          lastSynced: lastSynced,
          hasUnsynced: hasUnsynced,
        ));
      }
    } catch (e) {
      // Don't emit error for connection check
    }
  }

  Future<void> _onSyncAttendanceData(
    SyncAttendanceDataEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final hasConnection = await ErrorHandler.isConnected();

      if (hasConnection) {
        await _syncPendingAttendanceRecords();
        final lastSynced = await _getLastSyncTime();
        final hasUnsynced = await _hasUnsyncedData();

        emit(AttendanceOfflineMode(
          lastSynced: lastSynced,
          hasUnsynced: hasUnsynced,
        ));

        // Show success message
        emit(const AttendanceRecordSuccess(
            message: 'All data synchronized successfully'));
      } else {
        emit(const AttendanceError(message: 'Cannot sync while offline'));
      }
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  // Helper methods for offline mode

  Future<DateTime> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_attendance_sync');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_attendance_sync', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _hasUnsyncedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('unsynced_attendance');
  }

  Future<void> _storeOfflineAttendance(
    String courseId,
    DateTime date,
    Map<String, AttendanceStatus> studentAttendances,
    Map<String, String>? remarks, {
    int? scheduleIndex,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing unsynced records or create new list
      List<Map<String, dynamic>> unsyncedRecords = [];
      final unsyncedString = prefs.getString('unsynced_attendance');
      if (unsyncedString != null) {
        unsyncedRecords = List<Map<String, dynamic>>.from(
          jsonDecode(unsyncedString) as List,
        );
      }

      // Convert AttendanceStatus to string for JSON serialization
      final Map<String, String> serializedAttendances = {};
      studentAttendances.forEach((key, value) {
        serializedAttendances[key] = value.toString().split('.').last;
      });

      // Create new record
      final record = {
        'courseId': courseId,
        'date': date.millisecondsSinceEpoch,
        'studentAttendances': serializedAttendances,
        'remarks': remarks,
        'scheduleIndex': scheduleIndex,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Add to list
      unsyncedRecords.add(record);

      // Save back to prefs
      await prefs.setString('unsynced_attendance', jsonEncode(unsyncedRecords));
    } catch (e) {
      print('Error storing offline attendance: $e');
      // Don't rethrow as this is not critical
    }
  }

  Future<void> _syncPendingAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final unsyncedString = prefs.getString('unsynced_attendance');

    if (unsyncedString != null) {
      try {
        final List<dynamic> unsyncedData = jsonDecode(unsyncedString) as List;

        for (var data in unsyncedData) {
          final record = data as Map<String, dynamic>;
          final courseId = record['courseId'] as String;
          final date =
              DateTime.fromMillisecondsSinceEpoch(record['date'] as int);

          // Convert string statuses back to AttendanceStatus enum
          final Map<String, dynamic> rawAttendances =
              Map<String, dynamic>.from(record['studentAttendances'] as Map);
          final Map<String, AttendanceStatus> studentAttendances = {};

          rawAttendances.forEach((key, value) {
            studentAttendances[key] = _parseAttendanceStatus(value as String);
          });

          final remarks = record['remarks'] != null
              ? Map<String, String>.from(record['remarks'] as Map)
              : null;

          final scheduleIndex = record['scheduleIndex'] as int?;

          if (scheduleIndex != null) {
            // Handle scheduled attendance
            add(RecordScheduledAttendanceEvent(
              courseId: courseId,
              date: date,
              scheduleIndex: scheduleIndex,
              studentAttendances: studentAttendances,
              remarks: remarks,
            ));
          } else {
            // This should not happen anymore since we always require schedule
            // But keep for backward compatibility
            await recordBulkAttendanceUseCase.execute(
              courseId,
              date,
              studentAttendances,
              remarks: remarks,
            );
          }
        }

        // Clear unsynced records
        await prefs.remove('unsynced_attendance');

        // Update sync time
        await _updateLastSyncTime();
      } catch (e) {
        print('Error syncing attendance: $e');
        throw Exception('Failed to sync attendance records');
      }
    }
  }

  // Caching helpers

  Future<void> _cacheAttendanceData(
    String courseId,
    DateTime date,
    List<Attendance> attendanceRecords,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'attendance_${courseId}_${date.year}${date.month}${date.day}';

      // Convert attendance records to JSON-serializable format
      final recordsData = attendanceRecords
          .map((record) => {
                'id': record.id,
                'courseId': record.courseId,
                'studentId': record.studentId,
                'date': record.date.millisecondsSinceEpoch,
                'status': record.status.toString().split('.').last,
                'remarks': record.remarks,
                'createdAt': record.createdAt.millisecondsSinceEpoch,
                'updatedAt': record.updatedAt.millisecondsSinceEpoch,
              })
          .toList();

      await prefs.setString(key, jsonEncode(recordsData));
    } catch (e) {
      print('Error caching attendance data: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<List<Attendance>> _getCachedAttendanceData(
    String courseId,
    DateTime date,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'attendance_${courseId}_${date.year}${date.month}${date.day}';
      final cached = prefs.getString(key);

      if (cached != null) {
        final List<dynamic> rawData = jsonDecode(cached) as List;
        // Convert the dynamic list to List<Attendance>
        return rawData.map<Attendance>((item) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(item as Map);
          return Attendance(
            id: data['id'] as String,
            courseId: data['courseId'] as String,
            studentId: data['studentId'] as String,
            date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
            status: _parseAttendanceStatus(data['status'] as String),
            remarks: data['remarks'] as String?,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
          );
        }).toList();
      }
    } catch (e) {
      print('Error getting cached attendance data: $e');
    }
    return [];
  }

// Helper to convert string status to enum
  AttendanceStatus _parseAttendanceStatus(String status) {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }

  Future<void> _cacheStudents(
    String courseId,
    List<Map<String, dynamic>> students,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'students_$courseId';
      await prefs.setString(key, jsonEncode(students));
    } catch (e) {
      print('Error caching students: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedStudents(
    String courseId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'students_$courseId';
      final cached = prefs.getString(key);

      if (cached != null) {
        return List<Map<String, dynamic>>.from(
          (jsonDecode(cached) as List)
              .map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
    } catch (e) {
      print('Error getting cached students: $e');
    }
    return [];
  }

  Future<void> _cacheStudentAttendance(
    String courseId,
    String studentId,
    List<Attendance> attendanceRecords,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'student_attendance_${courseId}_$studentId';

      // Convert attendance records to JSON-serializable format
      final recordsData = attendanceRecords
          .map((record) => {
                'id': record.id,
                'courseId': record.courseId,
                'studentId': record.studentId,
                'date': record.date.millisecondsSinceEpoch,
                'status': record.status.toString().split('.').last,
                'remarks': record.remarks,
                'createdAt': record.createdAt.millisecondsSinceEpoch,
                'updatedAt': record.updatedAt.millisecondsSinceEpoch,
              })
          .toList();

      await prefs.setString(key, jsonEncode(recordsData));
    } catch (e) {
      print('Error caching student attendance: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<List<Attendance>> _getCachedStudentAttendance(
    String courseId,
    String studentId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'student_attendance_${courseId}_$studentId';
      final cached = prefs.getString(key);

      if (cached != null) {
        final List<dynamic> rawData = jsonDecode(cached) as List;
        // Convert the dynamic list to List<Attendance>
        return rawData.map<Attendance>((item) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(item as Map);
          return Attendance(
            id: data['id'] as String,
            courseId: data['courseId'] as String,
            studentId: data['studentId'] as String,
            date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
            status: _parseAttendanceStatus(data['status'] as String),
            remarks: data['remarks'] as String?,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
          );
        }).toList();
      }
    } catch (e) {
      print('Error getting cached student attendance: $e');
    }
    return [];
  }

  Future<void> _cacheStats(
    String courseId,
    Map<String, dynamic> stats,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'stats_$courseId';
      await prefs.setString(key, jsonEncode(stats));
    } catch (e) {
      print('Error caching stats: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<Map<String, dynamic>?> _getCachedStats(
    String courseId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'stats_$courseId';
      final cached = prefs.getString(key);

      if (cached != null) {
        return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      }
    } catch (e) {
      print('Error getting cached stats: $e');
    }
    return null;
  }

  Future<void> _cacheSchedules(
    String courseId,
    List<Schedule> schedules,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'schedules_$courseId';

      // Convert schedules to JSON-serializable format with ALL fields
      final schedulesData = schedules
          .map((schedule) => {
                'id': schedule.id,
                'courseId': schedule.courseId,
                'day': schedule.day,
                'startTime': schedule.startTime.millisecondsSinceEpoch,
                'endTime': schedule.endTime.millisecondsSinceEpoch,
                'location': schedule.location,
                'subject': schedule.subject,
                'grade': schedule.grade,
                'type': schedule.type
                    .toString()
                    .split('.')
                    .last, // Convert enum to string
                'specificDate': schedule.specificDate?.millisecondsSinceEpoch,
                'replacesDate': schedule.replacesDate,
                'reason': schedule.reason,
                'isActive': schedule.isActive,
                'createdAt': schedule.createdAt?.millisecondsSinceEpoch,
              })
          .toList();

      await prefs.setString(key, jsonEncode(schedulesData));
    } catch (e) {
      print('Error caching schedules: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<List<Schedule>> _getCachedSchedules(
    String courseId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'schedules_$courseId';
      final cached = prefs.getString(key);

      if (cached != null) {
        final List<dynamic> schedulesData = jsonDecode(cached) as List;

        return schedulesData.map((data) {
          // Parse schedule type enum
          ScheduleType type = ScheduleType.regular;
          if (data['type'] != null) {
            switch (data['type'] as String) {
              case 'replacement':
                type = ScheduleType.replacement;
                break;
              case 'extension':
                type = ScheduleType.extension;
                break;
              case 'cancelled':
                type = ScheduleType.cancelled;
                break;
              default:
                type = ScheduleType.regular;
            }
          }

          // Parse optional DateTime fields
          DateTime? specificDate;
          if (data['specificDate'] != null) {
            specificDate = DateTime.fromMillisecondsSinceEpoch(
                data['specificDate'] as int);
          }

          DateTime? createdAt;
          if (data['createdAt'] != null) {
            createdAt =
                DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
          }

          // Create full Schedule object with all fields
          return Schedule(
            id: data['id'] as String? ?? 'cached-schedule',
            courseId: data['courseId'] as String? ?? courseId,
            day: data['day'] as String,
            startTime:
                DateTime.fromMillisecondsSinceEpoch(data['startTime'] as int),
            endTime:
                DateTime.fromMillisecondsSinceEpoch(data['endTime'] as int),
            location: data['location'] as String,
            subject: data['subject'] as String? ?? 'Unknown',
            grade: data['grade'] as int? ?? 1,
            type: type,
            specificDate: specificDate,
            replacesDate: data['replacesDate'] as String?,
            reason: data['reason'] as String?,
            isActive: data['isActive'] as bool? ?? true,
            createdAt: createdAt,
          );
        }).toList();
      }
    } catch (e) {
      print('Error getting cached schedules: $e');
    }
    return [];
  }

  /// Check if attendance exists for a specific schedule before taking
  Future<void> _onCheckScheduleAttendanceBeforeTaking(
    CheckScheduleAttendanceBeforeTakingEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final schedule = event.schedule;
      final attendanceDate =
          ScheduleDateUtils.getScheduleDateForCurrentWeek(schedule);

      // Use your existing use case instead of direct repository access
      final status = await getScheduleAttendanceStatusUseCase.execute(
        event.courseId,
        attendanceDate,
        schedule.id,
      );

      final hasAttendance = status['isTaken'] as bool;
      final count = status['count'] as int;

      if (hasAttendance) {
        emit(ScheduleAttendanceAlreadyExists(
          schedule: schedule,
          attendanceDate: attendanceDate,
          existingCount: count,
        ));
      } else {
        emit(ScheduleAttendanceCanBeTaken(
          schedule: schedule,
          attendanceDate: attendanceDate,
        ));
      }
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  /// Record attendance with automatic date resolution from schedule
  Future<void> _onRecordScheduledAttendanceWithDateResolution(
    RecordScheduledAttendanceWithDateResolutionEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final schedule = event.schedule;
      final attendanceDate =
          ScheduleDateUtils.getScheduleDateForCurrentWeek(schedule);

      // Double-check for duplicates before recording (unless overwrite is allowed)
      if (!event.allowOverwrite) {
        final status = await getScheduleAttendanceStatusUseCase.execute(
          event.courseId,
          attendanceDate,
          schedule.id,
        );

        final hasAttendance = status['isTaken'] as bool;

        if (hasAttendance) {
          emit(const AttendanceError(
              message: 'Attendance has already been taken for this schedule. '
                  'Use edit mode to modify existing records.'));
          return;
        }
      }

      // Create enhanced schedule metadata
      final scheduleMetadata = {
        'scheduleId': schedule.id,
        'scheduleDay': schedule.day,
        'scheduleType': schedule.type.toString().split('.').last,
        'scheduleLocation': schedule.location,
        'scheduleStartTime': schedule.startTime.toIso8601String(),
        'scheduleEndTime': schedule.endTime.toIso8601String(),
        'attendanceDate': attendanceDate.toIso8601String(),
        'scheduleIndex': 0, // For backward compatibility
      };

      // Add schedule metadata to remarks
      Map<String, String> extendedRemarks =
          event.remarks?.map((k, v) => MapEntry(k, v)) ?? {};
      extendedRemarks['_scheduleMeta'] = jsonEncode(scheduleMetadata);

      // Use your existing use case
      await recordBulkAttendanceUseCase.execute(
        event.courseId,
        attendanceDate,
        event.studentAttendances,
        remarks: extendedRemarks,
      );

      // Update last sync time
      await _updateLastSyncTime();

      emit(AttendanceRecordSuccess(
        message:
            'Attendance recorded for ${schedule.displayTitle} on ${ScheduleDateUtils.getScheduleDateDisplay(schedule)}',
      ));

      // Reload attendance data
      add(LoadAttendanceByDateEvent(
        courseId: event.courseId,
        date: attendanceDate,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  /// Load attendance status for multiple schedules on a specific date
  Future<void> _onLoadMultipleScheduleStatus(
    LoadMultipleScheduleStatusEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final scheduleIds = event.schedules.map((s) => s.id).toList();

      // Use your existing use case for multiple schedules
      final statusMap =
          await getScheduleAttendanceStatusUseCase.executeForMultipleSchedules(
        event.courseId,
        event.date,
        scheduleIds,
      );

      // Extract status and count information
      final Map<String, bool> scheduleStatuses = {};
      final Map<String, int> attendanceCounts = {};

      statusMap.forEach((scheduleId, status) {
        scheduleStatuses[scheduleId] = status['isTaken'] as bool;
        attendanceCounts[scheduleId] = status['count'] as int;
      });

      emit(MultipleScheduleStatusLoaded(
        scheduleStatuses: scheduleStatuses,
        attendanceCounts: attendanceCounts,
        date: event.date,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  /// Load attendance records for editing with validation
  Future<void> _onLoadAttendanceForEdit(
    LoadAttendanceForEditEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceEditPreparing(
        message: 'Preparing attendance for editing...'));

    try {
      // First validate if editing is allowed (7-day rule)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final recordDate = DateTime(
        event.attendanceDate.year,
        event.attendanceDate.month,
        event.attendanceDate.day,
      );
      final daysDifference = today.difference(recordDate).inDays;
      final canEdit = daysDifference >= 0 && daysDifference <= 7;

      if (!canEdit) {
        emit(EditPermissionValidated(
          attendanceDate: event.attendanceDate,
          canEdit: false,
          reason: 'Records older than 7 days cannot be edited',
          daysOld: daysDifference,
        ));
        return;
      }

      // Load enrolled students for this course
      final enrolledStudents = await ErrorHandler.retryWithBackoff(
        operation: () => getEnrolledStudentsUseCase.execute(event.courseId),
      );

      // Extract schedule information from the first attendance record
      Map<String, dynamic>? scheduleInfo;
      if (event.existingRecords.isNotEmpty) {
        scheduleInfo =
            _extractScheduleInfoFromRecord(event.existingRecords.first);
      }

      emit(AttendanceLoadedForEdit(
        courseId: event.courseId,
        attendanceDate: event.attendanceDate,
        attendanceRecords: event.existingRecords,
        enrolledStudents: enrolledStudents,
        scheduleInfo: scheduleInfo,
        canEdit: canEdit,
      ));
    } catch (e) {
      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      emit(AttendanceError(message: errorMessage));
    }
  }

  /// Update attendance records with change tracking
  Future<void> _onUpdateAttendanceRecords(
    UpdateAttendanceRecordsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    print('DEBUG: Starting attendance update...');

    try {
      // Detect changes for tracking
      final Map<String, String> changes = {};
      int changedStudentCount = 0;

      print('DEBUG: Checking for changes...');
      event.updatedAttendances.forEach((studentId, newStatus) {
        final originalStatus = event.originalAttendances[studentId];
        if (originalStatus != null && originalStatus != newStatus) {
          changes[studentId] =
              '${_getStatusText(originalStatus)} → ${_getStatusText(newStatus)}';
          changedStudentCount++;
          print('DEBUG: Change detected for $studentId: ${changes[studentId]}');
        }
      });

      // If no changes detected, show message and return
      if (changedStudentCount == 0) {
        print('DEBUG: No changes detected');
        emit(AttendanceRecordsUpdated(
          message: 'No changes detected. Attendance remains the same.',
          changedStudentCount: 0,
          changes: {},
        ));
        return;
      }

      print(
          'DEBUG: Found $changedStudentCount changes, proceeding with update...');

      // SIMPLIFIED: Use the existing use case directly instead of helper method
      await updateAttendanceUseCase.executeMultiple(
        event.courseId,
        event.attendanceDate,
        event.updatedAttendances,
        event.updatedRemarks,
      );

      print('DEBUG: Update completed successfully');

      // Update last sync time
      await _updateLastSyncTime();

      emit(AttendanceRecordsUpdated(
        message:
            'Attendance updated successfully! Changed $changedStudentCount student(s).',
        changedStudentCount: changedStudentCount,
        changes: changes,
      ));

      print('DEBUG: Success state emitted');

      // Reload the attendance data to reflect changes
      add(LoadAttendanceByDateEvent(
        courseId: event.courseId,
        date: event.attendanceDate,
      ));

      print('DEBUG: Reload event added');
    } catch (e) {
      print('DEBUG: Error occurred: $e');
      print('DEBUG: Error type: ${e.runtimeType}');

      String errorMessage;
      if (e is Exception) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }

      print('DEBUG: Emitting error: $errorMessage');
      emit(AttendanceError(message: errorMessage));
    }
  }

  /// Validate edit permission based on 7-day rule
  Future<void> _onValidateEditPermission(
    ValidateEditPermissionEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final recordDate = DateTime(
        event.attendanceDate.year,
        event.attendanceDate.month,
        event.attendanceDate.day,
      );
      final daysDifference = today.difference(recordDate).inDays;
      final canEdit = daysDifference >= 0 && daysDifference <= 7;

      String reason = '';
      if (!canEdit) {
        if (daysDifference < 0) {
          reason = 'Cannot edit future attendance records';
        } else {
          reason = 'Records older than 7 days cannot be edited';
        }
      } else {
        reason = 'Record can be edited';
      }

      emit(EditPermissionValidated(
        attendanceDate: event.attendanceDate,
        canEdit: canEdit,
        reason: reason,
        daysOld: daysDifference,
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Error validating edit permission: $e'));
    }
  }

  /// Helper method to extract schedule info from attendance record
  Map<String, dynamic>? _extractScheduleInfoFromRecord(Attendance record) {
    if (record is AttendanceModel && record.scheduleMetadata != null) {
      return record.scheduleMetadata;
    }
    return null;
  }

  /// Helper method to get status text
  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  // REPLACE the _updateExistingAttendanceRecords method in AttendanceBloc:

  /// Update existing attendance records (handles existing document IDs)
  Future<void> _updateExistingAttendanceRecords(
    String courseId,
    DateTime date,
    Map<String, AttendanceStatus> updatedAttendances,
    Map<String, String>? updatedRemarks,
  ) async {
    try {
      // Get existing attendance records to find which ones need updating
      final existingRecords =
          await getAttendanceByDateUseCase.execute(courseId, date);

      // For each existing record that needs updating, use the repository's update method
      for (var record in existingRecords) {
        final studentId = record.studentId;

        if (updatedAttendances.containsKey(studentId)) {
          final newStatus = updatedAttendances[studentId]!;
          final newRemarks = updatedRemarks?[studentId];

          // FIXED: Use the UpdateAttendanceUseCase instead of calling repository directly
          await updateAttendanceUseCase.execute(
            record.id,
            newStatus,
            remarks: newRemarks,
          );
        }
      }
    } catch (e) {
      print('Error in _updateExistingAttendanceRecords: $e');
      throw Exception('Failed to update attendance records: $e');
    }
  }

  /// Helper method to update a single attendance record
  Future<void> _updateSingleAttendanceRecord(
    String attendanceId,
    AttendanceStatus newStatus,
    String? newRemarks,
  ) async {
    // Use the existing repository method through the use case pattern
    // We need to access the repository through dependency injection
    // For now, we'll throw an error to indicate this needs to be implemented
    throw UnimplementedError(
        'Need to add UpdateAttendanceUseCase or access repository directly');
  }
}
