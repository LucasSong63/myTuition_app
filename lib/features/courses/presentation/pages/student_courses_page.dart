import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../bloc/course_state.dart';

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({Key? key}) : super(key: key);

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage>
    with TickerProviderStateMixin {
  String _studentId = '';
  bool _isLoadingSchedules = false;
  List<Schedule> _allSchedules = [];
  List<Course> _courses = [];
  TabController? _tabController;

  // Group schedules by day
  Map<String, List<Schedule>> _schedulesByDay = {};

  // Sort order for days of the week
  final List<String> _dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Get today's day name
  String get _todayDayName {
    final now = DateTime.now();
    return _dayOrder[now.weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _getStudentId();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _getStudentId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _studentId = authState.user.studentId ?? '';
    }
  }

  void _loadInitialData() {
    debugPrint('🔄 Loading initial data for student: $_studentId');
    if (_studentId.isNotEmpty) {
      _loadCourses();
      _loadSchedules();
    } else {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _studentId = authState.user.studentId ?? '';
        if (_studentId.isNotEmpty) {
          _loadCourses();
          _loadSchedules();
        }
      }
    }
  }

  void _loadCourses() {
    debugPrint('📚 Loading courses for student: $_studentId');
    context.read<CourseBloc>().add(
          LoadEnrolledCoursesEvent(studentId: _studentId),
        );
  }

  void _loadSchedules() {
    debugPrint('📅 Loading schedules for student: $_studentId');
    setState(() {
      _isLoadingSchedules = true;
    });

    context.read<CourseBloc>().add(
          LoadUpcomingSchedulesEvent(studentId: _studentId),
        );
  }

  void _processSchedules(List<Schedule> schedules) {
    debugPrint('⚙️ Processing ${schedules.length} schedules');

    Map<String, List<Schedule>> grouped = {};

    // Initialize empty lists for each day
    for (var day in _dayOrder) {
      grouped[day] = [];
    }

    // Filter out expired replacement schedules and group by day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var schedule in schedules) {
      // Skip expired replacement schedules
      if (schedule.type == ScheduleType.replacement &&
          schedule.specificDate != null) {
        final scheduleDate = DateTime(
          schedule.specificDate!.year,
          schedule.specificDate!.month,
          schedule.specificDate!.day,
        );
        if (scheduleDate.isBefore(today)) {
          debugPrint(
              '⏭️ Skipping expired replacement schedule: ${schedule.id}');
          continue;
        }
      }

      if (grouped.containsKey(schedule.day)) {
        grouped[schedule.day]!.add(schedule);
      }
    }

    // Sort schedules by start time within each day
    for (var day in grouped.keys) {
      grouped[day]!.sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
    }

    setState(() {
      _schedulesByDay = grouped;
      _allSchedules = schedules.where((s) {
        if (s.type == ScheduleType.replacement && s.specificDate != null) {
          final scheduleDate = DateTime(
            s.specificDate!.year,
            s.specificDate!.month,
            s.specificDate!.day,
          );
          return !scheduleDate.isBefore(today);
        }
        return true;
      }).toList();
      _isLoadingSchedules = false;

      // Initialize tab controller with days that have schedules
      final daysWithSchedules =
          _dayOrder.where((day) => grouped[day]!.isNotEmpty).toList();

      if (daysWithSchedules.isNotEmpty) {
        // Find today's index or default to 0
        int initialIndex = daysWithSchedules.indexOf(_todayDayName);
        if (initialIndex == -1) initialIndex = 0;

        _tabController?.dispose();
        _tabController = TabController(
          length: daysWithSchedules.length,
          vsync: this,
          initialIndex: initialIndex,
        );
      }
    });

    debugPrint(
        '✅ Schedules processed - Active days: ${grouped.entries.where((e) => e.value.isNotEmpty).length}');
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              'My Courses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            actions: [
              // More Options Button
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 22.sp),
                onSelected: (value) {
                  switch (value) {
                    case 'attendance_history':
                      // Navigate to attendance history page
                      context.push('/student/attendance-history');
                      break;
                    case 'reload':
                      _loadInitialData();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'attendance_history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: AppColors.textDark,
                          size: 20.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'View Attendance History',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'reload',
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          color: AppColors.textDark,
                          size: 20.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Reload Page',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _loadInitialData();
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: MultiBlocListener(
              listeners: [
                BlocListener<CourseBloc, CourseState>(
                  listener: (context, state) {
                    if (state is CoursesLoaded) {
                      setState(() {
                        _courses = state.courses;
                      });
                      debugPrint(
                          '📚 Courses loaded and saved: ${_courses.length}');
                    } else if (state is SchedulesLoaded) {
                      _processSchedules(state.schedules);
                    } else if (state is CourseError) {
                      setState(() {
                        _isLoadingSchedules = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${state.message}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ],
              child: BlocBuilder<CourseBloc, CourseState>(
                builder: (context, state) {
                  // Check if we're still loading initial data
                  if (_courses.isEmpty && state is CourseLoading) {
                    return _buildLoadingState();
                  }

                  // If we have courses, show the content
                  if (_courses.isNotEmpty) {
                    return _buildCoursesContent(_courses);
                  }

                  // Empty state
                  if (state is CoursesLoaded && state.courses.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Error state
                  if (state is CourseError && _courses.isEmpty) {
                    return _buildErrorState(state.message);
                  }

                  // Default loading state
                  return _buildLoadingState();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 60.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Courses Yet',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'You are not enrolled in any courses.\nContact your tutor to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text(
                'Refresh',
                style: TextStyle(fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 50.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: Text(
                'Try Again',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesContent(List<Course> courses) {
    return CustomScrollView(
      slivers: [
        // Weekly Schedule Section
        SliverToBoxAdapter(
          child: _buildWeeklyScheduleSection(),
        ),

        // Quick Stats
        SliverToBoxAdapter(
          child: _buildQuickStats(courses),
        ),

        // Enrolled Courses Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(2.w, 1.h, 2.w, 1.h),
            child: Row(
              children: [
                Icon(Icons.book, color: AppColors.primaryBlue, size: 20.sp),
                SizedBox(width: 1.w),
                Text(
                  'Enrolled Courses',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${courses.length}',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Course Cards
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildEnhancedCourseCard(courses[index]),
              childCount: courses.length,
            ),
          ),
        ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: 3.h),
        ),
      ],
    );
  }

  Widget _buildWeeklyScheduleSection() {
    if (_isLoadingSchedules) {
      return Container(
        height: 32.h,
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final daysWithSchedules = _dayOrder
        .where((day) => _schedulesByDay[day]?.isNotEmpty ?? false)
        .toList();

    return Container(
      margin: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(2.w),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryBlue,
                  size: 22.sp,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_allSchedules.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue,
                          AppColors.primaryBlueLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_allSchedules.length} classes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (daysWithSchedules.isEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 40.sp,
                      color: AppColors.textLight,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No scheduled classes',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Day tabs
                if (_tabController != null)
                  Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primaryBlue,
                      unselectedLabelColor: AppColors.textMedium,
                      indicatorColor: AppColors.primaryBlue,
                      indicatorWeight: 3,
                      labelPadding: EdgeInsets.symmetric(horizontal: 2.w),
                      indicator: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 3.0,
                          ),
                        ),
                      ),
                      labelStyle: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                      tabs: daysWithSchedules.map((day) {
                        final isToday = day == _todayDayName;
                        final count = _schedulesByDay[day]?.length ?? 0;

                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isToday)
                                Container(
                                  width: 1.5.w,
                                  height: 1.5.w,
                                  margin: EdgeInsets.only(right: 0.8.w),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                day.substring(0, 3).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 15.sp,
                                ),
                              ),
                              SizedBox(width: 0.8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 1.2.w,
                                  vertical: 0.3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.accentOrange.withOpacity(0.2)
                                      : AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? AppColors.accentOrange
                                        : AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Schedule content
                if (_tabController != null)
                  SizedBox(
                    height: 22.h,
                    child: TabBarView(
                      controller: _tabController,
                      children: daysWithSchedules.map((day) {
                        return _buildDayScheduleList(
                          _schedulesByDay[day] ?? [],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleList(List<Schedule> schedules) {
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final isReplacement = schedule.type == ScheduleType.replacement;

        return Container(
          margin: EdgeInsets.only(bottom: 1.5.h),
          decoration: BoxDecoration(
            gradient: isReplacement
                ? LinearGradient(
                    colors: [
                      AppColors.accentOrange.withOpacity(0.1),
                      AppColors.accentOrange.withOpacity(0.05),
                    ],
                  )
                : null,
            color: !isReplacement
                ? _getSubjectColor(schedule.subject).withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReplacement
                  ? AppColors.accentOrange.withOpacity(0.3)
                  : _getSubjectColor(schedule.subject).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                context.push('/student/courses/${schedule.courseId}');
              },
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Row(
                  children: [
                    // Time
                    SizedBox(
                      width: 15.w,
                      child: Column(
                        children: [
                          Text(
                            _formatTime(schedule.startTime),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          Text(
                            _formatTime(schedule.endTime),
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 5.h,
                      margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                      color: AppColors.divider,
                    ),

                    // Course info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${schedule.subject} - Grade ${schedule.grade}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isReplacement) ...[
                                SizedBox(width: 1.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 1.2.w,
                                    vertical: 0.3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentOrange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'REPLACEMENT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12.sp,
                                color: AppColors.textMedium,
                              ),
                              SizedBox(width: 0.5.w),
                              Flexible(
                                child: Text(
                                  schedule.location,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textMedium,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (isReplacement &&
                              schedule.specificDate != null) ...[
                            SizedBox(height: 0.3.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 12.sp,
                                  color: AppColors.accentOrange,
                                ),
                                SizedBox(width: 0.5.w),
                                Text(
                                  DateFormat('d MMM yyyy')
                                      .format(schedule.specificDate!),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.accentOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: isReplacement
                          ? AppColors.accentOrange
                          : _getSubjectColor(schedule.subject),
                      size: 18.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(List<Course> courses) {
    final totalClasses = _allSchedules.length;
    final subjects = courses.map((c) => c.subject).toSet().length;

    return Container(
      height: 12.h,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.school,
              value: courses.length.toString(),
              label: 'Courses',
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(width: 1.5.w),
          Expanded(
            child: _buildStatCard(
              icon: Icons.subject,
              value: subjects.toString(),
              label: 'Subjects',
              color: AppColors.accentTeal,
            ),
          ),
          SizedBox(width: 1.5.w),
          Expanded(
            child: _buildStatCard(
              icon: Icons.event,
              value: totalClasses.toString(),
              label: 'Weekly Classes',
              color: AppColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24.sp),
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
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textMedium,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCourseCard(Course course) {
    final activeSchedules =
        course.schedules.where((s) => s.isActive && !s.isExpired).toList();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/student/courses/${course.id}');
          },
          child: Padding(
            padding: EdgeInsets.all(2.5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getSubjectColor(course.subject),
                            _getSubjectColor(course.subject).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSubjectIcon(course.subject),
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(width: 2.5.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.subject,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Grade ${course.grade}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.person,
                                size: 13.sp,
                                color: AppColors.textMedium,
                              ),
                              SizedBox(width: 0.5.w),
                              Flexible(
                                child: Text(
                                  course.tutorName,
                                  style: TextStyle(
                                    fontSize: 13.sp,
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
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primaryBlue,
                      size: 16.sp,
                    ),
                  ],
                ),

                // Schedules
                if (activeSchedules.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14.sp,
                              color: AppColors.textMedium,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Class Schedule',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        ...activeSchedules.map((schedule) {
                          final isReplacement =
                              schedule.type == ScheduleType.replacement;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 0.7.h),
                            child: Row(
                              children: [
                                if (isReplacement)
                                  Container(
                                    width: 0.8.w,
                                    height: 0.8.w,
                                    margin: EdgeInsets.only(right: 1.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    isReplacement
                                        ? 'Replacement: ${DateFormat('d MMM').format(schedule.specificDate!)}'
                                        : '${schedule.day} • ${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isReplacement
                                          ? AppColors.accentOrange
                                          : AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14.sp,
                                      color: AppColors.textLight,
                                    ),
                                    SizedBox(width: 0.5.w),
                                    ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: 18.w),
                                      child: Text(
                                        schedule.location,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.textLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return AppColors.mathSubject;
      case 'science':
        return AppColors.scienceSubject;
      case 'english':
        return AppColors.englishSubject;
      case 'bahasa malaysia':
        return AppColors.bahasaSubject;
      case 'chinese':
        return AppColors.chineseSubject;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.menu_book;
      case 'bahasa malaysia':
        return Icons.language;
      case 'chinese':
        return Icons.translate;
      default:
        return Icons.school;
    }
  }
}
