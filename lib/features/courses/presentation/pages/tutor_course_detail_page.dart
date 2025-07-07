// lib/features/courses/presentation/pages/tutor_course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import 'package:mytuition/features/courses/presentation/utils/course_detail_utils.dart';
import 'package:mytuition/features/courses/presentation/widgets/capacity_edit_bottom_sheet.dart';
import 'package:mytuition/features/courses/presentation/widgets/course_tasks_section.dart';
import 'package:mytuition/features/courses/presentation/widgets/schedule_bottom_sheet.dart';
import 'package:mytuition/features/courses/presentation/widgets/replacement_schedule_bottom_sheet.dart';
import 'package:mytuition/features/courses/domain/entities/activity.dart';

class TutorCourseDetailPage extends StatefulWidget {
  final String courseId;

  const TutorCourseDetailPage({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  State<TutorCourseDetailPage> createState() => _TutorCourseDetailPageState();
}

class _TutorCourseDetailPageState extends State<TutorCourseDetailPage>
    with SingleTickerProviderStateMixin {
  final GetIt getIt = GetIt.instance;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Add scroll listener to control app bar title visibility
    _scrollController.addListener(() {
      setState(() {
        _showTitle = _scrollController.offset > 30.w;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: AppColors.success,
            ),
          );
        }

        if (state is CourseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CourseError) {
          return _buildErrorScreen(state.message);
        }

        if (state is! CourseDetailsLoaded ||
            (state is CourseDetailsLoaded &&
                state.course.id != widget.courseId)) {
          context.read<CourseBloc>().add(
                LoadCourseDetailsEvent(courseId: widget.courseId),
              );
          // Also load recent activities
          context.read<CourseBloc>().add(
                LoadRecentActivitiesEvent(courseId: widget.courseId),
              );
          return _buildLoadingScreen();
        }

        final course = state.course;
        return _buildCourseDetailScreen(course);
      },
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Course Details', style: TextStyle(fontSize: 18.sp))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 12.w),
            SizedBox(height: 2.h),
            Text('Error: $message',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => context.read<CourseBloc>().add(
                    LoadCourseDetailsEvent(courseId: widget.courseId),
                  ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
          title: Text('Course Details', style: TextStyle(fontSize: 18.sp))),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCourseDetailScreen(Course course) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Custom app bar with course info
            SliverAppBar(
              expandedHeight: 25.h,
              pinned: true,
              backgroundColor:
                  CourseDetailUtils.getSubjectColor(course.subject),
              // Only show title when scrolled down
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showTitle ? 1.0 : 0.0,
                child: Text(
                  '${course.subject} (Grade ${course.grade})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildCourseHeader(course),
              ),
            ),
            // Quick action buttons as part of header
            SliverToBoxAdapter(
              child: _buildQuickActions(course),
            ),
            // Tab bar with improved design - using persistent header for better performance
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textMedium,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.primaryBlue,
                  indicator: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primaryBlue,
                        width: 0.75.w,
                      ),
                    ),
                  ),
                  labelStyle:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                  tabs: [
                    Tab(
                        text: 'Overview',
                        icon: Icon(Icons.dashboard_outlined, size: 5.w)),
                    Tab(
                        text: 'Schedule',
                        icon: Icon(Icons.schedule_outlined, size: 5.w)),
                    Tab(
                        text: 'Tasks',
                        icon: Icon(Icons.assignment_outlined, size: 5.w)),
                    Tab(
                        text: 'Settings',
                        icon: Icon(Icons.settings_outlined, size: 5.w)),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(course),
            _buildScheduleTab(course),
            _buildTasksTab(course),
            _buildSettingsTab(course),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader(Course course) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CourseDetailUtils.getSubjectColor(course.subject),
            CourseDetailUtils.getSubjectColor(course.subject).withOpacity(0.8),
          ],
        ),
      ),
      padding: EdgeInsets.all(4.w),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  child: Icon(
                    CourseDetailUtils.getSubjectIcon(course.subject),
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.subject,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Grade ${course.grade} • ${course.enrollmentCount} students',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(course),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildStatCard(
                    'Enrollment',
                    '${course.enrollmentCount}/${course.capacity}',
                    Icons.people),
                SizedBox(width: 4.w),
                _buildStatCard(
                    'Sessions',
                    '${course.schedules.where((s) => s.isRegular).length}/week',
                    Icons.schedule),
                SizedBox(width: 4.w),
                _buildStatCard('Active', course.isActive ? 'Yes' : 'No',
                    course.isActive ? Icons.check_circle : Icons.cancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Course course) {
    return GestureDetector(
      onTap: () => _toggleCourseActiveStatus(context, course),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: course.isActive
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(5.w),
          border: Border.all(
            color: course.isActive ? Colors.green : Colors.red,
            width: 0.4.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              course.isActive ? Icons.check_circle : Icons.cancel,
              size: 4.w,
              color: course.isActive ? Colors.green : Colors.red,
            ),
            SizedBox(width: 1.w),
            Text(
              course.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: course.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2.w),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 5.w),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Course course) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Manage Attendance',
              Icons.people_alt,
              AppColors.primaryBlue,
              () => _navigateToAttendanceManagement(context),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildActionButton(
              'Manage Tasks',
              Icons.assignment,
              AppColors.accentTeal,
              () => context.push('/tutor/courses/${course.id}/tasks',
                  extra: course.subject),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildActionButton(
              'Add Schedule',
              Icons.add_circle,
              AppColors.accentOrange,
              () => _showScheduleOptions(context, course),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Course course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enrollment overview
          _buildEnrollmentOverview(course),
          SizedBox(height: 3.h),

          // Recent activities
          _buildRecentActivities(),
          SizedBox(height: 3.h),

          // Quick stats
          _buildQuickStats(course),
        ],
      ),
    );
  }

  Widget _buildEnrollmentOverview(Course course) {
    final capacityPercentage = course.enrollmentPercentage;
    Color capacityColor = AppColors.success;
    if (course.isAtCapacity) {
      capacityColor = AppColors.error;
    } else if (course.isNearCapacity) {
      capacityColor = AppColors.warning;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class Enrollment',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 5.w),
                  onPressed: () => CapacityEditBottomSheet.show(
                    context: context,
                    course: course,
                  ),
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Enrollment:',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${course.enrollmentCount} of ${course.capacity} students',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: capacityColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(2.w),
              child: LinearProgressIndicator(
                value: capacityPercentage / 100,
                minHeight: 2.h,
                backgroundColor: AppColors.backgroundDark,
                color: capacityColor,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              CourseDetailUtils.getCapacityStatusText(course),
              style: TextStyle(
                color: capacityColor,
                fontStyle: FontStyle.italic,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 5.w),
                  onPressed: () {
                    // Reload recent activities
                    context.read<CourseBloc>().add(
                          LoadRecentActivitiesEvent(courseId: widget.courseId),
                        );
                  },
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Use BlocBuilder to handle the real-time data
            BlocBuilder<CourseBloc, CourseState>(
              builder: (context, state) {
                // Check if we have course details with activities
                if (state is CourseDetailsLoaded) {
                  final activities = state.recentActivities;

                  if (activities == null) {
                    // Activities not loaded yet
                    return _buildActivitiesLoadingState();
                  }

                  if (activities.isEmpty) {
                    return _buildEmptyActivitiesState();
                  }

                  return Column(
                    children: activities
                        .map((activity) => _buildRealActivityItem(activity))
                        .toList(),
                  );
                }

                // Fallback for other states
                return _buildActivitiesLoadingState();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Updated _buildActivityItem method to use real Activity objects
  Widget _buildRealActivityItem(Activity activity) {
    // Get color based on activity type
    Color color;
    IconData icon;

    switch (activity.type) {
      case ActivityType.attendance:
        color = AppColors.success;
        icon = Icons.people;
        break;
      case ActivityType.task:
        color = AppColors.primaryBlue;
        icon = Icons.assignment;
        break;
      case ActivityType.schedule:
        color = AppColors.accentOrange;
        icon = Icons.schedule;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Icon(icon, color: color, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                if (activity.description.isNotEmpty)
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  activity.relativeTime,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          // Optional: Add a tap handler for more details
          if (activity.type == ActivityType.task)
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 4.w),
              onPressed: () {
                // Navigate to task details if it's a task activity
                final taskId = activity.metadata?['taskId'] as String?;
                if (taskId != null) {
                  context.push('/tutor/tasks/\$taskId');
                }
              },
              color: AppColors.textLight,
            ),
        ],
      ),
    );
  }

  // Add these helper methods for loading and empty states
  Widget _buildActivitiesLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 5.w,
            height: 5.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'Loading activities...',
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivitiesState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 12.w,
            color: AppColors.textLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No recent activities',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Activities will appear here when you take attendance,\nassign tasks, or update schedules',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Course course) {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard('Total Students',
              '${course.enrollmentCount}', Icons.people, AppColors.primaryBlue),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatisticCard(
              'Weekly Sessions',
              '${course.schedules.where((s) => s.isRegular).length}',
              Icons.schedule,
              AppColors.accentTeal),
        ),
      ],
    );
  }

  Widget _buildStatisticCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 8.w),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab(Course course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add schedule buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddScheduleDialog(context, course.id),
                  icon: Icon(Icons.add, size: 5.w),
                  label: Text('Regular Schedule',
                      style: TextStyle(fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showAddReplacementScheduleBottomSheet(context, course),
                  icon: Icon(Icons.event_repeat, size: 5.w),
                  label: Text('Replacement', style: TextStyle(fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Regular schedules
          _buildScheduleSection('Regular Schedules',
              course.schedules.where((s) => s.isRegular).toList(), false),
          SizedBox(height: 3.h),

          // Replacement schedules
          _buildScheduleSection(
              'Replacement Schedules',
              course.schedules
                  .where((s) => s.isReplacement && !s.isExpired && s.isActive)
                  .toList(),
              true),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
      String title, List<Schedule> schedules, bool isReplacement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isReplacement && schedules.isNotEmpty) ...[
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Text(
                  '${schedules.length}',
                  style: TextStyle(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 2.h),
        if (schedules.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w)),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: Text(
                  'No ${isReplacement ? 'replacement' : 'regular'} schedules yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMedium,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              return _buildScheduleCard(
                  context, schedules[index], widget.courseId, isReplacement);
            },
          ),
      ],
    );
  }

  Widget _buildTasksTab(Course course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          CourseTasksSection(
            courseId: course.id,
            isTutor: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(Course course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Settings',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),

          // Course status
          _buildSettingCard(
            'Course Status',
            'Manage course availability',
            Icons.power_settings_new,
            () => _toggleCourseActiveStatus(context, course),
            trailing: Switch(
              value: course.isActive,
              onChanged: (_) => _toggleCourseActiveStatus(context, course),
              activeColor: AppColors.success,
            ),
          ),

          // Capacity management
          _buildSettingCard(
            'Class Capacity',
            'Current: ${course.enrollmentCount}/${course.capacity} students',
            Icons.people,
            () =>
                CapacityEditBottomSheet.show(context: context, course: course),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
      String title, String subtitle, IconData icon, VoidCallback onTap,
      {Widget? trailing}) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 6.w),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textMedium),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 4.w),
        onTap: onTap,
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, Schedule schedule,
      String courseId, bool isReplacement) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
        side: isReplacement
            ? BorderSide(
                color: AppColors.accentOrange.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isReplacement
                        ? AppColors.accentOrange.withOpacity(0.2)
                        : CourseDetailUtils.getSubjectColor(schedule.subject)
                            .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isReplacement) ...[
                        Icon(Icons.event_repeat,
                            size: 4.w, color: AppColors.accentOrange),
                        SizedBox(width: 1.w),
                      ],
                      Text(
                        schedule.displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isReplacement
                              ? AppColors.accentOrange
                              : CourseDetailUtils.getSubjectColor(
                                  schedule.subject),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 4.w, color: AppColors.textMedium),
                SizedBox(width: 1.w),
                Text(
                  '${CourseDetailUtils.formatTime(schedule.startTime)} - ${CourseDetailUtils.formatTime(schedule.endTime)}',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            if (isReplacement && schedule.specificDate != null) ...[
              SizedBox(height: 1.h),
              Text(
                'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(schedule.specificDate!)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentOrange,
                  fontSize: 12.sp,
                ),
              ),
            ],
            if (schedule.displaySubtitle.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                schedule.displaySubtitle,
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 11.sp,
                ),
              ),
            ],
            SizedBox(height: 2.h),
            const Divider(),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 4.w, color: AppColors.textMedium),
                    SizedBox(width: 1.w),
                    Text(
                      schedule.location,
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!isReplacement) ...[
                      IconButton(
                        icon: Icon(Icons.edit, size: 5.w),
                        onPressed: () => _showEditScheduleDialog(
                            context, courseId, schedule),
                        color: AppColors.primaryBlue,
                        padding: EdgeInsets.all(1.w),
                      ),
                    ],
                    IconButton(
                      icon: Icon(Icons.delete, size: 5.w),
                      onPressed: () => _confirmDeleteSchedule(
                          context, courseId, schedule.id),
                      color: AppColors.error,
                      padding: EdgeInsets.all(1.w),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleOptions(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (innerContext) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Schedule',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading:
                  Icon(Icons.schedule, color: AppColors.primaryBlue, size: 6.w),
              title:
                  Text('Regular Schedule', style: TextStyle(fontSize: 14.sp)),
              subtitle: Text('Weekly recurring class',
                  style: TextStyle(fontSize: 12.sp)),
              onTap: () {
                Navigator.pop(innerContext);
                _showAddScheduleDialog(context, course.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.event_repeat,
                  color: AppColors.accentOrange, size: 6.w),
              title: Text('Replacement Schedule',
                  style: TextStyle(fontSize: 14.sp)),
              subtitle: Text('One-time makeup or extension class',
                  style: TextStyle(fontSize: 12.sp)),
              onTap: () {
                Navigator.pop(context);
                _showAddReplacementScheduleBottomSheet(context, course);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCourseActiveStatus(BuildContext context, Course course) {
    final courseBloc = context.read<CourseBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          course.isActive ? 'Deactivate Course' : 'Activate Course',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Text(
          course.isActive
              ? 'This will hide the course from students. Are you sure you want to deactivate this course?'
              : 'This will make the course visible to enrolled students. Are you sure you want to activate this course?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              courseBloc.add(
                UpdateCourseActiveStatusEvent(
                  courseId: course.id,
                  isActive: !course.isActive,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  course.isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(
              course.isActive ? 'Deactivate' : 'Activate',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, String courseId) {
    ScheduleBottomSheet.show(
      context: context,
      courseId: courseId,
    );
  }

  void _showEditScheduleDialog(
      BuildContext context, String courseId, Schedule schedule) {
    ScheduleBottomSheet.show(
      context: context,
      courseId: courseId,
      existingSchedule: schedule,
    );
  }

  void _confirmDeleteSchedule(
      BuildContext context, String courseId, String scheduleId) {
    final courseBloc = context.read<CourseBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Schedule', style: TextStyle(fontSize: 16.sp)),
        content: Text(
          'Are you sure you want to delete this schedule? This action cannot be undone.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              courseBloc.add(DeleteScheduleEvent(
                  courseId: courseId, scheduleId: scheduleId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showAddReplacementScheduleBottomSheet(
      BuildContext context, Course course) {
    ReplacementScheduleBottomSheet.show(
      context: context,
      course: course,
    );
  }

  void _navigateToAttendanceManagement(BuildContext context) {
    context.push(
      '/tutor/courses/${widget.courseId}/attendance',
      extra: context.read<CourseBloc>().state is CourseDetailsLoaded
          ? (context.read<CourseBloc>().state as CourseDetailsLoaded)
              .course
              .subject
          : 'Course',
    );
  }
}

// SliverPersistentHeaderDelegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true; // This ensures the delegate rebuilds if the TabBar changes
  }
}
