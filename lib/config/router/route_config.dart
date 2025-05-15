// Modified route_config.dart file with changes for CourseDetailPage split

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/features/admin/setup_screen.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/registration_bloc.dart';
import 'package:mytuition/features/auth/presentation/pages/demo_home_screen.dart';
import 'package:mytuition/features/auth/presentation/pages/email_verification_page.dart';
import 'package:mytuition/features/auth/presentation/pages/login_page.dart';
import 'package:mytuition/features/auth/presentation/pages/register_page.dart';
import 'package:mytuition/features/auth/presentation/pages/registration_details_page.dart';
import 'package:mytuition/features/auth/presentation/pages/registration_list_page.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/subject_cost_bloc.dart';

// import 'package:mytuition/features/courses/presentation/pages/course_detail_page.dart'; // Removed
import 'package:mytuition/features/courses/presentation/pages/student_course_detail_page.dart'; // Added
import 'package:mytuition/features/courses/presentation/pages/tutor_course_detail_page.dart'; // Added
import 'package:mytuition/features/courses/presentation/pages/courses_page.dart';
import 'package:mytuition/features/courses/presentation/pages/subject_cost_configuration_page.dart';
import 'package:mytuition/features/courses/presentation/pages/tutor_courses_page.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:mytuition/features/payments/presentation/pages/payment_info_page.dart';
import 'package:mytuition/features/payments/presentation/pages/payment_management_page.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/pages/profile_page.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_bloc.dart';
import 'package:mytuition/features/student_management/presentation/pages/student_detail_page.dart';
import 'package:mytuition/features/student_management/presentation/pages/students_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/tutor_task_management_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/task_progress_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/student_tasks_page.dart';
import 'package:mytuition/features/tasks/presentation/pages/student_task_detail_page.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mytuition/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:mytuition/features/attendance/presentation/pages/take_attendance_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
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
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Forgot Password Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/setup',
        builder: (context, state) => const SetupScreen(),
      ),

      // Student routes - organized as a ShellRoute for nested navigation
      ShellRoute(
        builder: (context, state, child) {
          // This would be your student scaffold with bottom navigation
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
            builder: (context, state) => const DemoHomeScreen(isTutor: false),
            routes: [
              // Add profile route
              GoRoute(
                path: 'profile',
                name: RouteNames.studentProfile,
                builder: (context, state) => BlocProvider<ProfileBloc>(
                  create: (context) => getIt<ProfileBloc>(),
                  child: const ProfilePage(),
                ),
              ),

              // Add courses route
              GoRoute(
                path: 'courses',
                name: RouteNames.studentCourses,
                builder: (context, state) => BlocProvider<CourseBloc>(
                  create: (context) => getIt<CourseBloc>(),
                  child: const CoursesPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':courseId',
                    name: RouteNames.studentCourseDetails,
                    builder: (context, state) {
                      final courseId = state.pathParameters['courseId'] ?? '';
                      return BlocProvider<CourseBloc>(
                        create: (context) => getIt<CourseBloc>(),
                        // Replace with StudentCourseDetailPage
                        child: StudentCourseDetailPage(courseId: courseId),
                      );
                    },
                  ),
                ],
              ),

              // Add AI Chat route
              GoRoute(
                path: 'ai-chat',
                name: RouteNames.studentAiChat,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('AI Chat Coming Soon')),
                ),
              ),

              // Add Tasks route
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
            ],
          ),
        ],
      ),

      // Tutor routes - organized as a ShellRoute for nested navigation
      ShellRoute(
        builder: (context, state, child) {
          // This would be your tutor scaffold with bottom navigation
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
            builder: (context, state) => const DemoHomeScreen(isTutor: true),
            routes: [
              // Add profile route
              GoRoute(
                path: 'profile',
                name: RouteNames.tutorProfile,
                builder: (context, state) => BlocProvider<ProfileBloc>(
                  create: (context) => getIt<ProfileBloc>(),
                  child: const ProfilePage(),
                ),
              ),

              // Add students route
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
                    name: 'tutorStudentDetails',
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
              GoRoute(
                path: 'payment-info',
                name: RouteNames.tutorPaymentInfo,
                builder: (context, state) => BlocProvider<PaymentInfoBloc>(
                  create: (context) => getIt<PaymentInfoBloc>(),
                  child: const PaymentInfoPage(),
                ),
              ),

              GoRoute(
                name: RouteNames.tutorSubjectCosts,
                path: '/tutor/subject-costs',
                builder: (context, state) => BlocProvider(
                  create: (context) => getIt<SubjectCostBloc>(),
                  child: const SubjectCostConfigurationPage(),
                ),
              ),

              // Add tasks route
              GoRoute(
                path: 'tasks',
                name: RouteNames.tutorTasks,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tasks Coming Soon')),
                ),
              ),

              // Route for course task management
              GoRoute(
                path: 'courses/:courseId/tasks',
                name: 'tutorCourseTaskManagement',
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

              // Route for task progress view
              GoRoute(
                path: 'tasks/:taskId',
                name: 'tutorTaskProgress',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'] ?? '';
                  return BlocProvider<TaskBloc>(
                    create: (context) => getIt<TaskBloc>(),
                    child: TaskProgressPage(taskId: taskId),
                  );
                },
              ),

              // Route for course attendance management
              GoRoute(
                path: 'courses/:courseId/attendance',
                name: 'courseAttendance',
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final courseName = state.extra as String? ?? 'Course';

                  return BlocProvider(
                    create: (context) => getIt<AttendanceBloc>()
                      ..add(LoadEnrolledStudentsEvent(courseId: courseId))
                      ..add(LoadCourseAttendanceStatsEvent(courseId: courseId)),
                    child: AttendanceHistoryPage(
                      courseId: courseId,
                      courseName: courseName,
                    ),
                  );
                },
              ),

              // Route for taking attendance
              GoRoute(
                path: 'courses/:courseId/attendance/take',
                name: 'takeAttendance',
                builder: (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final courseName = state.extra as String? ?? 'Course';

                  return BlocProvider(
                    create: (context) => getIt<AttendanceBloc>()
                      ..add(LoadEnrolledStudentsEvent(courseId: courseId))
                      ..add(LoadAttendanceByDateEvent(
                        courseId: courseId,
                        date: DateTime.now(),
                      )),
                    child: TakeAttendancePage(
                      courseId: courseId,
                      courseName: courseName,
                    ),
                  );
                },
              ),

              // Route for managing registration requests
              GoRoute(
                path: 'registrations',
                name: 'tutorRegistrations',
                builder: (context, state) => BlocProvider<RegistrationBloc>(
                  create: (context) => getIt<RegistrationBloc>(),
                  child: const RegistrationListPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':registrationId',
                    name: 'registrationDetails',
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
                        // Replace with TutorCourseDetailPage
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
        name: 'legacyCourseDetail',
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
      case 3: // Updated index
        GoRouter.of(context).goNamed(RouteNames.tutorProfile);
        break;
    }
  }
}
