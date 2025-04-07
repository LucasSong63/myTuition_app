import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../widgets/upcoming_schedules_widget.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get user info from auth state
    final authState = context.read<AuthBloc>().state;
    String userName = '';
    if (authState is Authenticated) {
      userName = authState.user.name;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh dashboard data
            if (authState is Authenticated) {
              context.read<CourseBloc>().add(
                    LoadEnrolledCoursesEvent(studentId: authState.user.id),
                  );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting section
                _buildGreetingSection(context, userName),
                const SizedBox(height: 24),

                // Quick stats cards
                _buildQuickStatsSection(context),
                const SizedBox(height: 24),

                // Upcoming classes section
                _buildUpcomingClassesSection(context),
                const SizedBox(height: 24),

                // Quick access buttons
                _buildQuickAccessSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context, String userName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${userName.isNotEmpty ? userName.split(' ')[0] : 'Student'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome to your dashboard',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Handle notifications
          },
        ),
      ],
    );
  }

  Widget _buildQuickStatsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Courses',
            '3',
            Icons.book,
            AppColors.primaryBlue,
            () {
              context.pushNamed(RouteNames.studentCourses);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Tasks',
            '5',
            Icons.assignment,
            AppColors.accentOrange,
            () {
              context.pushNamed(RouteNames.studentTasks);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'AI Chat',
            '0/20',
            Icons.chat,
            AppColors.accentTeal,
            () {
              context.pushNamed(RouteNames.studentAiChat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingClassesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.pushNamed(RouteNames.studentCourses);
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocProvider(
          create: (context) => GetIt.instance<CourseBloc>(),
          child: const UpcomingSchedulesWidget(),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAccessButton(
              context,
              'Attendance',
              Icons.fact_check,
              () {
                // Navigate to attendance page
              },
            ),
            _buildQuickAccessButton(
              context,
              'AI Chat',
              Icons.smart_toy,
              () {
                context.pushNamed(RouteNames.studentAiChat);
              },
            ),
            _buildQuickAccessButton(
              context,
              'Payments',
              Icons.payment,
              () {
                context.pushNamed(RouteNames.studentPayments);
              },
            ),
            _buildQuickAccessButton(
              context,
              'Profile',
              Icons.person,
              () {
                context.pushNamed(RouteNames.studentProfile);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
