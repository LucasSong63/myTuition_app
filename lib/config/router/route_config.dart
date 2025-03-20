import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

// Import your screens here as you create them
// import 'package:mytuition/presentation/pages/auth/login_page.dart';
// import 'package:mytuition/presentation/pages/auth/register_page.dart';
// etc.

/// App router configuration using GoRouter
class AppRouter {
  // Use a private constructor so this class can't be instantiated
  AppRouter._();

  // Router instance
  static final _router = GoRouter(
    initialLocation: '/',
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
    // TODO: Implement auth checking logic
    // Example:
    // final bool isLoggedIn = AuthService.isLoggedIn;
    // final bool isOnAuthPage = state.location.startsWith('/login') ||
    //                           state.location.startsWith('/register') ||
    //                           state.location.startsWith('/forgot-password');

    // if (!isLoggedIn && !isOnAuthPage && state.location != '/') {
    //   return '/login';
    // } else if (isLoggedIn && isOnAuthPage) {
    //   // Go to appropriate dashboard based on user role
    //   final bool isTutor = AuthService.currentUser?.isTutor ?? false;
    //   return isTutor ? '/tutor' : '/student';
    // }

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
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen')),
        ),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Register Screen')),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Forgot Password Screen')),
        ),
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
                BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Student Dashboard')),
            ),
            routes: [
              GoRoute(
                path: 'profile',
                name: RouteNames.studentProfile,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Student Profile')),
                ),
              ),
              GoRoute(
                path: 'courses',
                name: RouteNames.studentCourses,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Student Courses')),
                ),
                routes: [
                  GoRoute(
                    path: ':courseId',
                    name: RouteNames.studentCourseDetails,
                    builder: (context, state) {
                      final courseId = state.pathParameters['courseId'] ?? '';
                      return Scaffold(
                        body: Center(child: Text('Course Details: $courseId')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'ai-chat',
                name: RouteNames.studentAiChat,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Student AI Chat')),
                ),
              ),
              GoRoute(
                path: 'tasks',
                name: RouteNames.studentTasks,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Student Tasks')),
                ),
                routes: [
                  GoRoute(
                    path: ':taskId',
                    name: RouteNames.studentTaskDetails,
                    builder: (context, state) {
                      final taskId = state.pathParameters['taskId'] ?? '';
                      return Scaffold(
                        body: Center(child: Text('Task Details: $taskId')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'attendance',
                name: RouteNames.studentAttendance,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Student Attendance')),
                ),
              ),
              GoRoute(
                path: 'payments',
                name: RouteNames.studentPayments,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Student Payments')),
                ),
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
                BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Classes'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
                BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Tutor Dashboard')),
            ),
            routes: [
              GoRoute(
                path: 'profile',
                name: RouteNames.tutorProfile,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Profile')),
                ),
              ),
              GoRoute(
                path: 'subjects',
                name: RouteNames.tutorSubjects,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Subjects')),
                ),
                routes: [
                  GoRoute(
                    path: ':subjectId',
                    name: RouteNames.tutorSubjectDetails,
                    builder: (context, state) {
                      final subjectId = state.pathParameters['subjectId'] ?? '';
                      return Scaffold(
                        body: Center(child: Text('Subject Details: $subjectId')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'students',
                name: RouteNames.tutorStudents,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Students')),
                ),
                routes: [
                  GoRoute(
                    path: ':studentId',
                    name: RouteNames.tutorStudentDetails,
                    builder: (context, state) {
                      final studentId = state.pathParameters['studentId'] ?? '';
                      return Scaffold(
                        body: Center(child: Text('Student Details: $studentId')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'classes',
                name: RouteNames.tutorClasses,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Classes')),
                ),
                routes: [
                  GoRoute(
                    path: ':classId',
                    name: RouteNames.tutorClassDetails,
                    builder: (context, state) {
                      final classId = state.pathParameters['classId'] ?? '';
                      return Scaffold(
                        body: Center(child: Text('Class Details: $classId')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'tasks',
                name: RouteNames.tutorTasks,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Tasks')),
                ),
                routes: [
                  GoRoute(
                    path: ':taskId',
                    name: RouteNames.tutorTaskDetails,
                    builder: (context, state) {
                      final taskId = state.pathParameters['taskId'] ?? '';
                      return Scaffold(
                        body: Center(child: Text('Task Details: $taskId')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'attendance',
                name: RouteNames.tutorAttendance,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Attendance')),
                ),
              ),
              GoRoute(
                path: 'payments',
                name: RouteNames.tutorPayments,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Tutor Payments')),
                ),
              ),
            ],
          ),
        ],
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
    if (location.startsWith('/tutor/profile')) return 4;
    if (location.startsWith('/tutor/classes')) return 1;
    if (location.startsWith('/tutor/students')) return 2;
    if (location.startsWith('/tutor/tasks')) return 3;
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
        GoRouter.of(context).goNamed(RouteNames.tutorTasks);
        break;
      case 4:
        GoRouter.of(context).goNamed(RouteNames.tutorProfile);
        break;
    }
  }
}