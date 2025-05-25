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
import 'package:mytuition/features/courses/presentation/widgets/schedule_dialog.dart';
import 'package:mytuition/features/courses/presentation/widgets/replacement_schedule_bottom_sheet.dart';

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
        _showTitle = _scrollController.offset > 120;
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
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        }

        if (state is CourseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
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
          return _buildLoadingScreen();
        }

        final course = state.course;
        return _buildCourseDetailScreen(course);
      },
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
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
              child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
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
                  indicator: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primaryBlue,
                        width: 3.0,
                      ),
                    ),
                  ),
                  labelStyle:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                  tabs: const [
                    Tab(
                        text: 'Overview',
                        icon: Icon(Icons.dashboard_outlined, size: 20)),
                    Tab(
                        text: 'Schedule',
                        icon: Icon(Icons.schedule_outlined, size: 20)),
                    Tab(
                        text: 'Tasks',
                        icon: Icon(Icons.assignment_outlined, size: 20)),
                    Tab(
                        text: 'Settings',
                        icon: Icon(Icons.settings_outlined, size: 20)),
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
                    borderRadius: BorderRadius.circular(12),
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
                _buildStatCard('Sessions', '${course.schedules.length}/week',
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: course.isActive ? Colors.green : Colors.red,
            width: 1.5,
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
          borderRadius: BorderRadius.circular(8),
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
              'Take Attendance',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              fontSize: 11.sp, // Increased from 10.sp
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  icon: const Icon(Icons.edit),
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
              borderRadius: BorderRadius.circular(8),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildActivityItem(Icons.people, 'Attendance taken', '2 hours ago',
                AppColors.success),
            _buildActivityItem(Icons.assignment, 'New task assigned',
                'Yesterday', AppColors.primaryBlue),
            _buildActivityItem(Icons.schedule, 'Schedule updated', '3 days ago',
                AppColors.accentOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      IconData icon, String title, String time, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style:
                      TextStyle(fontSize: 12.sp, color: AppColors.textMedium),
                ),
              ],
            ),
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
              '${course.schedules.length}',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  icon: const Icon(Icons.add),
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
                  icon: const Icon(Icons.event_repeat),
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
                  borderRadius: BorderRadius.circular(12),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

          // Export data
          _buildSettingCard(
            'Export Data',
            'Download attendance and progress reports',
            Icons.download,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Export functionality coming soon!')),
              );
            },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              leading: Icon(Icons.schedule, color: AppColors.primaryBlue),
              title:
                  Text('Regular Schedule', style: TextStyle(fontSize: 14.sp)),
              subtitle: Text('Weekly recurring class',
                  style: TextStyle(fontSize: 12.sp)),
              onTap: () {
                Navigator.pop(context);
                _showAddScheduleDialog(context, course.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.event_repeat, color: AppColors.accentOrange),
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
    final courseBloc = context.read<CourseBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => ScheduleDialog(
        courseId: courseId,
        onSave: (day, startTime, endTime, location) {
          final now = DateTime.now();
          final startDateTime = DateTime(
              now.year, now.month, now.day, startTime.hour, startTime.minute);
          final endDateTime = DateTime(
              now.year, now.month, now.day, endTime.hour, endTime.minute);

          final schedule = Schedule(
            id: '$courseId-schedule-new',
            courseId: courseId,
            day: day,
            startTime: startDateTime,
            endTime: endDateTime,
            location: location,
            subject: 'Subject',
            grade: 0,
          );

          courseBloc
              .add(AddScheduleEvent(courseId: courseId, schedule: schedule));
        },
      ),
    );
  }

  void _showEditScheduleDialog(
      BuildContext context, String courseId, Schedule schedule) {
    final courseBloc = context.read<CourseBloc>();
    showDialog(
      context: context,
      builder: (context) => ScheduleDialog(
        existingSchedule: schedule,
        courseId: courseId,
        onSave: (day, startTime, endTime, location) {
          final now = DateTime.now();
          final startDateTime = DateTime(
              now.year, now.month, now.day, startTime.hour, startTime.minute);
          final endDateTime = DateTime(
              now.year, now.month, now.day, endTime.hour, endTime.minute);

          final updatedSchedule = Schedule(
            id: schedule.id,
            courseId: courseId,
            day: day,
            startTime: startDateTime,
            endTime: endDateTime,
            location: location,
            subject: schedule.subject,
            grade: schedule.grade,
          );

          courseBloc.add(UpdateScheduleEvent(
            courseId: courseId,
            scheduleId: schedule.id,
            updatedSchedule: updatedSchedule,
          ));
        },
      ),
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
