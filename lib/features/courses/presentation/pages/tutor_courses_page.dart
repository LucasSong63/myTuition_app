import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/courses/presentation/widgets/capacity_indicator_widget.dart';
import '../../domain/entities/course.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../bloc/course_state.dart';

class TutorCoursesUiState {
  final bool isUpdatingCourse;
  final String? updatingCourseId;
  final String? errorMessage;
  final bool isRefreshing;

  TutorCoursesUiState({
    this.isUpdatingCourse = false,
    this.updatingCourseId,
    this.errorMessage,
    this.isRefreshing = false,
  });

  TutorCoursesUiState copyWith({
    bool? isUpdatingCourse,
    String? updatingCourseId,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return TutorCoursesUiState(
      isUpdatingCourse: isUpdatingCourse ?? this.isUpdatingCourse,
      updatingCourseId: updatingCourseId ?? this.updatingCourseId,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class TutorCoursesPage extends StatefulWidget {
  const TutorCoursesPage({Key? key}) : super(key: key);

  @override
  State<TutorCoursesPage> createState() => _TutorCoursesPageState();
}

class _TutorCoursesPageState extends State<TutorCoursesPage> {
  // Filter state
  String _searchQuery = '';
  String _subjectFilter = 'All';
  String _statusFilter = 'All';
  final _searchController = TextEditingController();

  TutorCoursesUiState _uiState = TutorCoursesUiState();

  final List<String> _subjects = [
    'All',
    'Mathematics',
    'Science',
    'English',
    'Bahasa Malaysia',
    'Chinese'
  ];

  final List<String> _statusOptions = ['All', 'Active', 'Inactive'];

  // Track loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Schedule the loading after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateUiState({
    bool? isUpdatingCourse,
    String? updatingCourseId,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    setState(() {
      _uiState = _uiState.copyWith(
        isUpdatingCourse: isUpdatingCourse,
        updatingCourseId: updatingCourseId,
        errorMessage: errorMessage,
        isRefreshing: isRefreshing,
      );
    });
  }

  void _loadCourses() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      String tutorId = authState.user.docId;
      if (tutorId.isNotEmpty) {
        // Only set refreshing state if we're not already updating a course
        if (!_uiState.isUpdatingCourse) {
          _updateUiState(isRefreshing: true);
        }

        // Trigger the load
        context.read<CourseBloc>().add(
              LoadTutorCoursesEvent(tutorId: tutorId),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        // Handle loading state from data refresh (not course status updates)
        if (state is CourseLoading && _uiState.updatingCourseId == null) {
          // Only update UI for data loading, not action updates
          _updateUiState(isRefreshing: true);
        }

        // Handle success from course status updates
        else if (state is CourseActionSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );

          // Clear updating state but don't touch the courses data
          _updateUiState(
            isUpdatingCourse: false,
            updatingCourseId: null,
          );

          // Schedule a refresh after a delay to ensure Firebase has updated
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadCourses();
            }
          });
        }

        // Handle error state
        else if (state is CourseError) {
          // Show error and clear updating state
          _updateUiState(
            isUpdatingCourse: false,
            updatingCourseId: null,
            errorMessage: state.message,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Handle courses loaded state
        else if (state is CoursesLoaded) {
          // Clear loading state when courses are loaded
          _updateUiState(
            isRefreshing: false,
            errorMessage: null,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Classes'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _loadCourses();
                    break;
                  case 'subject_costs':
                    context.pushNamed(RouteNames.tutorSubjectCosts);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'subject_costs',
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: AppColors.accentOrange),
                      SizedBox(width: 12),
                      Text('Manage Subject Costs'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: AppColors.primaryBlue),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                // Reload the courses when the user pulls down
                _loadCourses();
                // Wait a short time to ensure the refresh indicator is shown
                return await Future.delayed(const Duration(milliseconds: 800));
              },
              child: BlocBuilder<CourseBloc, CourseState>(
                builder: (context, state) {
                  // Loading state from BLoC
                  if (state is CourseLoading && !_uiState.isUpdatingCourse) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Loaded state
                  if (state is CoursesLoaded) {
                    final courses = state.courses;

                    if (courses.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Apply filters to the courses
                    final filteredCourses = _filterCourses(courses);

                    // Check if filtered list is empty
                    if (filteredCourses.isEmpty) {
                      return _buildNoResultsState();
                    }

                    // Group courses by grade
                    final Map<int, List<Course>> coursesByGrade = {};
                    for (var course in filteredCourses) {
                      if (!coursesByGrade.containsKey(course.grade)) {
                        coursesByGrade[course.grade] = [];
                      }
                      coursesByGrade[course.grade]!.add(course);
                    }

                    // Sort grades
                    final sortedGrades = coursesByGrade.keys.toList()..sort();

                    return Column(
                      children: [
                        // Search and filter section
                        _buildSearchAndFilterSection(),

                        // Courses list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedGrades.length,
                            itemBuilder: (context, index) {
                              final grade = sortedGrades[index];
                              final gradeCourses = coursesByGrade[grade]!;

                              return _buildGradeSection(
                                  context, grade, gradeCourses);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  // Error or other states - The RefreshIndicator will still work here
                  if (state is CourseError && !_uiState.isUpdatingCourse) {
                    return Column(
                      children: [
                        // Always show search/filter even in error state
                        _buildSearchAndFilterSection(),

                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load courses',
                                  style: TextStyle(fontSize: 18),
                                ),
                                if (_uiState.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _uiState.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.textMedium),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadCourses,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Default state - show search with loading indicator
                  return Column(
                    children: [
                      // Always show search/filter
                      _buildSearchAndFilterSection(),

                      // Show a centered loading or message
                      Expanded(
                        child: Center(
                          child: const Text('Loading courses...'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Overlay loading indicator when we're updating a course status
            if (_uiState.isUpdatingCourse)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text(
                            'Updating...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Filter courses based on search query and filters
  List<Course> _filterCourses(List<Course> courses) {
    return courses.where((course) {
      // Apply subject filter
      if (_subjectFilter != 'All' &&
          !course.subject
              .toLowerCase()
              .contains(_subjectFilter.toLowerCase())) {
        return false;
      }

      // Apply status filter
      if (_statusFilter == 'Active' && !course.isActive) {
        return false;
      } else if (_statusFilter == 'Inactive' && course.isActive) {
        return false;
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        return course.subject.toLowerCase().contains(_searchQuery) ||
            'grade ${course.grade}'.contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search courses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.backgroundDark),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filter row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  icon: Icons.subject,
                  hint: 'Subject',
                  value: _subjectFilter,
                  items: _subjects,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _subjectFilter = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  icon: Icons.toggle_on,
                  hint: 'Status',
                  value: _statusFilter,
                  items: _statusOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          // Clear filters button (only shown when filters are active)
          if (_searchQuery.isNotEmpty ||
              _subjectFilter != 'All' ||
              _statusFilter != 'All')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _subjectFilter = 'All';
                      _statusFilter = 'All';
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String hint,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundLight,
        border: Border.all(color: AppColors.backgroundDark),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: Text(hint),
          style: const TextStyle(color: Colors.black, fontSize: 14),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: item != 'All'
                        ? _getFilterIconColor(item, icon)
                        : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(item),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color _getFilterIconColor(String item, IconData icon) {
    // For subject filter
    if (icon == Icons.subject) {
      return _getSubjectColor(item);
    }
    // For status filter
    else if (icon == Icons.toggle_on) {
      return item == 'Active' ? AppColors.success : AppColors.error;
    }
    return AppColors.primaryBlue;
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        _buildSearchAndFilterSection(),
        SizedBox(height: MediaQuery.of(context).size.height / 4),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.class_outlined,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'No classes found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first class',
                style: TextStyle(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Column(
      children: [
        _buildSearchAndFilterSection(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No classes match your filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _subjectFilter = 'All';
                      _statusFilter = 'All';
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeSection(
      BuildContext context, int grade, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Improved grade section header
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(0.8),
                AppColors.primaryBlueDark.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.school,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Grade $grade',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${courses.length} Classes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Course cards for this grade
        ...courses.map((course) => _buildCourseCard(context, course)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    // Get next schedule info for the course (if available)
    String scheduleInfo = 'No scheduled classes';
    if (course.schedules.isNotEmpty) {
      final nextSchedule = course.schedules.first; // For demonstration
      scheduleInfo =
          '${nextSchedule.day}, ${_formatTime(nextSchedule.startTime)} - ${_formatTime(nextSchedule.endTime)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: course.isActive
              ? AppColors.backgroundDark.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.pushNamed(
            RouteNames.tutorCourseDetails,
            pathParameters: {'courseId': course.id},
          );
        },
        child: Column(
          children: [
            // Top section with subject info and status
            Container(
              decoration: BoxDecoration(
                color: _getSubjectColor(course.subject).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Subject icon circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(course.subject),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getSubjectIcon(course.subject),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Subject and grade info
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
                        Text(
                          'Grade ${course.grade}',
                          style: TextStyle(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: course.isActive
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          course.isActive ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: course.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: course.isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Middle section with capacity info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next schedule info
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next class: $scheduleInfo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Capacity indicator
                  CapacityIndicator(course: course),
                ],
              ),
            ),

            // Divider
            Divider(color: AppColors.backgroundDark.withOpacity(0.5)),

            // Quick actions section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.people,
                    label: 'Attendance',
                    onTap: () => _navigateToAttendance(context, course),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.assignment,
                    label: 'Tasks',
                    onTap: () => _navigateToTasks(context, course),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.person_add,
                    label: 'Enrollment',
                    onTap: () => _navigateToEnrollment(context, course),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onTap: () => _showMoreOptions(context, course),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAttendance(BuildContext context, Course course) {
    context.push(
      '/tutor/courses/${course.id}/attendance',
      extra: course.subject,
    );
  }

  void _navigateToTasks(BuildContext context, Course course) {
    context.push(
      '/tutor/courses/${course.id}/tasks',
      extra: course.subject,
    );
  }

  void _navigateToEnrollment(BuildContext context, Course course) {
    // This would navigate to a student enrollment page for this course
    // This is a placeholder for future implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enrollment management coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, Course course) {
    // Store a reference to the CourseBloc
    final courseBloc = context.read<CourseBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              course.isActive ? Icons.visibility_off : Icons.visibility,
              color: course.isActive ? AppColors.error : AppColors.success,
            ),
            title:
                Text(course.isActive ? 'Deactivate Course' : 'Activate Course'),
            onTap: () {
              // Close the bottom sheet first
              Navigator.of(context).pop();

              // Set UI state to updating for this specific course
              _updateUiState(
                isUpdatingCourse: true,
                updatingCourseId: course.id,
              );

              // Show a snackbar to indicate loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Updating course status...'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Update course status - don't use a delay here,
              // we're already handling the state properly
              courseBloc.add(
                UpdateCourseActiveStatusEvent(
                  courseId: course.id,
                  isActive: !course.isActive,
                ),
              );
            },
          ),
          // ... rest of your list tiles remain the same
        ],
      ),
    );
  }

  // This function would be implemented to show the capacity edit dialog
  void _showCapacityEditDialog(BuildContext context, Course course) {
    // Navigate to the course detail page or use a dedicated bottom sheet
    context.pushNamed(
      RouteNames.tutorCourseDetails,
      pathParameters: {'courseId': course.id},
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
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
