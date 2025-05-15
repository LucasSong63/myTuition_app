import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../bloc/course_state.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({Key? key}) : super(key: key);

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String _studentId = '';
  bool _isLoadingSchedules = false;
  List<Schedule> _allSchedules = [];

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

  @override
  void initState() {
    super.initState();
    // We'll defer actual loading to didChangeDependencies
    _getStudentId();

    // Add a post-frame callback to ensure we have access to context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // We've moved most of the initialization to the post-frame callback in initState
    // This remains as a backup in case the widget is remounted
    if (_studentId.isEmpty) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _studentId = authState.user.studentId ?? '';
        // We don't load data here to prevent duplicate loads
      }
    }
  }

  // Load both courses and schedules
  void _loadInitialData() {
    debugPrint('LOADING INITIAL DATA');
    if (_studentId.isNotEmpty) {
      _loadCourses();
      _loadSchedules();
    } else {
      // Get user ID from auth state if not already set
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _studentId = authState.user.studentId ?? '';
        if (_studentId.isNotEmpty) {
          _loadCourses();
          _loadSchedules();
        } else {
          debugPrint('WARNING: StudentId is empty, cannot load data');
        }
      } else {
        debugPrint(
            'WARNING: Auth state is not Authenticated, cannot load data');
      }
    }
  }

  void _getStudentId() {
    // Get user ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _studentId = authState.user.studentId ?? '';
    }
  }

  void _loadCourses() {
    debugPrint('Loading courses for student: $_studentId');
    context.read<CourseBloc>().add(
          LoadEnrolledCoursesEvent(studentId: _studentId),
        );
  }

  void _loadSchedules() {
    debugPrint('Loading schedules for student: $_studentId');
    setState(() {
      _isLoadingSchedules = true;
    });

    context.read<CourseBloc>().add(
          LoadUpcomingSchedulesEvent(studentId: _studentId),
        );
  }

  void _processSchedules(List<Schedule> schedules) {
    debugPrint('Processing ${schedules.length} schedules');
    Map<String, List<Schedule>> grouped = {};

    // Initialize empty lists for each day
    for (var day in _dayOrder) {
      grouped[day] = [];
    }

    // Group schedules by day
    for (var schedule in schedules) {
      if (grouped.containsKey(schedule.day)) {
        grouped[schedule.day]!.add(schedule);
      }
    }

    // Sort schedules by start time within each day
    for (var day in grouped.keys) {
      grouped[day]!.sort((a, b) =>
          a.startTime.hour * 60 +
          a.startTime.minute -
          (b.startTime.hour * 60 + b.startTime.minute));
    }

    setState(() {
      _schedulesByDay = grouped;
      _allSchedules = schedules;
      _isLoadingSchedules = false;
    });

    debugPrint(
        'Schedules processed - days with classes: ${grouped.entries.where((e) => e.value.isNotEmpty).length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadInitialData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reload both courses and schedules when user pulls to refresh
          _loadInitialData();
          // Wait a short time to ensure the refresh indicator is shown
          return await Future.delayed(const Duration(milliseconds: 800));
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<CourseBloc, CourseState>(
              listenWhen: (previous, current) => current is SchedulesLoaded,
              listener: (context, state) {
                if (state is SchedulesLoaded) {
                  _processSchedules(state.schedules);
                }
              },
            ),
            BlocListener<CourseBloc, CourseState>(
              listenWhen: (previous, current) =>
                  current is CourseError && _isLoadingSchedules,
              listener: (context, state) {
                if (state is CourseError) {
                  setState(() {
                    _isLoadingSchedules = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to load schedules: ${state.message}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<CourseBloc, CourseState>(
            buildWhen: (previous, current) {
              // Add debug print to track state changes
              debugPrint('Current state: ${current.runtimeType}');

              // We want to rebuild in these specific scenarios
              return current is CourseInitial ||
                  current is CourseLoading && !(previous is CoursesLoaded) ||
                  current is CoursesLoaded ||
                  (current is CourseError && !(current is SchedulesLoaded));
            },
            builder: (context, state) {
              // Handle courses loading state
              if (state is CourseInitial ||
                  (state is CourseLoading &&
                      !(state is CoursesLoaded) &&
                      !(state is SchedulesLoaded))) {
                return _buildLoadingState();
              }

              if (state is CoursesLoaded) {
                final courses = state.courses;
                debugPrint('Course loaded: ${courses.length} courses');

                if (courses.isEmpty) {
                  // No courses - show empty state
                  return _buildEmptyState();
                }

                // Display courses with schedule at the top
                return _buildCoursesWithSchedule(courses);
              }

              if (state is CourseError && !(state is SchedulesLoaded)) {
                // Error loading courses
                return _buildErrorState(state.message);
              }

              // Default state - show loading
              return _buildLoadingState();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      children: [
        // Placeholder for weekly schedule
        Card(
          margin: const EdgeInsets.all(16),
          child: Container(
            height: 200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
        ),

        // Placeholder for Enrolled Courses section header
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Placeholder cards for courses
        for (int i = 0; i < 3; i++)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 100,
              alignment: Alignment.center,
              child: const LinearProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildCoursesWithSchedule(List<Course> courses) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Weekly schedule view at the top
        _buildWeeklyScheduleView(),

        // Section header for courses
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(Icons.book, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Enrolled Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Course cards
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildCourseCard(context, course);
          },
        ),

        // Add some padding at the bottom
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWeeklyScheduleView() {
    if (_isLoadingSchedules) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_allSchedules.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No scheduled classes',
                      style: TextStyle(
                        fontSize: 16,
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

    // Build the improved weekly schedule view
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_allSchedules.length} ${_allSchedules.length == 1 ? 'class' : 'classes'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDayTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTabs() {
    // Only show days that have schedules
    List<String> daysWithSchedules = _schedulesByDay.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();

    // Sort days according to the correct order
    daysWithSchedules
        .sort((a, b) => _dayOrder.indexOf(a) - _dayOrder.indexOf(b));

    if (daysWithSchedules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No classes scheduled this week'),
      );
    }

    return DefaultTabController(
      length: daysWithSchedules.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day tabs
          TabBar(
            isScrollable: true,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textMedium,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: AppColors.primaryBlueLight.withOpacity(0.2),
            ),
            dividerColor: Colors.transparent,
            tabs: daysWithSchedules.map((day) {
              int count = _schedulesByDay[day]?.length ?? 0;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Tab views - schedule for each day
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            child: TabBarView(
              children: daysWithSchedules.map((day) {
                return _buildDaySchedules(_schedulesByDay[day] ?? []);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedules(List<Schedule> schedules) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No classes scheduled for this day',
            style: TextStyle(
              color: AppColors.textMedium,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: schedules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return InkWell(
      onTap: () {
        // Navigate to course details
        context.push('/student/courses/${schedule.courseId}');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getSubjectColor(schedule.subject).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getSubjectColor(schedule.subject).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSubjectColor(schedule.subject),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getSubjectIcon(schedule.subject),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.location,
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _getSubjectColor(schedule.subject),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'You are not enrolled in any courses yet',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your tutor to get enrolled',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_studentId.isNotEmpty) {
                _loadCourses();
                _loadSchedules();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_studentId.isNotEmpty) {
                _loadCourses();
                _loadSchedules();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/student/courses/${course.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Subject Icon/Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(course.subject).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        _getSubjectIcon(course.subject),
                        color: _getSubjectColor(course.subject),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grade ${course.grade}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ],
              ),
              if (course.schedules.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),
                const Text(
                  'Schedules:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: course.schedules.map((schedule) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getSubjectColor(course.subject).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              _getSubjectColor(course.subject).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: 12,
                            color: _getSubjectColor(course.subject),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getSubjectColor(course.subject),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
