import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_bloc.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_event.dart';
import 'package:mytuition/features/student_management/presentation/bloc/student_management_state.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:sizer/sizer.dart';

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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: EdgeInsets.all(4.w),
          icon: Icon(Icons.close, size: 6.w),
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
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is StudentManagementActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    hintStyle: TextStyle(fontSize: 14.sp),
                    prefixIcon: Icon(Icons.search, size: 5.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 3.w),
                  ),
                ),
                SizedBox(height: 4.w),

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
                    SizedBox(width: 3.w),
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
                SizedBox(height: 4.w),

                // Course selection text with counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Courses',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCourseIds.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 1.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          '${_selectedCourseIds.length} selected',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.w),
                const Divider(),
                SizedBox(height: 2.w),

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
                          padding: EdgeInsets.symmetric(vertical: 3.5.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 6.w,
                                height: 6.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _selectedCourseIds.isEmpty
                                    ? 'Select Courses to Enroll'
                                    : 'Enroll in ${_selectedCourseIds.length} Course${_selectedCourseIds.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
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
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.w),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, size: 5.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              borderRadius: BorderRadius.circular(2.w),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 13.sp)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 4.w),
            Text(
              'Loading available courses...',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
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
                size: 12.w,
                color: AppColors.textLight,
              ),
              SizedBox(height: 4.w),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No courses found matching "$_searchQuery"'
                    : 'No available courses match the filters',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMedium, fontSize: 14.sp),
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
                  child: Text('Clear Filters', style: TextStyle(fontSize: 14.sp)),
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
            size: 12.w,
            color: AppColors.textLight,
          ),
          SizedBox(height: 4.w),
          Text(
            'No available courses',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 4.w),
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
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.w),
            ),
            child: Text('Reload Courses', style: TextStyle(fontSize: 14.sp)),
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
        padding: EdgeInsets.symmetric(vertical: 3.w, horizontal: 2.w),
        color: isSelected ? AppColors.primaryBlueLight.withOpacity(0.1) : null,
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
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
                        size: 6.w,
                      )
                    : isFull
                        ? Icon(
                            Icons.block,
                            color: AppColors.textMedium,
                            size: 6.w,
                          )
                        : Text(
                            course['subject'].toString()[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: _getSubjectColor(course['subject']),
                            ),
                          ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['subject'] as String,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16.sp,
                      color: isFull ? AppColors.textMedium : null,
                    ),
                  ),
                  SizedBox(height: 1.w),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.5.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          'Grade ${course['grade']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      if (course['tutorName'] != null)
                        Text(
                          'Tutor: ${course['tutorName']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.w),
                  // Show capacity information
                  Text(
                    'Enrollment: $currentEnrollment/$capacity',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isFull ? AppColors.error : AppColors.textMedium,
                      fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isFull)
                    Text(
                      'Class is full',
                      style: TextStyle(
                        fontSize: 12.sp,
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
                padding: EdgeInsets.all(3.w),
                child: Icon(
                  Icons.do_not_disturb,
                  color: AppColors.textLight,
                  size: 5.w,
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
