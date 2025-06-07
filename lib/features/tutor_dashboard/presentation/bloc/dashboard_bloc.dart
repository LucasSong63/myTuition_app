// lib/features/dashboard/presentation/bloc/dashboard_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../../courses/domain/entities/schedule.dart';
import '../../../student_management/domain/usecases/get_all_students_usecase.dart';
import '../../../courses/domain/usecases/get_tutor_courses_usecase.dart';
import '../../../auth/domain/repositories/registration_repository.dart';
import '../../../payments/domain/repositories/payment_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetAllStudentsUseCase getAllStudentsUseCase;
  final GetTutorCoursesUseCase getTutorCoursesUseCase;
  final RegistrationRepository registrationRepository;
  final PaymentRepository paymentRepository;
  final FirebaseFirestore _firestore;

  DashboardBloc({
    required this.getAllStudentsUseCase,
    required this.getTutorCoursesUseCase,
    required this.registrationRepository,
    required this.paymentRepository,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        super(DashboardInitial()) {
    on<LoadDashboardOverviewEvent>(_onLoadDashboardOverview);
    on<LoadUpcomingClassesEvent>(_onLoadUpcomingClasses);
    on<LoadRecentActivityEvent>(_onLoadRecentActivity);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboardOverview(
    LoadDashboardOverviewEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // Load all basic stats in parallel
      final results = await Future.wait([
        _getTotalStudents(),
        _getActiveCourses(),
        _getPendingRegistrationsCount(),
        _getPaymentOverview(),
      ]);

      final totalStudents = results[0] as int;
      final activeCourses = results[1] as int;
      final pendingRegistrations = results[2] as int;
      final paymentOverview = results[3] as PaymentOverview;

      // Load upcoming classes and recent activity
      final upcomingClasses = await _getUpcomingClasses();
      final recentActivity = await _getRecentActivity(limit: 10);

      final stats = DashboardStats(
        totalStudents: totalStudents,
        activeCourses: activeCourses,
        pendingRegistrations: pendingRegistrations,
        paymentOverview: paymentOverview,
        upcomingClassesToday: upcomingClasses.where((c) => c.isToday).toList(),
        upcomingClassesThisWeek: upcomingClasses,
        recentActivities: recentActivity,
      );

      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError(message: 'Failed to load dashboard: $e'));
    }
  }

  Future<void> _onLoadUpcomingClasses(
    LoadUpcomingClassesEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentStats = (state as DashboardLoaded).stats;

      try {
        final upcomingClasses = await _getUpcomingClasses();

        final updatedStats = DashboardStats(
          totalStudents: currentStats.totalStudents,
          activeCourses: currentStats.activeCourses,
          pendingRegistrations: currentStats.pendingRegistrations,
          paymentOverview: currentStats.paymentOverview,
          upcomingClassesToday:
              upcomingClasses.where((c) => c.isToday).toList(),
          upcomingClassesThisWeek: upcomingClasses,
          recentActivities: currentStats.recentActivities,
        );

        emit(DashboardLoaded(stats: updatedStats));
      } catch (e) {
        emit(DashboardPartiallyLoaded(
          stats: currentStats,
          warning: 'Failed to update upcoming classes: $e',
        ));
      }
    }
  }

  Future<void> _onLoadRecentActivity(
    LoadRecentActivityEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentStats = (state as DashboardLoaded).stats;

      try {
        final recentActivity = await _getRecentActivity(limit: event.limit);

        final updatedStats = DashboardStats(
          totalStudents: currentStats.totalStudents,
          activeCourses: currentStats.activeCourses,
          pendingRegistrations: currentStats.pendingRegistrations,
          paymentOverview: currentStats.paymentOverview,
          upcomingClassesToday: currentStats.upcomingClassesToday,
          upcomingClassesThisWeek: currentStats.upcomingClassesThisWeek,
          recentActivities: recentActivity,
        );

        emit(DashboardLoaded(stats: updatedStats));
      } catch (e) {
        emit(DashboardPartiallyLoaded(
          stats: currentStats,
          warning: 'Failed to update recent activity: $e',
        ));
      }
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    add(const LoadDashboardOverviewEvent());
  }

  // Helper methods for data fetching

  Future<int> _getTotalStudents() async {
    try {
      final students = await getAllStudentsUseCase.execute();
      return students.length;
    } catch (e) {
      print('Error getting total students: $e');
      return 0;
    }
  }

  Future<int> _getActiveCourses() async {
    try {
      final courses = await getTutorCoursesUseCase
          .execute('tutor-leong'); // Should come from auth
      return courses.where((course) => course.isActive).length;
    } catch (e) {
      print('Error getting active courses: $e');
      return 0;
    }
  }

  Future<int> _getPendingRegistrationsCount() async {
    try {
      final pendingStream = registrationRepository.getPendingRegistrations();
      final pending = await pendingStream.first;
      return pending.length;
    } catch (e) {
      print('Error getting pending registrations: $e');
      return 0;
    }
  }

  Future<PaymentOverview> _getPaymentOverview() async {
    try {
      final now = DateTime.now();
      final payments =
          await paymentRepository.getPaymentsByMonthYear(now.month, now.year);

      int paidCount = 0;
      int unpaidCount = 0;
      int partialCount = 0;
      double totalAmount = 0;
      double paidAmount = 0;
      double outstandingAmount = 0;

      for (final payment in payments) {
        totalAmount += payment.amount;

        switch (payment.status) {
          case 'paid':
            paidCount++;
            paidAmount += payment.amount;
            break;
          case 'unpaid':
            unpaidCount++;
            outstandingAmount += payment.amount;
            break;
          case 'partial':
            partialCount++;
            final paid = payment.amountPaid ?? 0;
            paidAmount += paid;
            outstandingAmount += payment.getOutstandingAmount();
            break;
        }
      }

      return PaymentOverview(
        totalPayments: payments.length,
        paidPayments: paidCount,
        unpaidPayments: unpaidCount,
        partialPayments: partialCount,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        outstandingAmount: outstandingAmount,
      );
    } catch (e) {
      print('Error getting payment overview: $e');
      return const PaymentOverview(
        totalPayments: 0,
        paidPayments: 0,
        unpaidPayments: 0,
        partialPayments: 0,
        totalAmount: 0,
        paidAmount: 0,
        outstandingAmount: 0,
      );
    }
  }

  Future<List<UpcomingClass>> _getUpcomingClasses() async {
    try {
      print("=== GETTING UPCOMING CLASSES (DIRECT FIREBASE) ===");

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek = today.add(const Duration(days: 7));

      // Step 1: Get all active courses directly from classes collection
      final coursesSnapshot = await _firestore
          .collection('classes')
          .where('isActive', isEqualTo: true)
          .get();

      print("Found ${coursesSnapshot.docs.length} active courses");

      final List<UpcomingClass> upcomingClasses = [];

      // Step 2: Process each course document
      for (var courseDoc in coursesSnapshot.docs) {
        final courseData = courseDoc.data();
        final courseId = courseDoc.id;
        final subject = courseData['subject'] as String;
        final grade = courseData['grade'] as int;
        final students = courseData['students'] as List<dynamic>? ?? [];
        final schedules = courseData['schedules'] as List<dynamic>? ?? [];

        print("Processing course: $subject Grade $grade");
        print("  Students: ${students.length}");
        print("  Schedules: ${schedules.length}");

        // Step 3: Process schedules array
        for (var i = 0; i < schedules.length; i++) {
          final scheduleData = schedules[i] as Map<String, dynamic>;

          // Skip inactive schedules
          if (scheduleData['isActive'] != true) {
            continue;
          }

          final startTime = (scheduleData['startTime'] as Timestamp).toDate();
          final endTime = (scheduleData['endTime'] as Timestamp).toDate();
          final day = scheduleData['day'] as String;
          final location = scheduleData['location'] as String;
          final scheduleId = scheduleData['id'] as String;
          final type = scheduleData['type'] as String? ?? 'regular';

          print(
              "    Schedule: $day ${startTime.hour}:${startTime.minute} ($type)");

          if (type == 'regular') {
            // Handle regular weekly schedules
            final scheduleDayIndex = _getDayIndex(day);

            // Find next occurrence within 7 days
            for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
              final checkDate = today.add(Duration(days: dayOffset));

              if (checkDate.weekday == scheduleDayIndex) {
                final scheduleDateTime = DateTime(
                  checkDate.year,
                  checkDate.month,
                  checkDate.day,
                  startTime.hour,
                  startTime.minute,
                );

                // Only include future classes
                if (scheduleDateTime.isAfter(now)) {
                  upcomingClasses.add(UpcomingClass(
                    id: scheduleId,
                    courseId: courseId,
                    courseName: '$subject Grade $grade',
                    subject: subject,
                    grade: grade,
                    startTime: scheduleDateTime,
                    endTime: DateTime(
                      checkDate.year,
                      checkDate.month,
                      checkDate.day,
                      endTime.hour,
                      endTime.minute,
                    ),
                    location: location,
                    day: day,
                    enrolledStudents: students.length,
                    isToday: _isSameDay(checkDate, today),
                  ));

                  print("      ✅ Added: $scheduleDateTime");
                }
              }
            }
          } else if (type == 'replacement') {
            // Handle replacement schedules
            final specificDate = scheduleData['specificDate'] != null
                ? (scheduleData['specificDate'] as Timestamp).toDate()
                : null;

            if (specificDate != null) {
              final scheduleDate = DateTime(
                  specificDate.year, specificDate.month, specificDate.day);

              if (scheduleDate
                      .isAfter(today.subtract(const Duration(days: 1))) &&
                  scheduleDate.isBefore(nextWeek)) {
                final scheduleDateTime = DateTime(
                  scheduleDate.year,
                  scheduleDate.month,
                  scheduleDate.day,
                  startTime.hour,
                  startTime.minute,
                );

                if (scheduleDateTime.isAfter(now)) {
                  upcomingClasses.add(UpcomingClass(
                    id: scheduleId,
                    courseId: courseId,
                    courseName: '$subject Grade $grade',
                    subject: subject,
                    grade: grade,
                    startTime: scheduleDateTime,
                    endTime: DateTime(
                      scheduleDate.year,
                      scheduleDate.month,
                      scheduleDate.day,
                      endTime.hour,
                      endTime.minute,
                    ),
                    location: location,
                    day: _getDayName(scheduleDate.weekday),
                    enrolledStudents: students.length,
                    isToday: _isSameDay(scheduleDate, today),
                    isReplacement: true,
                    reason: scheduleData['reason'] as String?,
                  ));

                  print("      ✅ Added replacement: $scheduleDateTime");
                }
              }
            }
          }
        }
      }

      // Sort by start time
      upcomingClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

      print("Total upcoming classes: ${upcomingClasses.length}");
      return upcomingClasses;
    } catch (e) {
      print('Error getting upcoming classes: $e');
      return [];
    }
  }

// Helper methods
  int _getDayIndex(String day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final index = days.indexOf(day);
    return index == -1 ? 1 : index + 1; // Monday = 1, Sunday = 7
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekday >= 1 && weekday <= 7 ? days[weekday - 1] : 'Unknown';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<List<RecentActivity>> _getRecentActivity({int limit = 10}) async {
    try {
      final List<RecentActivity> activities = [];

      // Get recent payment history
      final paymentHistory = await paymentRepository.getAllPaymentHistory();
      for (final payment in paymentHistory.take(5)) {
        activities.add(RecentActivity(
          id: payment.id,
          type: RecentActivityType.payment,
          title: 'Payment Received',
          description:
              '${payment.studentName} paid RM${payment.amount.toStringAsFixed(2)}',
          timestamp: payment.date,
          data: {
            'studentName': payment.studentName,
            'amount': payment.amount,
            'month': payment.month,
            'year': payment.year,
          },
        ));
      }

      // Get recent task submissions
      final taskSubmissions = await _firestore
          .collection('student_tasks')
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      for (final doc in taskSubmissions.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String;
        final taskId = data['taskId'] as String;

        // Get student name and task title
        final studentName = await _getStudentName(studentId);
        final taskTitle = await _getTaskTitle(taskId);

        activities.add(RecentActivity(
          id: doc.id,
          type: RecentActivityType.taskSubmission,
          title: 'Task Completed',
          description: '$studentName completed "$taskTitle"',
          timestamp: (data['completedAt'] as Timestamp).toDate(),
          data: {
            'studentId': studentId,
            'taskId': taskId,
            'studentName': studentName,
            'taskTitle': taskTitle,
          },
        ));
      }

      // Get recent attendance
      final recentAttendance = await _firestore
          .collection('attendance')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in recentAttendance.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String;
        final courseId = data['courseId'] as String;

        final studentName = await _getStudentName(studentId);
        final courseName = await _getCourseName(courseId);

        activities.add(RecentActivity(
          id: doc.id,
          type: RecentActivityType.attendance,
          title: 'Attendance Recorded',
          description: '$studentName attended $courseName',
          timestamp: (data['createdAt'] as Timestamp).toDate(),
          data: {
            'studentId': studentId,
            'courseId': courseId,
            'studentName': studentName,
            'courseName': courseName,
          },
        ));
      }

      // Sort all activities by timestamp and limit
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(limit).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      return [];
    }
  }

  Future<String> _getStudentName(String studentId) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.data()['name'] ?? 'Unknown Student';
      }
      return 'Unknown Student';
    } catch (e) {
      return 'Unknown Student';
    }
  }

  Future<String> _getTaskTitle(String taskId) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (taskDoc.exists) {
        return taskDoc.data()?['title'] ?? 'Unknown Task';
      }
      return 'Unknown Task';
    } catch (e) {
      return 'Unknown Task';
    }
  }

  Future<String> _getCourseName(String courseId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();
      if (courseDoc.exists) {
        final data = courseDoc.data()!;
        return '${data['subject']} Grade ${data['grade']}';
      }
      return 'Unknown Course';
    } catch (e) {
      return 'Unknown Course';
    }
  }
}
