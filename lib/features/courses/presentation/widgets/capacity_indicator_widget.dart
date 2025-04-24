import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: capacityColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${course.enrollmentCount}/${course.capacity}',
          style: TextStyle(
            fontSize: 12,
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
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            Text(
              '${course.enrollmentCount}/${course.capacity} students',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: capacityColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: enrollmentPercentage / 100,
            minHeight: 6,
            backgroundColor: AppColors.backgroundDark,
            color: capacityColor,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 2),
          Text(
            _getCapacityStatusText(course),
            style: TextStyle(
              fontSize: 12,
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
