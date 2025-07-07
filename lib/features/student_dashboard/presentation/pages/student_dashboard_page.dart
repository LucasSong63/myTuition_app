// lib/features/student_dashboard/presentation/pages/student_dashboard_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:mytuition/features/student_dashboard/presentation/widgets/upcoming_classes_widget.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/student_dashboard_bloc.dart';
import '../bloc/student_dashboard_event.dart';
import '../bloc/student_dashboard_state.dart';
import '../../domain/entities/student_dashboard_stats.dart';
import '../widgets/ai_usage_widget.dart';
import '../widgets/student_recent_activity_bottom_sheet.dart';

class StudentDashboardPage extends StatefulWidget {
  final String studentId;

  const StudentDashboardPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late StreamSubscription<AuthState> _authSubscription;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Load dashboard data
    context.read<StudentDashboardBloc>().add(
          LoadStudentDashboardEvent(studentId: widget.studentId),
        );

    // Listen for auth state changes
    _authSubscription = context.read<AuthBloc>().stream.listen((state) {
      if (state is Unauthenticated && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).go('/login');
        });
      }
    });

    // Set up auto-refresh timer (every 5 minutes)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        context.read<StudentDashboardBloc>().add(
              RefreshStudentDashboardEvent(studentId: widget.studentId),
            );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // Notification Badge
          NotificationBadge(
            userId: widget.studentId,
            badgeColor: AppColors.error,
            iconColor: AppColors.white,
            onTap: () {
              context.push('/notifications');
            },
            semanticsLabel: 'Notifications',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: BlocBuilder<StudentDashboardBloc, StudentDashboardState>(
        builder: (context, state) {
          if (state is StudentDashboardLoading) {
            return _buildLoadingState();
          }

          if (state is StudentDashboardError) {
            return _buildErrorState(state.message);
          }

          if (state is StudentDashboardLoaded ||
              state is StudentDashboardPartiallyLoaded) {
            final stats = state is StudentDashboardLoaded
                ? state.stats
                : (state as StudentDashboardPartiallyLoaded).stats;

            final warning =
                state is StudentDashboardPartiallyLoaded ? state.warning : null;

            return _buildDashboardContent(stats, warning);
          }

          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 1.w,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading your dashboard...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 16.w,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<StudentDashboardBloc>().add(
                      LoadStudentDashboardEvent(studentId: widget.studentId),
                    );
              },
              icon: Icon(Icons.refresh, size: 5.w),
              label: Text(
                'Try Again',
                style: TextStyle(fontSize: 16.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 1.w,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          SizedBox(height: 2.h),
          Text(
            'Setting up your dashboard...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(StudentDashboardStats stats, String? warning) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<StudentDashboardBloc>().add(
              RefreshStudentDashboardEvent(studentId: widget.studentId),
            );
        await Future.delayed(const Duration(milliseconds: 800));
      },
      color: AppColors.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner if any
            if (warning != null) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(4.w),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(color: AppColors.warning, width: 0.3.w),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 6.w),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Welcome section
            _buildWelcomeSection(),
            SizedBox(height: 3.h),

            // Quick Actions Row (includes Notifications)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildQuickActions(),
            ),
            SizedBox(height: 3.h),

            // Stats cards grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildStatsGrid(stats),
            ),
            SizedBox(height: 3.h),

            // AI Usage widget
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: AIUsageWidget(aiUsage: stats.aiUsage),
            ),
            SizedBox(height: 3.h),

            // Outstanding payments warning (if any)
            if (stats.hasOutstandingPayments) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildOutstandingPaymentsBanner(),
              ),
              SizedBox(height: 3.h),
            ],

            // 🎯 NEW: Upcoming classes widget implementation
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: UpcomingClassesWidget(
                upcomingClasses: stats.upcomingClassesThisWeek,
                onViewAll: () => context.push('/student/courses'),
              ),
            ),
            SizedBox(height: 3.h),

            // Recent tasks
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildRecentTasks(stats.recentTasks),
            ),
            SizedBox(height: 3.h),

            // Recent activity
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildRecentActivity(stats.recentActivities),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final timeEmoji = _getTimeEmoji(now.hour);

    // Get student name from auth state
    final authState = context.read<AuthBloc>().state;
    final studentName =
        authState is Authenticated ? (authState.user.name) : 'Student';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlueDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 3.w,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                timeEmoji,
                style: TextStyle(fontSize: 6.w, color: Colors.yellow),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  '$greeting $studentName!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Welcome back! Here\'s your learning overview for today.',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 10.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickActionCard(
            icon: Icons.notifications_active,
            label: 'Notifications',
            color: AppColors.accentOrange,
            onTap: () => context.push('/notifications'),
          ),
          SizedBox(width: 3.w),
          _buildQuickActionCard(
            icon: Icons.calendar_today,
            label: 'Schedule',
            color: AppColors.accentTeal,
            onTap: () => context.push('/student/courses'),
          ),
          SizedBox(width: 3.w),
          _buildQuickActionCard(
            icon: Icons.assignment,
            label: 'Tasks',
            color: AppColors.secondaryBlue,
            onTap: () => context.push('/student/tasks'),
          ),
          SizedBox(width: 3.w),
          _buildQuickActionCard(
            icon: Icons.psychology,
            label: 'AI Tutor',
            color: AppColors.primaryBlue,
            onTap: () => context.push('/student/ai-chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3.w),
      child: Container(
        width: 22.w,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.3.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 6.w,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  String _getTimeEmoji(int hour) {
    if (hour < 6) {
      return '🌙';
    } else if (hour < 12) {
      return '🌅';
    } else if (hour < 17) {
      return '☀️';
    } else if (hour < 20) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  Widget _buildStatsGrid(StudentDashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on screen width
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) {
          crossAxisCount = 3; // 3 columns for tablets
        }

        // Calculate card width with proper spacing
        final spacing = 3.w;
        final cardWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildFlexibleStatCard(
                title: 'My Courses',
                value: stats.enrolledCoursesCount.toString(),
                subtitle: 'Enrolled courses',
                icon: Icons.book,
                emoji: '📚',
                backgroundColor: AppColors.primaryBlue,
                onTap: () => context.push('/student/courses'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFlexibleStatCard(
                title: 'Pending Tasks',
                value: stats.pendingTasksCount.toString(),
                subtitle: 'Tasks to complete',
                icon: Icons.assignment,
                emoji: '📝',
                backgroundColor: AppColors.accentOrange,
                onTap: () => context.push('/student/tasks'),
                hasNotification: stats.pendingTasksCount > 0,
                notificationCount: stats.pendingTasksCount,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFlexibleStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required String emoji,
    required Color backgroundColor,
    required VoidCallback onTap,
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive font sizes based on card width
        final isSmallCard = constraints.maxWidth < 150;
        final isMediumCard = constraints.maxWidth < 200;

        final valueSize = isSmallCard
            ? 16.0
            : isMediumCard
                ? 18.0
                : 20.0;
        final titleSize = isSmallCard
            ? 10.0
            : isMediumCard
                ? 11.0
                : 12.0;
        final subtitleSize = isSmallCard
            ? 8.0
            : isMediumCard
                ? 9.0
                : 10.0;
        final emojiSize = isSmallCard
            ? 16.0
            : isMediumCard
                ? 18.0
                : 20.0;

        return Card(
          elevation: 2,
          shadowColor: backgroundColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 100,
              ),
              padding: EdgeInsets.all(isSmallCard ? 8.0 : 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    backgroundColor.withOpacity(0.1),
                    backgroundColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with emoji and notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallCard ? 6.0 : 8.0),
                        decoration: BoxDecoration(
                          color: backgroundColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: emojiSize),
                        ),
                      ),
                      if (hasNotification && notificationCount > 0)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            notificationCount.toString(),
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: isSmallCard ? 8.0 : 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: isSmallCard ? 8.0 : 12.0),

                  // Bottom content
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Value
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: valueSize,
                              fontWeight: FontWeight.bold,
                              color: backgroundColor,
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallCard ? 2.0 : 4.0),

                        // Title
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallCard ? 1.0 : 2.0),

                        // Subtitle
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: AppColors.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutstandingPaymentsBanner() {
    return Card(
      elevation: 0.5.w,
      shadowColor: AppColors.warning.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withOpacity(0.1),
              AppColors.warning.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Text(
                '⚠️',
                style: TextStyle(fontSize: 6.w),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Reminder',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'You have outstanding tuition fees. Please contact your tutor for payment details.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks(List<PendingTask> recentTasks) {
    return Card(
      elevation: 0.5.w,
      shadowColor: AppColors.accentOrange.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: LinearGradient(
            colors: [
              AppColors.accentOrange.withOpacity(0.1),
              AppColors.accentOrange.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        '📝',
                        style: TextStyle(fontSize: 6.w),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Recent Tasks',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => context.push('/student/tasks'),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(1.5.w),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            if (recentTasks.isNotEmpty) ...[
              ...recentTasks.take(3).map((task) => _buildTaskItem(task)),
            ] else ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Text(
                        '✅',
                        style: TextStyle(fontSize: 12.w),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No pending tasks',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(PendingTask task) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: task.isOverdue
            ? AppColors.errorLight.withOpacity(0.1)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(3.w),
        border: task.isOverdue
            ? Border.all(color: AppColors.error.withOpacity(0.3), width: 0.3.w)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: task.isOverdue
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  task.dueDateText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: task.isOverdue
                        ? AppColors.error
                        : AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            task.courseName,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textMedium,
            ),
          ),
          if (task.description.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textMedium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<StudentActivity> activities) {
    return Card(
      elevation: 0.5.w,
      shadowColor: AppColors.primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withOpacity(0.1),
              AppColors.primaryBlue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        '⚡',
                        style: TextStyle(fontSize: 6.w),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (activities.length > 3)
                  InkWell(
                    onTap: () => StudentRecentActivityBottomSheet.show(
                      context: context,
                      activities: activities,
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1.5.w),
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 3.h),
            if (activities.isNotEmpty) ...[
              ...activities
                  .take(5)
                  .map((activity) => _buildActivityItem(activity)),
            ] else ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Text(
                        '📊',
                        style: TextStyle(fontSize: 12.w),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(StudentActivity activity) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(5.w),
            ),
            child: Center(
              child: Text(
                activity.type.icon,
                style: TextStyle(fontSize: 5.w),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Text(
              activity.timeAgo,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(StudentActivityType type) {
    switch (type) {
      case StudentActivityType.taskAssigned:
        return AppColors.primaryBlue;
      case StudentActivityType.taskRemarks:
        return AppColors.success;
      case StudentActivityType.scheduleChange:
        return AppColors.accentTeal;
      case StudentActivityType.scheduleReplacement:
        return AppColors.warning;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            child: const Text('Logout'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
    );
  }
}
