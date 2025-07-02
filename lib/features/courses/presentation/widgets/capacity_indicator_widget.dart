import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';

class CapacityIndicator extends StatelessWidget {
  final Course course;
  final bool compact;

  const CapacityIndicator({
    Key? key,
    required this.course,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enrollmentPercentage = course.enrollmentPercentage;
    final isNearCapacity = course.isNearCapacity;
    final isAtCapacity = course.isAtCapacity;

    // Determine color based on capacity
    Color capacityColor = AppColors.success;
    if (isAtCapacity) {
      capacityColor = AppColors.error;
    } else if (isNearCapacity) {
      capacityColor = AppColors.warning;
    }

    if (compact) {
      // Compact version (just a badge)
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
        decoration: BoxDecoration(
          color: capacityColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2.5.w),
        ),
        child: Text(
          '${course.enrollmentCount}/${course.capacity}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: capacityColor,
          ),
        ),
      );
    }

    // Full version with progress bar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enrollment:',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
            ),
            Text(
              '${course.enrollmentCount}/${course.capacity} students',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: capacityColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.w),
        ClipRRect(
          borderRadius: BorderRadius.circular(1.w),
          child: LinearProgressIndicator(
            value: enrollmentPercentage / 100,
            minHeight: 1.5.w,
            backgroundColor: AppColors.backgroundDark,
            color: capacityColor,
          ),
        ),
        if (!compact) ...[
          SizedBox(height: 0.5.w),
          Text(
            _getCapacityStatusText(course),
            style: TextStyle(
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
              color: capacityColor,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ],
    );
  }

  String _getCapacityStatusText(Course course) {
    if (course.isAtCapacity) {
      return 'Class is at full capacity';
    } else if (course.isNearCapacity) {
      return 'Class is nearly full';
    } else if (course.enrollmentCount > 0) {
      return 'Class has space available';
    } else {
      return 'No students enrolled yet';
    }
  }
}
