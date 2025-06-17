// lib/features/attendance/presentation/widgets/quick_attendance_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';

class QuickAttendanceDialog extends StatefulWidget {
  const QuickAttendanceDialog({Key? key}) : super(key: key);

  @override
  State<QuickAttendanceDialog> createState() => _QuickAttendanceDialogState();

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlocProvider(
        create: (context) => GetIt.instance<CourseBloc>(),
        child: const QuickAttendanceDialog(),
      ),
    );
  }
}

class _QuickAttendanceDialogState extends State<QuickAttendanceDialog> {
  Course? selectedCourse;
  List<Course> availableCourses = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTutorCourses();
  }

  void _loadTutorCourses() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is Authenticated) {
      context.read<CourseBloc>().add(
            LoadTutorCoursesEvent(tutorId: authState.user.docId),
          );
    }
  }

  void _proceedToAttendance() {
    final course = selectedCourse ?? availableCourses.first;

    Navigator.of(context).pop();

    // FIXED: Use named route to ensure correct path construction
    context.pushNamed(
      RouteNames.takeAttendance,
      pathParameters: {'courseId': course.id},
      extra: {
        'courseName': '${course.subject} - Grade ${course.grade}',
        'isQuickAttendance': true,
        // Flag to indicate this came from quick attendance
      },
    );
  }

  bool _canProceed() {
    return availableCourses.isNotEmpty &&
        (selectedCourse != null || availableCourses.length == 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseLoading) {
          setState(() {
            isLoading = true;
            errorMessage = null;
          });
        } else if (state is CoursesLoaded) {
          setState(() {
            isLoading = false;
            availableCourses = state.courses;
            // Auto-select if only one course
            if (availableCourses.length == 1) {
              selectedCourse = availableCourses.first;
            }
          });
        } else if (state is CourseError) {
          setState(() {
            isLoading = false;
            errorMessage = state.message;
          });
          _showErrorSnackBar(state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        child: Container(
          padding: EdgeInsets.all(6.w),
          constraints: BoxConstraints(
            maxWidth: 90.w,
            maxHeight: 70.h, // Reduced height since no session selection
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 4.h),

              // Content
              if (isLoading)
                _buildLoadingContent()
              else if (errorMessage != null)
                _buildErrorContent()
              else
                _buildSelectionContent(),

              SizedBox(height: 4.h),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Icon(
            Icons.how_to_reg,
            color: AppColors.primaryBlue,
            size: 6.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Attendance',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Select course and proceed to attendance',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: AppColors.textMedium,
            size: 6.w,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading your courses...',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Error loading courses',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _loadTutorCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionContent() {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date info
            _buildDateInfo(),
            SizedBox(height: 3.h),

            // Course selection
            _buildCourseSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.accentTeal,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Today\'s Date',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.accentTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(now),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          Text(
            DateFormat('h:mm a').format(now),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelection() {
    if (availableCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            children: [
              Icon(
                Icons.school_outlined,
                color: AppColors.textMedium,
                size: 8.w,
              ),
              SizedBox(height: 2.h),
              Text(
                'No active courses found',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Please create a course first to take attendance',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Course',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 2.h),

        // Course selection based on count
        if (availableCourses.length == 1) ...[
          // Auto-selected single course
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Course Auto-Selected',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '${availableCourses.first.subject} - Grade ${availableCourses.first.grade}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (availableCourses.first.schedules.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    '${availableCourses.first.schedules.length} schedule(s) available',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          // Multiple courses - dropdown selection
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Course>(
                value: selectedCourse,
                hint: Text(
                  'Choose a course...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textMedium,
                  ),
                ),
                isExpanded: true,
                items: availableCourses.map((course) {
                  return DropdownMenuItem<Course>(
                    value: course,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${course.subject} - Grade ${course.grade}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (course.schedules.isNotEmpty)
                          Text(
                            '${course.schedules.length} schedule(s)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMedium,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (course) {
                  setState(() {
                    selectedCourse = course;
                  });
                },
              ),
            ),
          ),
        ],

        // Show selected course details if multiple courses and one is selected
        if (availableCourses.length > 1 && selectedCourse != null) ...[
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Course Details',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${selectedCourse!.subject} - Grade ${selectedCourse!.grade}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (selectedCourse!.schedules.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    '${selectedCourse!.schedules.length} schedule(s) available',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _canProceed() ? _proceedToAttendance : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _canProceed() ? AppColors.primaryBlue : Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            child: Text(
              'Take Attendance',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
