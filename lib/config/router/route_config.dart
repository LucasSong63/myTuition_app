// lib/config/router/route_config.dart - PART 1
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/admin/setup_screen.dart';
import 'package:mytuition/features/attendance/data/models/attendance_model.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/registration_bloc.dart';
import 'package:mytuition/features/auth/presentation/pages/email_verification_page.dart';
import 'package:mytuition/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:mytuition/features/auth/presentation/pages/login_page.dart';
import 'package:mytuition/features/auth/presentation/pages/register_page.dart';
import 'package:mytuition/features/auth/presentation/pages/registration_details_page.dart';
import 'package:mytuition/features/auth/presentation/pages/registration_list_page.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/subject_cost_bloc.dart';
import 'package:mytuition/features/courses/presentation/pages/student_course_detail_page.dart';
import 'package:mytuition/features/courses/presentation/pages/student_courses_page.dart';
import 'package:mytuition/features/courses/presentation/pages/tutor_course_detail_page.dart';
import 'package:mytuition/features/courses/presentation/pages/subject_cost_configuration_page.dart';
import 'package:mytuition/features/courses/presentation/pages/tutor_courses_page.dart';

import 'package:mytuition/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:mytuition/features/payments/presentation/pages/payment_info_page.dart';
import 'package:mytuition/features/payments/presentation/pages/payment_management_page.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/pages/student_profile_page.dart';
import 'package:mytuition/features/profile/presentation/pages/tutor_profile_page.dart';
import 'package:mytuition/features/student_dashboard/presentation/bloc/student_dashboard_bloc.dart';
import 'package:mytuition/features/student_dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_bloc.dart';
import 'package:mytuition/features/student_management/presentation/pages/student_detail_page.dart';
import 'package:mytuition/features/student_management/presentation/pages/students_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/tutor_task_management_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/task_progress_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/student_tasks_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/student_task_detail_page.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mytuition/features/attendance/presentation/pages/manage_attendance_page.dart';
import 'package:mytuition/features/attendance/presentation/pages/take_attendance_page.dart';
import 'package:mytuition/features/attendance/presentation/pages/student_attendance_history_page.dart';
import 'package:mytuition/features/attendance/presentation/bloc/student_attendance_history_bloc.dart';
import 'package:mytuition/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:mytuition/features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/pages/tutor_dashboard_page.dart';
import '../../core/services/fcm_service.dart';
import '../../features/attendance/domain/entities/attendance.dart';
import '../../features/attendance/presentation/pages/edit_attendance_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'route_names.dart';

/// App router configuration using GoRouter
class AppRouter {
  // Use a private constructor so this class can't be instantiated
  AppRouter._();

  // Get instance of GetIt
  static final getIt = GetIt.instance;

  // Router instance
  static final _router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: _guardRoutes,
    routes: _buildRoutes(),
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text('Page not found'),
      ),
    ),
  );

  // Getter for the router instance
  static GoRouter get router => _router;

  // Auth guard for routes
  static String? _guardRoutes(BuildContext context, GoRouterState state) {
    final authBloc = context.read<AuthBloc>();
    final currentState = authBloc.state;

    final bool isLoggedIn = currentState is Authenticated;
    final String location = state.uri.toString();
    final bool isOnAuthPage = location.startsWith('/login') ||
        location.startsWith('/register') ||
        location.startsWith('/forgot-password');

    // If user is not logged in and not on an auth page, redirect to login
    if (!isLoggedIn && !isOnAuthPage && !location.startsWith('/')) {
      return '/login';
    }

    // If user is logged in and on an auth page, redirect to appropriate dashboard
    if (isLoggedIn && isOnAuthPage) {
      final bool isTutor = (currentState as Authenticated).isTutor;
      return isTutor ? '/tutor' : '/student';
    }

    return null;
  }

  // Build the route configuration
  static List<RouteBase> _buildRoutes() {
    return [
      // Auth routes
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Splash Screen')),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Onboarding')),
        ),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: RouteNames.verifyEmail,
        builder: (context, state) {
          final email = state.extra as String;
          return EmailVerificationPage(email: email);
        },
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<AuthBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/admin/setup',
        name: RouteNames.adminSetup,
        builder: (context, state) => const SetupScreen(),
      ),

      // Notifications route
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            return NotificationListPage(userId: authState.user.studentId!);
          }
          return const Scaffold(
            body: Center(child: Text('Please log in to view notifications')),
          );
        },
      ),

      // lib/config/router/route_config.dart - PART 2
// Continue from Part 1...

      // Student routes - organized as a ShellRoute for nested navigation
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.book), label: 'Courses'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat), label: 'AI Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _calculateSelectedIndex(state),
              onTap: (index) => _onItemTapped(index, context),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/student',
            name: RouteNames.studentRoot,
            builder: (context, state) {
              final authState = context.read<AuthBloc>().state;
              final studentId = authState is Authenticated
                  ? authState.user.studentId ?? ''
                  : '';

              return BlocProvider<StudentDashboardBloc>(
                create: (context) => getIt<StudentDashboardBloc>(),
                child: StudentDashboardPage(studentId: studentId),
              );
            },
            routes: [
              // Student profile route
              GoRoute(
                path: 'profile',
                name: RouteNames.studentProfile,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider<ProfileBloc>(
                      create: (context) => getIt<ProfileBloc>(),
                    ),
                    BlocProvider<PaymentInfoBloc>(
                      create: (context) => getIt<PaymentInfoBloc>(),
                    ),
                  ],
                  child: const StudentProfilePage(),
                ),
              ),

              // Student courses route
              GoRoute(
                path: 'courses',
                name: RouteNames.studentCourses,
                builder: (context, state) => BlocProvider<CourseBloc>(
                  create: (context) => getIt<CourseBloc>(),
                  child: const StudentCoursesPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':courseId',
                    name: RouteNames.studentCourseDetails,
                    builder: (context, state) {
                      final courseId = state.pathParameters['courseId'] ?? '';
                      return BlocProvider<CourseBloc>(
                        create: (context) => getIt<CourseBloc>(),
                        child: StudentCourseDetailPage(courseId: courseId),
                      );
                    },
                  ),
                ],
              ),

              // Student AI Chat route
              GoRoute(
                path: 'ai-chat',
                name: RouteNames.studentAiChat,
                builder: (context, state) {
                  final authState = context.read<AuthBloc>().state;
                  String studentId = '';

                  if (authState is Authenticated) {
                    studentId = authState.user.studentId ??
                        authState.user.email.split('@').first ??
                        '';
                  }

                  if (studentId.isEmpty) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('AI Chat Error'),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error,
                                size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            const Text(
                              'Unable to load AI Chat',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Student ID is missing from authentication',
                              style: TextStyle(color: AppColors.textMedium),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context
                                        .read<AuthBloc>()
                                        .add(CheckAuthStatusEvent());
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh Auth'),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    GoRouter.of(context)
                                        .goNamed(RouteNames.studentRoot);
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Go Back'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return BlocProvider<ChatBloc>(
                    create: (context) => getIt<ChatBloc>(),
                    child: AIChatPage(studentId: studentId),
                  );
                },
              ),

              // Student Tasks route
              GoRoute(
                path: 'tasks',
                name: RouteNames.studentTasks,
                builder: (context, state) => BlocProvider<TaskBloc>(
                  create: (context) => getIt<TaskBloc>(),
                  child: const StudentTasksPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':taskId',
                    name: RouteNames.studentTaskDetails,
                    builder: (context, state) {
                      final taskId = state.pathParameters['taskId'] ?? '';
                      return BlocProvider<TaskBloc>(
                        create: (context) => getIt<TaskBloc>(),
                        child: StudentTaskDetailPage(taskId: taskId),
                      );
                    },
                  ),
                ],
              ),

              // Student Attendance History route
              GoRoute(
                path: 'attendance-history',
                name: RouteNames.studentAttendanceHistory,
                builder: (context, state) =>
                    BlocProvider<StudentAttendanceHistoryBloc>(
                  create: (context) => getIt<StudentAttendanceHistoryBloc>(),
                  child: const StudentAttendanceHistoryPage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Tutor routes - organized as a ShellRoute for nested navigation
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.class_), label: 'Classes'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: 'Students'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _calculateSelectedTutorIndex(state),
              onTap: (index) => _onTutorItemTapped(index, context),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/tutor',
            name: RouteNames.tutorRoot,
            builder: (context, state) => BlocProvider<DashboardBloc>(
              create: (context) => getIt<DashboardBloc>(),
              child: const TutorDashboardPage(),
            ),
            routes: [
              // Tutor profile route
              GoRoute(
                path: 'profile',
                name: RouteNames.tutorProfile,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider<ProfileBloc>(
                      create: (context) => getIt<ProfileBloc>(),
                    ),
                    BlocProvider<PaymentInfoBloc>(
                      create: (context) => getIt<PaymentInfoBloc>(),
                    ),
                  ],
                  child: const TutorProfilePage(),
                ),
              ),

              // Tutor students route
              GoRoute(
                path: 'students',
                name: RouteNames.tutorStudents,
                builder: (context, state) =>
                    BlocProvider<StudentManagementBloc>(
                  create: (context) => getIt<StudentManagementBloc>(),
                  child: const StudentsPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':studentId',
                    name: RouteNames.tutorStudentDetails,
                    builder: (context, state) {
                      final studentId = state.pathParameters['studentId'] ?? '';
                      return BlocProvider<StudentManagementBloc>(
                        create: (context) => getIt<StudentManagementBloc>(),
                        child: StudentDetailPage(studentId: studentId),
                      );
                    },
                  ),
                ],
              ),

              // Tutor payments route
              GoRoute(
                path: 'payments',
                name: RouteNames.tutorPayments,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final month = extra?['month'] as int? ?? DateTime.now().month;
                  final year = extra?['year'] as int? ?? DateTime.now().year;

                  return BlocProvider<PaymentBloc>(
                    create: (context) => getIt<PaymentBloc>()
                      ..add(LoadPaymentsByMonthEvent(
                        month: month,
                        year: year,
                      )),
                    child: const PaymentManagementPage(),
                  );
                },
              ),

              // Tutor payment info route
              GoRoute(
                path: 'payment-info',
                name: RouteNames.tutorPaymentInfo,
                builder: (context, state) => BlocProvider<PaymentInfoBloc>(
                  create: (context) => getIt<PaymentInfoBloc>(),
                  child: const PaymentInfoPage(),
                ),
              ),

              // Tutor subject costs route
              GoRoute(
                path: 'subject-costs',
                name: RouteNames.tutorSubjectCosts,
                builder: (context, state) => BlocProvider(
                  create: (context) => getIt<SubjectCostBloc>(),
                  child: const SubjectCostConfigurationPage(),
                ),
              ),

              // Tutor tasks route
              GoRoute(
                path: 'tasks',
                name: RouteNames.tutorTasks,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tasks Coming Soon')),
                ),
              ),

              // Course task management route
              GoRoute(
                path: 'courses/:courseId/tasks',
                name: RouteNames.tutorCourseTaskManagement,
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final courseName = state.extra as String? ?? 'Course';
                  return BlocProvider<TaskBloc>(
                    create: (context) => getIt<TaskBloc>(),
                    child: TutorTaskManagementPage(
                      courseId: courseId,
                      courseName: courseName,
                    ),
                  );
                },
              ),

              // Task progress route
              GoRoute(
                path: 'tasks/:taskId',
                name: RouteNames.tutorTaskProgress,
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'] ?? '';
                  return BlocProvider<TaskBloc>(
                    create: (context) => getIt<TaskBloc>(),
                    child: TaskProgressPage(taskId: taskId),
                  );
                },
              ),

              // Manage attendance route (renamed from attendance history)
              GoRoute(
                path: 'courses/:courseId/attendance',
                name: RouteNames.manageAttendance,
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final courseName = state.extra as String? ?? 'Course';

                  return BlocProvider(
                    create: (context) => getIt<AttendanceBloc>()
                      ..add(LoadEnrolledStudentsEvent(courseId: courseId))
                      ..add(LoadCourseAttendanceStatsEvent(courseId: courseId)),
                    child: ManageAttendancePage(
                      courseId: courseId,
                      courseName: courseName,
                    ),
                  );
                },
              ),

              // Take attendance route (updated to support update mode)
              GoRoute(
                path: 'courses/:courseId/attendance/take',
                name: RouteNames.takeAttendance,
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  final courseName =
                      extra?['courseName'] as String? ?? 'Course';
                  final isUpdateMode = extra?['isUpdateMode'] as bool? ?? false;
                  final targetDate = extra?['targetDate'] as DateTime?;

                  return BlocProvider(
                    create: (context) => getIt<AttendanceBloc>()
                      ..add(LoadEnrolledStudentsEvent(courseId: courseId))
                      ..add(LoadAttendanceByDateEvent(
                        courseId: courseId,
                        date: targetDate ?? DateTime.now(),
                      ))
                      ..add(LoadCourseSchedulesEvent(courseId: courseId)),
                    child: TakeAttendancePage(
                      courseId: courseId,
                      courseName: courseName,
                      isUpdateMode: isUpdateMode,
                      targetDate: targetDate,
                    ),
                  );
                },
              ),

              // Edit attendance route
              GoRoute(
                path: 'courses/:courseId/attendance/edit',
                name: RouteNames.editAttendance,
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;

                  if (extra == null) {
                    // Error case - missing required data
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Edit Attendance'),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            const Text('Missing attendance data'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.pop(),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  try {
                    // Extract parameters from extra data
                    final courseName =
                        extra['courseName'] as String? ?? 'Course';
                    final attendanceDateStr =
                        extra['attendanceDate'] as String?;
                    final sessionId = extra['sessionId'] as String?;
                    final existingRecordsData =
                        extra['existingRecords'] as List<dynamic>?;

                    // Parse attendance date
                    DateTime? attendanceDate;
                    if (attendanceDateStr != null) {
                      attendanceDate = DateTime.parse(attendanceDateStr);
                    }

                    // Reconstruct attendance records from serialized data
                    List<Attendance>? existingRecords;
                    if (existingRecordsData != null) {
                      existingRecords = existingRecordsData.map((recordData) {
                        final data = recordData as Map<String, dynamic>;

                        // Parse attendance status from string back to enum
                        AttendanceStatus status = AttendanceStatus.absent;
                        final statusStr = data['status'] as String?;
                        if (statusStr != null) {
                          // Convert string back to enum
                          switch (statusStr) {
                            case 'AttendanceStatus.present':
                              status = AttendanceStatus.present;
                              break;
                            case 'AttendanceStatus.absent':
                              status = AttendanceStatus.absent;
                              break;
                            case 'AttendanceStatus.late':
                              status = AttendanceStatus.late;
                              break;
                            case 'AttendanceStatus.excused':
                              status = AttendanceStatus.excused;
                              break;
                            default:
                              status = AttendanceStatus.absent;
                          }
                        }

                        // Parse date
                        final dateStr = data['date'] as String?;
                        DateTime recordDate = attendanceDate ?? DateTime.now();
                        if (dateStr != null) {
                          try {
                            recordDate = DateTime.parse(dateStr);
                          } catch (e) {
                            print('Error parsing record date: $e');
                          }
                        }

                        return AttendanceModel(
                          id: data['id'] as String? ?? '',
                          studentId: data['studentId'] as String? ?? '',
                          courseId: courseId,
                          date: recordDate,
                          status: status,
                          remarks: data['remarks'] as String?,
                          createdAt: recordDate,
                          // ✅ Use recordDate as createdAt fallback
                          updatedAt: recordDate,
                          // ✅ Use recordDate as updatedAt fallback
                          scheduleMetadata:
                              data['scheduleMetadata'] as Map<String, dynamic>?,
                        );
                      }).toList();
                    }

                    // Debug logging
                    print('Route Config - EditAttendance Reconstructed:');
                    print('  Course ID: $courseId');
                    print('  Course Name: $courseName');
                    print('  Attendance Date: $attendanceDate');
                    print('  Session ID: $sessionId');
                    print('  Records Count: ${existingRecords?.length ?? 0}');

                    if (attendanceDate == null || existingRecords == null) {
                      return Scaffold(
                        appBar: AppBar(
                          title: const Text('Edit Attendance'),
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error,
                                  size: 64, color: AppColors.error),
                              const SizedBox(height: 16),
                              const Text('Invalid attendance data'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.pop(),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return BlocProvider(
                      create: (context) => getIt<AttendanceBloc>(),
                      child: EditAttendancePage(
                        courseId: courseId,
                        courseName: courseName,
                        attendanceDate: attendanceDate,
                        existingRecords: existingRecords,
                        sessionId: sessionId,
                      ),
                    );
                  } catch (e) {
                    print('Error in editAttendance route: $e');
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Edit Attendance'),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text('Error loading attendance data: $e'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.pop(),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),

              // Registration management routes
              GoRoute(
                path: 'registrations',
                name: RouteNames.tutorRegistrations,
                builder: (context, state) => BlocProvider<RegistrationBloc>(
                  create: (context) => getIt<RegistrationBloc>(),
                  child: const RegistrationListPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':registrationId',
                    name: RouteNames.registrationDetails,
                    builder: (context, state) {
                      final registrationId =
                          state.pathParameters['registrationId'] ?? '';
                      return BlocProvider<RegistrationBloc>(
                        create: (context) => getIt<RegistrationBloc>(),
                        child: RegistrationDetailsPage(
                            registrationId: registrationId),
                      );
                    },
                  ),
                ],
              ),

              // Tutor classes route
              GoRoute(
                path: 'classes',
                name: RouteNames.tutorClasses,
                builder: (context, state) => BlocProvider<CourseBloc>(
                  create: (context) => getIt<CourseBloc>(),
                  child: const TutorCoursesPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':courseId',
                    name: RouteNames.tutorCourseDetails,
                    builder: (context, state) {
                      final courseId = state.pathParameters['courseId'] ?? '';
                      return BlocProvider<CourseBloc>(
                        create: (context) => getIt<CourseBloc>(),
                        child: TutorCourseDetailPage(courseId: courseId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Legacy route for backward compatibility during transition
      GoRoute(
        path: '/courses/:courseId',
        name: RouteNames.legacyCourseDetail,
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final authState = context.read<AuthBloc>().state;
          final isTutor = authState is Authenticated && authState.isTutor;

          return BlocProvider<CourseBloc>(
            create: (context) => getIt<CourseBloc>(),
            child: isTutor
                ? TutorCourseDetailPage(courseId: courseId)
                : StudentCourseDetailPage(courseId: courseId),
          );
        },
      ),
    ];
  }

  // Helper method to calculate the selected index for bottom navigation
  static int _calculateSelectedIndex(GoRouterState state) {
    final location = state.uri.toString();
    if (location.startsWith('/student/profile')) return 4;
    if (location.startsWith('/student/courses')) return 1;
    if (location.startsWith('/student/ai-chat')) return 2;
    if (location.startsWith('/student/tasks')) return 3;
    return 0; // Default to home/dashboard
  }

  // Helper method to handle bottom navigation item taps
  static void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).goNamed(RouteNames.studentRoot);
        break;
      case 1:
        GoRouter.of(context).goNamed(RouteNames.studentCourses);
        break;
      case 2:
        GoRouter.of(context).goNamed(RouteNames.studentAiChat);
        break;
      case 3:
        GoRouter.of(context).goNamed(RouteNames.studentTasks);
        break;
      case 4:
        GoRouter.of(context).goNamed(RouteNames.studentProfile);
        break;
    }
  }

  // Helper method to calculate the selected index for tutor bottom navigation
  static int _calculateSelectedTutorIndex(GoRouterState state) {
    final location = state.uri.toString();
    if (location.startsWith('/tutor/profile')) return 3;
    if (location.startsWith('/tutor/classes')) return 1;
    if (location.startsWith('/tutor/students')) return 2;
    return 0; // Default to home/dashboard
  }

  // Helper method to handle tutor bottom navigation item taps
  static void _onTutorItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).goNamed(RouteNames.tutorRoot);
        break;
      case 1:
        GoRouter.of(context).goNamed(RouteNames.tutorClasses);
        break;
      case 2:
        GoRouter.of(context).goNamed(RouteNames.tutorStudents);
        break;
      case 3:
        GoRouter.of(context).goNamed(RouteNames.tutorProfile);
        break;
    }
  }
}
