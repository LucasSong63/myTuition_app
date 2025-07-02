import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';

class CapacityEditBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required Course course,
  }) async {
    // Get the existing bloc from the parent context
    final CourseBloc parentBloc = context.read<CourseBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          'Edit Class Capacity',
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
                constraints: BoxConstraints(
                  maxWidth: 600, // Limit width on larger screens
                ),
                // Use BlocProvider.value to share the existing bloc
                child: BlocProvider.value(
                  value: parentBloc,
                  child: _CapacityEditContent(
                    course: course,
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

class _CapacityEditContent extends StatefulWidget {
  final Course course;

  const _CapacityEditContent({
    required this.course,
  });

  @override
  State<_CapacityEditContent> createState() => _CapacityEditContentState();
}

class _CapacityEditContentState extends State<_CapacityEditContent> {
  late TextEditingController _capacityController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _capacityController =
        TextEditingController(text: widget.course.capacity.toString());
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseActionSuccess) {
          Navigator.pop(context); // Close sheet on success
        } else if (state is CourseError) {
          // Show error but don't close sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(fontSize: 14.sp),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Class information
              Card(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 2.5.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: _getSubjectColor(widget.course.subject),
                              borderRadius: BorderRadius.circular(1.25.w),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.course.subject,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Grade ${widget.course.grade}',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 6.w),

              // Current enrollment info
              Text(
                'Current Enrollment Status',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 2.w),
              _buildEnrollmentStatusRow(),

              SizedBox(height: 6.w),

              // Capacity input
              Text(
                'New Capacity',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 2.w),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: 'Enter new capacity',
                  hintStyle: TextStyle(fontSize: 14.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  suffixIcon: Icon(Icons.people, size: 5.w),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 3.w,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a capacity value';
                  }

                  final int? capacity = int.tryParse(value);
                  if (capacity == null) {
                    return 'Please enter a valid number';
                  }

                  if (capacity < 1) {
                    return 'Capacity must be at least 1';
                  }

                  if (capacity < widget.course.enrollmentCount) {
                    return 'Capacity cannot be less than current enrollment (${widget.course.enrollmentCount})';
                  }

                  return null;
                },
              ),
              SizedBox(height: 2.w),
              Text(
                '* Capacity cannot be less than current enrollment',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),

              SizedBox(height: 8.w),

              // Update button
              BlocBuilder<CourseBloc, CourseState>(
                builder: (context, state) {
                  final isLoading = state is CourseLoading;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateCapacity,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 4.w),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
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
                              'Update Capacity',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentStatusRow() {
    // Determine color based on enrollment
    Color statusColor = AppColors.success;
    if (widget.course.isAtCapacity) {
      statusColor = AppColors.error;
    } else if (widget.course.isNearCapacity) {
      statusColor = AppColors.warning;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Enrollment:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  '${widget.course.enrollmentCount} of ${widget.course.capacity} students',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2.w),
              child: LinearProgressIndicator(
                value: widget.course.enrollmentPercentage / 100,
                minHeight: 2.5.w,
                backgroundColor: AppColors.backgroundDark,
                color: statusColor,
              ),
            ),
            SizedBox(height: 2.w),
            // Status text
            Text(
              _getCapacityStatusText(),
              style: TextStyle(
                color: statusColor,
                fontStyle: FontStyle.italic,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }

  String _getCapacityStatusText() {
    if (widget.course.isAtCapacity) {
      return 'Class is at full capacity';
    } else if (widget.course.isNearCapacity) {
      return 'Class is nearly full';
    } else if (widget.course.enrollmentCount > 0) {
      return 'Class has space available';
    } else {
      return 'No students enrolled yet';
    }
  }

  void _updateCapacity() {
    if (_formKey.currentState!.validate()) {
      final int newCapacity = int.parse(_capacityController.text);

      context.read<CourseBloc>().add(
            UpdateCourseCapacityEvent(
              courseId: widget.course.id,
              capacity: newCapacity,
            ),
          );
    }
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
}
