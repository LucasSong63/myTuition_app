// lib/features/courses/presentation/pages/student_course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import 'package:mytuition/features/courses/presentation/utils/course_detail_utils.dart';
import 'package:mytuition/features/courses/presentation/widgets/course_tasks_section.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_event.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_state.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_state.dart';

class StudentCourseDetailPage extends StatefulWidget {
  final String courseId;

  const StudentCourseDetailPage({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage>
    with SingleTickerProviderStateMixin {
  final GetIt getIt = GetIt.instance;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  String? _currentStudentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _scrollController.addListener(() {
      setState(() {
        _showTitle = _scrollController.offset > 120;
      });
    });

    // Get current student ID
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentStudentId = authState.user.studentId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<TaskBloc>()
            ..add(LoadTasksByCourseEvent(courseId: widget.courseId)),
        ),
        BlocProvider(
          create: (context) => getIt<AttendanceBloc>()
            ..add(LoadStudentAttendanceEvent(
              studentId: _currentStudentId ?? '',
              courseId: widget.courseId,
            )),
        ),
      ],
      child: BlocConsumer<CourseBloc, CourseState>(
        listener: (context, state) {
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
              (state.course.id != widget.courseId)) {
            context.read<CourseBloc>().add(
                  LoadCourseDetailsEvent(courseId: widget.courseId),
                );
            return _buildLoadingScreen();
          }

          final course = state.course;
          return _buildCourseDetailScreen(course);
        },
      ),
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
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp)),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => context.read<CourseBloc>().add(
                    LoadCourseDetailsEvent(courseId: widget.courseId),
                  ),
              child: Text('Retry', style: TextStyle(fontSize: 12.sp)),
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
            SliverAppBar(
              expandedHeight: 25.h,
              pinned: true,
              backgroundColor:
                  CourseDetailUtils.getSubjectColor(course.subject),
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showTitle ? 1.0 : 0.0,
                child: Text(
                  '${course.subject} (Grade ${course.grade})',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildCourseHeader(course),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildQuickStatsSection(course),
            ),
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
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                  tabs: const [
                    Tab(
                        text: 'Overview',
                        icon: Icon(Icons.dashboard_outlined, size: 18)),
                    Tab(
                        text: 'Schedule',
                        icon: Icon(Icons.schedule_outlined, size: 18)),
                    Tab(
                        text: 'Tasks',
                        icon: Icon(Icons.assignment_outlined, size: 18)),
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Grade ${course.grade} • ${course.tutorName}',
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
                _buildStatCard('Class Size', '${course.enrollmentCount}',
                    Icons.people_outline),
                SizedBox(width: 4.w),
                _buildStatCard(
                    'Sessions',
                    '${course.schedules.where((s) => s.isRegular && s.isActive).length}/week',
                    Icons.schedule_outlined),
                SizedBox(width: 4.w),
                _buildStatCard('Next Class',
                    _getNextClassInfo(course.schedules), Icons.event_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Course course) {
    return Container(
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
              fontSize: 10.sp,
            ),
          ),
        ],
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
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(Course course) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, taskState) {
                int totalTasks = 0;
                int completedTasks = 0;

                if (taskState is TasksLoaded && _currentStudentId != null) {
                  // Get tasks for this course
                  final courseTasks = taskState.tasks
                      .where((task) => task.courseId == widget.courseId)
                      .toList();
                  totalTasks = courseTasks.length;

                  // TODO: Implement proper student-specific task completion tracking
                  // Should check student_tasks collection with document pattern: {taskId}-{studentId}
                  // For now, using the task's isCompleted field as fallback
                  completedTasks =
                      courseTasks.where((task) => task.isCompleted).length;
                }

                final progressPercentage = totalTasks > 0
                    ? (completedTasks / totalTasks * 100).round()
                    : 0;

                return _buildQuickStatCard(
                  'Progress',
                  '$progressPercentage%',
                  Icons.trending_up,
                  AppColors.success,
                );
              },
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, attendanceState) {
                double attendanceRate = 0.0;

                if (attendanceState is StudentAttendanceLoaded &&
                    _currentStudentId != null) {
                  // Filter attendance records for this specific student and course
                  final studentAttendanceRecords = attendanceState
                      .attendanceRecords
                      .where((record) =>
                          record.studentId == _currentStudentId &&
                          record.courseId == widget.courseId)
                      .toList();

                  final totalClasses = studentAttendanceRecords.length;
                  final presentClasses = studentAttendanceRecords
                      .where((record) => record.status == 'present')
                      .length;

                  attendanceRate = totalClasses > 0
                      ? (presentClasses / totalClasses * 100)
                      : 0.0;
                }

                return _buildQuickStatCard(
                  'Attendance',
                  '${attendanceRate.round()}%',
                  Icons.check_circle_outline,
                  AppColors.primaryBlue,
                );
              },
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, taskState) {
                int overdueTasks = 0;

                if (taskState is TasksLoaded && _currentStudentId != null) {
                  final now = DateTime.now();
                  // Get course tasks that are overdue for this student
                  final courseTasks = taskState.tasks
                      .where((task) => task.courseId == widget.courseId)
                      .toList();

                  // TODO: Check student_tasks collection for completion status per student
                  // For now, using task's isCompleted field as fallback
                  for (final task in courseTasks) {
                    if (task.dueDate != null &&
                        task.dueDate!.isBefore(now) &&
                        !task.isCompleted) {
                      overdueTasks++;
                    }
                  }
                }

                return _buildQuickStatCard(
                  'Overdue',
                  '$overdueTasks',
                  Icons.assignment_late,
                  AppColors.warning,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textMedium,
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
          _buildCourseInfoCard(course),
          SizedBox(height: 3.h),
          _buildUpcomingEventsCard(),
          SizedBox(height: 3.h),
          _buildPerformanceOverviewCard(),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard(Course course) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Information',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildInfoRow('Subject', course.subject),
            SizedBox(height: 1.h),
            _buildInfoRow('Grade Level', 'Grade ${course.grade}'),
            SizedBox(height: 1.h),
            _buildInfoRow('Tutor', course.tutorName),
            SizedBox(height: 1.h),
            _buildInfoRow('Class Size', '${course.enrollmentCount} students'),
            SizedBox(height: 1.h),
            _buildInfoRow('Weekly Sessions',
                '${course.schedules.where((s) => s.isRegular && s.isActive).length} times'),
            if (!course.isActive) ...[
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.error, size: 5.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'This course is currently inactive. Please contact your tutor for more information.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 25.w,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
              fontSize: 14.sp,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventsCard() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note,
                        color: AppColors.primaryBlue, size: 6.w),
                    SizedBox(width: 2.w),
                    Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                if (taskState is TasksLoaded && _currentStudentId != null) ...[
                  // TODO: Filter by student-specific completion status from student_tasks collection
                  ...taskState.tasks
                      .where((task) =>
                          task.courseId == widget.courseId &&
                          !task.isCompleted &&
                          task.dueDate != null &&
                          task.dueDate!.isAfter(DateTime.now()))
                      .take(3)
                      .map((task) => _buildEventItem(
                          task.title,
                          DateFormat('MMM d, yyyy').format(task.dueDate!),
                          Icons.assignment,
                          AppColors.warning))
                      .toList(),
                ] else ...[
                  _buildEventItem(
                      'Next Class', 'Loading...', Icons.school, Colors.blue),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventItem(
      String title, String date, IconData icon, Color color) {
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
            child: Icon(icon, color: color, size: 4.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryBlue, size: 6.w),
                SizedBox(width: 2.w),
                Text(
                  'My Performance',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<AttendanceBloc, AttendanceState>(
                    builder: (context, attendanceState) {
                      double attendanceRate = 0.0;

                      if (attendanceState is StudentAttendanceLoaded &&
                          _currentStudentId != null) {
                        // Filter attendance records for this specific student and course
                        final studentAttendanceRecords = attendanceState
                            .attendanceRecords
                            .where((record) =>
                                record.studentId == _currentStudentId &&
                                record.courseId == widget.courseId)
                            .toList();

                        final totalClasses = studentAttendanceRecords.length;
                        final presentClasses = studentAttendanceRecords
                            .where((record) => record.status == 'present')
                            .length;

                        attendanceRate = totalClasses > 0
                            ? (presentClasses / totalClasses)
                            : 0.0;
                      }

                      return _buildPerformanceItem(
                          'Attendance Rate',
                          '${(attendanceRate * 100).round()}%',
                          attendanceRate,
                          AppColors.success);
                    },
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, taskState) {
                      int totalTasks = 0;
                      int completedTasks = 0;

                      if (taskState is TasksLoaded &&
                          _currentStudentId != null) {
                        // Get tasks for this course
                        final courseTasks = taskState.tasks
                            .where((task) => task.courseId == widget.courseId)
                            .toList();
                        totalTasks = courseTasks.length;

                        // TODO: Implement proper student-specific task completion tracking
                        // Should check student_tasks collection with document pattern: {taskId}-{studentId}
                        // For now, using the task's isCompleted field as fallback
                        completedTasks = courseTasks
                            .where((task) => task.isCompleted)
                            .length;
                      }

                      final completionRate =
                          totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

                      return _buildPerformanceItem(
                          'Task Completion',
                          '$completedTasks/$totalTasks',
                          completionRate,
                          AppColors.accentTeal);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(
      String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textMedium,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 0.8.h,
            backgroundColor: AppColors.backgroundDark,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(Course course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.schedules.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 12.w, color: AppColors.textMedium),
                      SizedBox(height: 2.h),
                      Text(
                        'No scheduled classes yet',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMedium,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            if (course.schedules.any((s) => s.isRegular)) ...[
              Text(
                'Weekly Schedule',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              ...course.schedules
                  .where((s) => s.isRegular)
                  .map((schedule) => _buildStudentScheduleCard(schedule))
                  .toList(),
              SizedBox(height: 3.h),
            ],
            if (course.schedules
                .any((s) => s.isReplacement && !s.isExpired && s.isActive)) ...[
              Text(
                'Upcoming Makeup Classes',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              ...course.schedules
                  .where((s) => s.isReplacement && !s.isExpired && s.isActive)
                  .map((schedule) => _buildStudentScheduleCard(schedule))
                  .toList(),
              SizedBox(height: 3.h),
            ],
            if (course.schedules
                .any((s) => s.isExtension && !s.isExpired && s.isActive)) ...[
              Text(
                'Extension Classes',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              ...course.schedules
                  .where((s) => s.isExtension && !s.isExpired && s.isActive)
                  .map((schedule) => _buildStudentScheduleCard(schedule))
                  .toList(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStudentScheduleCard(Schedule schedule) {
    final isReplacement = schedule.isReplacement;
    final isExtension = schedule.isExtension;
    Color primaryColor;
    if (isReplacement) {
      primaryColor = AppColors.accentOrange;
    } else if (isExtension) {
      primaryColor = AppColors.accentTeal;
    } else {
      primaryColor = CourseDetailUtils.getSubjectColor(schedule.subject);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: (isReplacement || isExtension)
            ? BorderSide(color: primaryColor.withOpacity(0.3))
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
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isReplacement) ...[
                        Icon(Icons.event_repeat,
                            size: 4.w, color: AppColors.accentOrange),
                        SizedBox(width: 1.w),
                      ] else if (isExtension) ...[
                        Icon(Icons.add_circle_outline,
                            size: 4.w, color: AppColors.accentTeal),
                        SizedBox(width: 1.w),
                      ],
                      Text(
                        schedule.displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Enrolled',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if ((isReplacement || isExtension) &&
                schedule.specificDate != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 4.w, color: AppColors.textMedium),
                  SizedBox(width: 2.w),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy')
                        .format(schedule.specificDate!),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
            ],
            Row(
              children: [
                Icon(Icons.access_time, size: 4.w, color: AppColors.textMedium),
                SizedBox(width: 2.w),
                Text(
                  '${CourseDetailUtils.formatTime(schedule.startTime)} - ${CourseDetailUtils.formatTime(schedule.endTime)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.location_on, size: 4.w, color: AppColors.textMedium),
                SizedBox(width: 2.w),
                Text(
                  schedule.location,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            if (schedule.reason != null && schedule.reason!.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 4.w, color: AppColors.textMedium),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      schedule.reason!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab(Course course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          CourseTasksSection(
            courseId: course.id,
            isTutor: false,
          ),
        ],
      ),
    );
  }

  String _getNextClassInfo(List<Schedule> schedules) {
    if (schedules.isEmpty) return 'None';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final schedule in schedules) {
      if (schedule.isReplacement &&
          schedule.specificDate != null &&
          !schedule.isExpired) {
        final scheduleDate = DateTime(
          schedule.specificDate!.year,
          schedule.specificDate!.month,
          schedule.specificDate!.day,
        );
        if (scheduleDate.isAfter(today) ||
            scheduleDate.isAtSameMomentAs(today)) {
          if (scheduleDate.isAtSameMomentAs(today)) {
            return 'Today';
          } else if (scheduleDate.difference(today).inDays == 1) {
            return 'Tomorrow';
          } else {
            return DateFormat('MMM d').format(scheduleDate);
          }
        }
      }
    }

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final currentDayIndex = now.weekday - 1;

    for (int i = 0; i < 14; i++) {
      final checkDay = (currentDayIndex + i) % 7;
      final dayName = dayNames[checkDay];

      final hasClass = schedules.any((s) => s.isRegular && s.day == dayName);
      if (hasClass && i > 0) {
        if (i == 1) return 'Tomorrow';
        if (i < 7) return dayName;
        return 'Next $dayName';
      }
    }

    return 'TBD';
  }
}

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
    return false;
  }
}
