// lib/features/auth/presentation/pages/tutor_dashboard_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/features/tutor_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/bloc/dashboard_event.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/bloc/dashboard_state.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/widgets/recent_activity_bottom_sheet.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';

class TutorDashboardPage extends StatefulWidget {
  const TutorDashboardPage({Key? key}) : super(key: key);

  @override
  State<TutorDashboardPage> createState() => _TutorDashboardPageState();
}

class _TutorDashboardPageState extends State<TutorDashboardPage> {
  late StreamSubscription<AuthState> _authSubscription;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Load dashboard data
    context.read<DashboardBloc>().add(const LoadDashboardOverviewEvent());

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
        context.read<DashboardBloc>().add(const RefreshDashboardEvent());
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 1.w,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardError) {
            return _buildErrorState(state.message);
          }

          if (state is DashboardLoaded || state is DashboardPartiallyLoaded) {
            final stats = state is DashboardLoaded
                ? state.stats
                : (state as DashboardPartiallyLoaded).stats;

            final warning =
                state is DashboardPartiallyLoaded ? state.warning : null;

            return _buildDashboardContent(stats, warning);
          }

          return _buildInitialState();
        },
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
                context
                    .read<DashboardBloc>()
                    .add(const LoadDashboardOverviewEvent());
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

  Widget _buildDashboardContent(DashboardStats stats, String? warning) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const RefreshDashboardEvent());
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

            // Stats cards grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildStatsGrid(stats),
            ),
            SizedBox(height: 3.h),

            // Payment overview
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildPaymentOverview(stats.paymentOverview),
            ),
            SizedBox(height: 3.h),

            // Upcoming classes
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildUpcomingClasses(stats.upcomingClassesThisWeek),
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
                style: TextStyle(fontSize: 6.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Welcome back! Here\'s your teaching overview for today.',
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

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
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

  Widget _buildStatsGrid(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on screen width
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) {
          crossAxisCount = 3; // 3 columns for tablets
        }
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4; // 4 columns for desktop
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
                title: 'Total Students',
                value: stats.totalStudents.toString(),
                subtitle: 'Enrolled students',
                icon: Icons.people,
                emoji: '👥',
                backgroundColor: AppColors.primaryBlue,
                onTap: () => context.push('/tutor/students'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFlexibleStatCard(
                title: 'Active Classes',
                value: stats.activeCourses.toString(),
                subtitle: 'Running courses',
                icon: Icons.class_,
                emoji: '📚',
                backgroundColor: AppColors.accentTeal,
                onTap: () => context.push('/tutor/classes'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFlexibleStatCard(
                title: 'Pending Requests',
                value: stats.pendingRegistrations.toString(),
                subtitle: 'New registrations',
                icon: Icons.pending_actions,
                emoji: '📝',
                backgroundColor: AppColors.warning,
                onTap: () => context.push('/tutor/registrations'),
                hasNotification: stats.pendingRegistrations > 0,
                notificationCount: stats.pendingRegistrations,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFlexibleStatCard(
                title: 'Today\'s Classes',
                value: stats.upcomingClassesToday.length.toString(),
                subtitle: 'Classes scheduled',
                icon: Icons.today,
                emoji: '📅',
                backgroundColor: AppColors.accentOrange,
                onTap: () => context.push('/tutor/classes'),
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
                minHeight: 100, // Minimum height to prevent too small cards
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
                // Important: Let content determine size
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

                  // Flexible space between top and bottom
                  SizedBox(height: isSmallCard ? 8.0 : 12.0),

                  // Bottom content with value, title, and subtitle
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Value with FittedBox to prevent overflow
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

                        // Title with flexible text handling
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

                        // Subtitle with overflow handling
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

  Widget _buildPaymentOverview(PaymentOverview paymentOverview) {
    return Card(
      elevation: 0.5.w,
      shadowColor: AppColors.success.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: InkWell(
        onTap: () => context.push('/tutor/payments'),
        borderRadius: BorderRadius.circular(4.w),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.w),
            gradient: LinearGradient(
              colors: [
                AppColors.success.withOpacity(0.1),
                AppColors.success.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      '💰',
                      style: TextStyle(fontSize: 5.w),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Payment Overview',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textMedium,
                    size: 4.w,
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentStat(
                      'Paid',
                      paymentOverview.paidPayments.toString(),
                      AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: _buildPaymentStat(
                      'Unpaid',
                      paymentOverview.unpaidPayments.toString(),
                      AppColors.error,
                    ),
                  ),
                  Expanded(
                    child: _buildPaymentStat(
                      'Partial',
                      paymentOverview.partialPayments.toString(),
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.2),
                    width: 0.3.w,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Rate',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                        Text(
                          '${paymentOverview.paymentCompletionRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Outstanding',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                        Text(
                          'RM ${paymentOverview.outstandingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingClasses(List<UpcomingClass> upcomingClasses) {
    final todayClasses = upcomingClasses.where((c) => c.isToday).toList();
    final nextFewClasses = upcomingClasses.take(3).toList();

    return Card(
      elevation: 0.5.w,
      shadowColor: AppColors.accentTeal.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: LinearGradient(
            colors: [
              AppColors.accentTeal.withOpacity(0.1),
              AppColors.accentTeal.withOpacity(0.05),
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
                        color: AppColors.accentTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        '📖',
                        style: TextStyle(fontSize: 6.w),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Upcoming Classes',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => context.push('/tutor/classes'),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(1.5.w),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            if (todayClasses.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: AppColors.accentTeal.withOpacity(0.3),
                    width: 0.3.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.today,
                          color: AppColors.accentTeal,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ...todayClasses.map(
                        (class_) => _buildClassItem(class_, isToday: true)),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
            ],
            if (nextFewClasses.isNotEmpty) ...[
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 1.h),
              ...nextFewClasses.map((class_) => _buildClassItem(class_)),
            ] else ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Text(
                        '📅',
                        style: TextStyle(fontSize: 12.w),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No upcoming classes this week',
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

  Widget _buildClassItem(UpcomingClass class_, {bool isToday = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.accentTeal.withOpacity(0.1)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(3.w),
        border: isToday
            ? Border.all(
                color: AppColors.accentTeal.withOpacity(0.3), width: 0.3.w)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  class_.displayTitle,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 3.5.w,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      class_.timeRange,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      Icons.location_on,
                      size: 3.5.w,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        class_.location,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Text(
                  '${class_.enrolledStudents} students',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!class_.isToday) ...[
                SizedBox(height: 0.5.h),
                Text(
                  class_.day,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<RecentActivity> activities) {
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
                    onTap: () => RecentActivityBottomSheet.show(
                      context: context,
                      activities: activities,
                    ),
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

  Widget _buildActivityItem(RecentActivity activity) {
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

  Color _getActivityColor(RecentActivityType type) {
    switch (type) {
      case RecentActivityType.payment:
        return AppColors.success;
      case RecentActivityType.taskSubmission:
        return AppColors.primaryBlue;
      case RecentActivityType.attendance:
        return AppColors.accentTeal;
      case RecentActivityType.enrollment:
        return AppColors.accentOrange;
      case RecentActivityType.registration:
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
