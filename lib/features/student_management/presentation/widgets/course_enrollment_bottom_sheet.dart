import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_bloc.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_event.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_state.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class CourseEnrollmentBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required String studentId,
    required String studentName,
  }) async {
    // Get the existing bloc from the parent context
    final parentBloc = context.read<StudentManagementBloc>();

    // Pre-load available courses using the parent bloc
    parentBloc.add(LoadAvailableCoursesEvent(studentId: studentId));

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          'Enroll $studentName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: const EdgeInsets.all(16),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600, // Limit width on larger screens
                ),
                // Use BlocProvider.value to share the existing bloc
                child: BlocProvider.value(
                  value: parentBloc,
                  child: _CourseEnrollmentContent(
                    studentId: studentId,
                    studentName: studentName,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [pageBuilder(context)],
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(),
    );
  }
}

class _CourseEnrollmentContent extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _CourseEnrollmentContent({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_CourseEnrollmentContent> createState() =>
      _CourseEnrollmentContentState();
}

class _CourseEnrollmentContentState extends State<_CourseEnrollmentContent> {
  final Set<String> _selectedCourseIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  String _gradeFilter = 'All';
  String _subjectFilter = 'All';

  // Lists for filter options
  final List<String> _grades = ['All', '1', '2', '3', '4', '5', '6'];
  final List<String> _subjects = [
    'All',
    'Mathematics',
    'Science',
    'English',
    'Bahasa Malaysia',
    'Chinese'
  ];

  // Store the available courses to prevent data loss during state transitions
  List<Map<String, dynamic>> _availableCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentManagementBloc, StudentManagementState>(
      listenWhen: (previous, current) {
        // Only listen to state changes that are relevant to this bottom sheet
        return current is AvailableCoursesLoaded ||
            current is StudentManagementError ||
            current is StudentManagementActionSuccess;
      },
      listener: (context, state) {
        if (state is AvailableCoursesLoaded &&
            state.studentId == widget.studentId) {
          setState(() {
            _availableCourses = state.availableCourses;
            _isLoading = false;
          });
        } else if (state is StudentManagementError) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is StudentManagementActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter section
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        label: 'Grade',
                        value: _gradeFilter,
                        items: _grades,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _gradeFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        label: 'Subject',
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
                  ],
                ),
                const SizedBox(height: 16),

                // Course selection text with counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Courses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCourseIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_selectedCourseIds.length} selected',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Course list with fixed height
                Expanded(
                  child: _buildCourseList(),
                ),

                // Enroll button
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<StudentManagementBloc,
                      StudentManagementState>(
                    builder: (context, state) {
                      final isLoading = state is StudentManagementLoading;

                      return ElevatedButton(
                        onPressed: _selectedCourseIds.isEmpty || isLoading
                            ? null
                            : () {
                                _enrollSelectedCourses(context);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _selectedCourseIds.isEmpty
                                    ? 'Select Courses to Enroll'
                                    : 'Enroll in ${_selectedCourseIds.length} Course${_selectedCourseIds.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to handle enrolling in multiple courses
  void _enrollSelectedCourses(BuildContext context) {
    final bloc = context.read<StudentManagementBloc>();

    // Loop through each selected course and enroll the student
    for (final courseId in _selectedCourseIds) {
      bloc.add(
        EnrollStudentEvent(
          studentId: widget.studentId,
          courseId: courseId,
        ),
      );
    }

    // After enrollment, trigger a refresh of the enrolled courses
    bloc.add(LoadEnrolledCoursesEvent(studentId: widget.studentId));

    // Close the sheet
    Navigator.pop(context);
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMedium,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(8),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseList() {
    // Show loading indicator while initially loading
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading available courses...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // If we have data, show it regardless of current BLoC state
    if (_availableCourses.isNotEmpty) {
      // Apply filters
      final filteredCourses = _availableCourses.where((course) {
        final subject = (course['subject'] as String).toLowerCase();
        final grade = course['grade'].toString();

        // Apply search query filter
        bool matchesSearch = _searchQuery.isEmpty ||
            subject.contains(_searchQuery) ||
            grade.contains(_searchQuery);

        // Apply grade filter
        bool matchesGrade = _gradeFilter == 'All' || grade == _gradeFilter;

        // Apply subject filter
        bool matchesSubject = _subjectFilter == 'All' ||
            course['subject'].toString().toLowerCase() ==
                _subjectFilter.toLowerCase();

        return matchesSearch && matchesGrade && matchesSubject;
      }).toList();

      if (filteredCourses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No courses found matching "$_searchQuery"'
                    : 'No available courses match the filters',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMedium),
              ),
              if (_searchQuery.isNotEmpty ||
                  _gradeFilter != 'All' ||
                  _subjectFilter != 'All')
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _gradeFilter = 'All';
                      _subjectFilter = 'All';
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
        );
      }

      return ListView.separated(
        itemCount: filteredCourses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final course = filteredCourses[index];
          final courseId = course['id'] as String;
          final isSelected = _selectedCourseIds.contains(courseId);

          return _buildCourseCard(course, isSelected);
        },
      );
    }

    // If no data is available, show empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No available courses',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });

              context.read<StudentManagementBloc>().add(
                    LoadAvailableCoursesEvent(
                      studentId: widget.studentId,
                    ),
                  );
            },
            child: const Text('Reload Courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, bool isSelected) {
    final courseId = course['id'] as String;
    final capacity = course['capacity'] as int? ?? 20;
    final currentEnrollment = course['currentEnrollment'] as int? ?? 0;
    final hasCapacity =
        course['hasCapacity'] as bool? ?? (currentEnrollment < capacity);
    final isFull = currentEnrollment >= capacity;

    return InkWell(
      onTap: () {
        // Don't allow selection of full courses
        if (isFull) return;

        setState(() {
          // Toggle selection
          if (isSelected) {
            _selectedCourseIds.remove(courseId);
          } else {
            _selectedCourseIds.add(courseId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        color: isSelected ? AppColors.primaryBlueLight.withOpacity(0.1) : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isFull
                    ? AppColors.backgroundDark
                    : _getSubjectColor(course['subject']).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _getSubjectColor(course['subject']),
                      )
                    : isFull
                        ? Icon(
                            Icons.block,
                            color: AppColors.textMedium,
                          )
                        : Text(
                            course['subject'].toString()[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getSubjectColor(course['subject']),
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['subject'] as String,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                      color: isFull ? AppColors.textMedium : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Grade ${course['grade']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (course['tutorName'] != null)
                        Text(
                          'Tutor: ${course['tutorName']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Show capacity information
                  Text(
                    'Enrollment: $currentEnrollment/$capacity',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFull ? AppColors.error : AppColors.textMedium,
                      fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isFull)
                    Text(
                      'Class is full',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            // Use Checkbox instead of Radio
            if (!isFull)
              Checkbox(
                value: isSelected,
                onChanged: (_) {
                  setState(() {
                    if (isSelected) {
                      _selectedCourseIds.remove(courseId);
                    } else {
                      _selectedCourseIds.add(courseId);
                    }
                  });
                },
                activeColor: AppColors.primaryBlue,
              )
            else
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  Icons.do_not_disturb,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return AppColors.mathSubject;
    if (subject.contains('science')) return AppColors.scienceSubject;
    if (subject.contains('english')) return AppColors.englishSubject;
    if (subject.contains('bahasa')) return AppColors.bahasaSubject;
    if (subject.contains('chinese')) return AppColors.chineseSubject;
    return AppColors.primaryBlue;
  }
}
