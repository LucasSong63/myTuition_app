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
import 'package:mytuition/features/tasks/domain/entities/student_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/features/attendance/data/models/attendance_model.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';

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

  // Store student task data for performance calculation
  Map<String, StudentTask> _studentTaskMap = {};
  List<StudentTask> _studentTasks = [];

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
      // Load student-specific task data
      _loadStudentTaskData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load student-specific task data from Firestore
  Future<void> _loadStudentTaskData() async {
    if (_currentStudentId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('student_tasks')
          .where('studentId', isEqualTo: _currentStudentId)
          .get();

      setState(() {
        _studentTaskMap = {};
        _studentTasks = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final studentTask = StudentTask(
            id: doc.id,
            taskId: data['taskId'] ?? '',
            studentId: data['studentId'] ?? '',
            remarks: data['remarks'] ?? '',
            isCompleted: data['isCompleted'] ?? false,
            completedAt: data['completedAt'] != null
                ? (data['completedAt'] as Timestamp).toDate()
                : null,
          );
          _studentTasks.add(studentTask);
          _studentTaskMap[studentTask.taskId] = studentTask;
        }
      });
    } catch (e) {
      print('Error loading student task data: $e');
    }
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

                  // Check student-specific completion status
                  for (final task in courseTasks) {
                    final studentTask = _studentTaskMap[task.id];
                    if (studentTask?.isCompleted ?? false) {
                      completedTasks++;
                    }
                  }
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
                      .where(
                          (record) => record.status == AttendanceStatus.present)
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

                  // Check student-specific completion status for overdue calculation
                  for (final task in courseTasks) {
                    if (task.dueDate != null && task.dueDate!.isBefore(now)) {
                      final studentTask = _studentTaskMap[task.id];
                      final isCompleted = studentTask?.isCompleted ?? false;
                      if (!isCompleted) {
                        overdueTasks++;
                      }
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
          SizedBox(height: 3.h),
          _buildAttendanceHistoryCard(),
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
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, courseState) {
        return BlocBuilder<TaskBloc, TaskState>(
          builder: (context, taskState) {
            final List<Widget> eventItems = [];

            // Add upcoming schedules
            if (courseState is CourseDetailsLoaded) {
              final course = courseState.course;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              // Get next class info
              for (final schedule in course.schedules) {
                if (schedule.isActive) {
                  if (schedule.isReplacement && schedule.specificDate != null) {
                    final scheduleDate = DateTime(
                      schedule.specificDate!.year,
                      schedule.specificDate!.month,
                      schedule.specificDate!.day,
                    );
                    if (scheduleDate.isAfter(today) ||
                        scheduleDate.isAtSameMomentAs(today)) {
                      String dateStr;
                      if (scheduleDate.isAtSameMomentAs(today)) {
                        dateStr =
                            'Today ${CourseDetailUtils.formatTime(schedule.startTime)}';
                      } else if (scheduleDate.difference(today).inDays == 1) {
                        dateStr =
                            'Tomorrow ${CourseDetailUtils.formatTime(schedule.startTime)}';
                      } else {
                        dateStr = DateFormat('MMM d').format(scheduleDate) +
                            ' ${CourseDetailUtils.formatTime(schedule.startTime)}';
                      }
                      eventItems.add(_buildEventItem(
                        'Makeup Class',
                        dateStr,
                        Icons.event_repeat,
                        AppColors.accentOrange,
                      ));
                    }
                  } else if (schedule.isRegular) {
                    // Find next regular class
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

                    for (int i = 0; i < 7; i++) {
                      final checkDay = (currentDayIndex + i) % 7;
                      final dayName = dayNames[checkDay];

                      if (schedule.day == dayName) {
                        String dateStr;
                        if (i == 0 &&
                            TimeOfDay.fromDateTime(now).hour <
                                schedule.startTime.hour) {
                          dateStr =
                              'Today ${CourseDetailUtils.formatTime(schedule.startTime)}';
                        } else if (i == 1 ||
                            (i == 0 &&
                                TimeOfDay.fromDateTime(now).hour >=
                                    schedule.startTime.hour)) {
                          dateStr =
                              'Tomorrow ${CourseDetailUtils.formatTime(schedule.startTime)}';
                        } else {
                          dateStr =
                              '$dayName ${CourseDetailUtils.formatTime(schedule.startTime)}';
                        }

                        if (eventItems.isEmpty) {
                          // Only add if no replacement class found
                          eventItems.add(_buildEventItem(
                            'Next Class',
                            dateStr,
                            Icons.school,
                            AppColors.primaryBlue,
                          ));
                        }
                        break;
                      }
                    }
                    if (eventItems.isNotEmpty)
                      break; // Stop after finding next class
                  }
                }
              }
            }

            // Add upcoming tasks
            if (taskState is TasksLoaded && _currentStudentId != null) {
              final upcomingTasks = taskState.tasks.where((task) {
                if (task.courseId != widget.courseId || task.dueDate == null) {
                  return false;
                }
                // Check student-specific completion status
                final studentTask = _studentTaskMap[task.id];
                final isCompleted = studentTask?.isCompleted ?? false;
                return !isCompleted && task.dueDate!.isAfter(DateTime.now());
              }).toList()
                ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

              for (int i = 0;
                  i < upcomingTasks.length && eventItems.length < 3;
                  i++) {
                final task = upcomingTasks[i];
                eventItems.add(_buildEventItem(
                  task.title,
                  DateFormat('MMM d, yyyy').format(task.dueDate!),
                  Icons.assignment,
                  AppColors.warning,
                ));
              }
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                    if (eventItems.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Center(
                          child: Text(
                            'No upcoming events',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      ...eventItems,
                  ],
                ),
              ),
            );
          },
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14.sp,
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
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
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

                        // Check student-specific completion status
                        for (final task in courseTasks) {
                          final studentTask = _studentTaskMap[task.id];
                          if (studentTask?.isCompleted ?? false) {
                            completedTasks++;
                          }
                        }
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
            fontSize: 14.sp,
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

  Widget _buildAttendanceHistoryCard() {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
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
                    Icon(Icons.history_edu,
                        color: AppColors.primaryBlue, size: 6.w),
                    SizedBox(width: 2.w),
                    Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                if (state is StudentAttendanceLoaded &&
                    _currentStudentId != null) ...[
                  // Filter attendance records for this specific student and course
                  Builder(
                    builder: (context) {
                      final studentAttendanceRecords = state.attendanceRecords
                          .where((record) =>
                              record.studentId == _currentStudentId &&
                              record.courseId == widget.courseId)
                          .toList()
                        ..sort((a, b) => b.date
                            .compareTo(a.date)); // Sort by date (newest first)

                      if (studentAttendanceRecords.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 3.h),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_busy,
                                    size: 8.w, color: AppColors.textMedium),
                                SizedBox(height: 1.h),
                                Text(
                                  'No attendance records yet',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Show latest 5 attendance records
                      final recordsToShow =
                          studentAttendanceRecords.take(5).toList();

                      return Column(
                        children: [
                          ...recordsToShow
                              .map((record) => _buildAttendanceItem(record)),
                          if (studentAttendanceRecords.length > 5) ...[
                            SizedBox(height: 2.h),
                            TextButton(
                              onPressed: () {
                                // Navigate to full attendance history page
                                context.pushNamed(
                                  RouteNames.studentAttendanceHistory,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View All (${studentAttendanceRecords.length} records)',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(width: 1.w),
                                  Icon(Icons.arrow_forward, size: 4.w),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ] else if (state is AttendanceLoading) ...[
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    child: Center(
                      child: Text(
                        'Unable to load attendance history',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceItem(Attendance record) {
    // Determine the status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (record.status) {
      case AttendanceStatus.present:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Present';
        break;
      case AttendanceStatus.absent:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      case AttendanceStatus.late:
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time_filled;
        statusText = 'Late';
        break;
      case AttendanceStatus.excused:
        statusColor = AppColors.accentTeal;
        statusIcon = Icons.info;
        statusText = 'Excused';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(record.date),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (record is AttendanceModel &&
                    record.scheduleMetadata != null) ...[
                  Text(
                    '${record.scheduleTimeDisplay} • ${record.scheduleLocation ?? 'Location'}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
                if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    record.remarks!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
