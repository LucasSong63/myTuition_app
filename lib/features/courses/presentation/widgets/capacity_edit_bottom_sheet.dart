import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        topBarTitle: const Text(
          'Edit Class Capacity',
          style: TextStyle(
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
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Class information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getSubjectColor(widget.course.subject),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.course.subject,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Grade ${widget.course.grade}',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
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

              const SizedBox(height: 24),

              // Current enrollment info
              Text(
                'Current Enrollment Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _buildEnrollmentStatusRow(),

              const SizedBox(height: 24),

              // Capacity input
              Text(
                'New Capacity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter new capacity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.people),
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
              const SizedBox(height: 8),
              Text(
                '* Capacity cannot be less than current enrollment',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 32),

              // Update button
              BlocBuilder<CourseBloc, CourseState>(
                builder: (context, state) {
                  final isLoading = state is CourseLoading;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateCapacity,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                          : const Text(
                              'Update Capacity',
                              style: TextStyle(
                                fontSize: 16,
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
        padding: const EdgeInsets.all(16.0),
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
                  ),
                ),
                Text(
                  '${widget.course.enrollmentCount} of ${widget.course.capacity} students',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.course.enrollmentPercentage / 100,
                minHeight: 10,
                backgroundColor: AppColors.backgroundDark,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            // Status text
            Text(
              _getCapacityStatusText(),
              style: TextStyle(
                color: statusColor,
                fontStyle: FontStyle.italic,
                fontSize: 12,
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
