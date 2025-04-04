import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/features/auth/presentation/bloc/registration_bloc.dart';
import 'package:mytuition/features/auth/presentation/pages/demo_home_screen.dart';
import 'package:mytuition/features/auth/presentation/pages/email_verification_page.dart';
import 'package:mytuition/features/auth/presentation/pages/login_page.dart';
import 'package:mytuition/features/auth/presentation/pages/register_page.dart';
import 'package:mytuition/features/auth/presentation/pages/registration_details_page.dart';
import 'package:mytuition/features/auth/presentation/pages/registration_list_page.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/pages/profile_page.dart';
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
              // Student routes (add others as needed)...
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
                BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
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

              // Other tutor routes...
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
