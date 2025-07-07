import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
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
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
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
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
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
          title: Text('My Classes', style: TextStyle(fontSize: 18.sp)),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 6.w),
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
                PopupMenuItem<String>(
                  value: 'subject_costs',
                  child: Row(
                    children: [
                      Icon(Icons.attach_money,
                          color: AppColors.accentOrange, size: 5.w),
                      SizedBox(width: 3.w),
                      Text('Manage Subject Costs',
                          style: TextStyle(fontSize: 14.sp)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh,
                          color: AppColors.primaryBlue, size: 5.w),
                      SizedBox(width: 3.w),
                      Text('Refresh', style: TextStyle(fontSize: 14.sp)),
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
                            padding: EdgeInsets.all(4.w),
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
                                  size: 16.w,
                                  color: AppColors.error,
                                ),
                                SizedBox(height: 4.w),
                                Text(
                                  'Failed to load courses',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                                if (_uiState.errorMessage != null)
                                  Padding(
                                    padding: EdgeInsets.all(2.w),
                                    child: Text(
                                      _uiState.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.textMedium,
                                          fontSize: 14.sp),
                                    ),
                                  ),
                                SizedBox(height: 4.w),
                                ElevatedButton(
                                  onPressed: _loadCourses,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 3.w,
                                    ),
                                  ),
                                  child: Text('Try Again',
                                      style: TextStyle(fontSize: 14.sp)),
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
                          child: Text('Loading courses...',
                              style: TextStyle(fontSize: 16.sp)),
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
                      padding: EdgeInsets.all(6.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 4.w),
                          Text(
                            'Updating...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
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
      padding: EdgeInsets.all(4.w),
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
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Search courses...',
              hintStyle: TextStyle(fontSize: 14.sp),
              prefixIcon: Icon(Icons.search, size: 5.w),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 5.w),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.w),
                borderSide: BorderSide(color: AppColors.backgroundDark),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: EdgeInsets.symmetric(vertical: 3.w),
            ),
          ),
          SizedBox(height: 3.w),

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
              SizedBox(width: 3.w),
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
              padding: EdgeInsets.only(top: 2.w),
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
                  icon: Icon(Icons.filter_alt_off, size: 4.w),
                  label:
                      Text('Clear Filters', style: TextStyle(fontSize: 13.sp)),
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
        borderRadius: BorderRadius.circular(3.w),
        color: AppColors.backgroundLight,
        border: Border.all(color: AppColors.backgroundDark),
      ),
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, size: 6.w),
          hint: Text(hint, style: TextStyle(fontSize: 14.sp)),
          style: TextStyle(color: Colors.black, fontSize: 14.sp),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 4.w,
                    color: item != 'All'
                        ? _getFilterIconColor(item, icon)
                        : AppColors.primaryBlue,
                  ),
                  SizedBox(width: 2.w),
                  Text(item, style: TextStyle(fontSize: 14.sp)),
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
        SizedBox(height: 20.h),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.class_outlined,
                size: 16.w,
                color: AppColors.textLight,
              ),
              SizedBox(height: 4.w),
              Text(
                'No classes found',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.w),
              Text(
                'Tap the + button to add your first class',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14.sp,
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
                  size: 16.w,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 4.w),
                Text(
                  'No classes match your filters',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.w),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _subjectFilter = 'All';
                      _statusFilter = 'All';
                    });
                  },
                  icon: Icon(Icons.filter_alt_off, size: 5.w),
                  label:
                      Text('Clear Filters', style: TextStyle(fontSize: 14.sp)),
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
          margin: EdgeInsets.only(bottom: 3.w, top: 4.w),
          padding: EdgeInsets.symmetric(vertical: 2.w, horizontal: 4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(0.8),
                AppColors.primaryBlueDark.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(3.w),
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
              Icon(
                Icons.school,
                color: Colors.white,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Grade $grade',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Text(
                  '${courses.length} Classes',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Course cards for this grade
        ...courses.map((course) => _buildCourseCard(context, course)).toList(),
        SizedBox(height: 4.w),
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
      margin: EdgeInsets.only(bottom: 4.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
        side: BorderSide(
          color: course.isActive
              ? AppColors.backgroundDark.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4.w),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.w),
                  topRight: Radius.circular(4.w),
                ),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Subject icon circle
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(course.subject),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getSubjectIcon(course.subject),
                        color: Colors.white,
                        size: 6.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),

                  // Subject and grade info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.subject,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Grade ${course.grade}',
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status indicator
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                    decoration: BoxDecoration(
                      color: course.isActive
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          course.isActive ? Icons.check_circle : Icons.cancel,
                          size: 4.w,
                          color: course.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          course.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12.sp,
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
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next schedule info
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 4.w,
                        color: AppColors.textMedium,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Next class: $scheduleInfo',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.w),

                  // Capacity indicator
                  CapacityIndicator(course: course),
                ],
              ),
            ),

            // Divider
            Divider(color: AppColors.backgroundDark.withOpacity(0.5)),

            // Quick actions section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
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
        borderRadius: BorderRadius.circular(2.w),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 5.w,
              ),
              SizedBox(height: 1.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
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
      SnackBar(
        content: Text(
          'Enrollment management coming soon',
          style: TextStyle(fontSize: 14.sp),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, Course course) {
    // Store a reference to the CourseBloc
    final courseBloc = context.read<CourseBloc>();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(4.w),
        ),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              course.isActive ? Icons.visibility_off : Icons.visibility,
              color: course.isActive ? AppColors.error : AppColors.success,
              size: 6.w,
            ),
            title: Text(
              course.isActive ? 'Deactivate Course' : 'Activate Course',
              style: TextStyle(fontSize: 16.sp),
            ),
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
                    children: [
                      SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Updating course status...',
                        style: TextStyle(fontSize: 14.sp),
                      ),
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
