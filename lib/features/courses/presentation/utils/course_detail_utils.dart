// lib/features/courses/presentation/utils/course_detail_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/course.dart';

class CourseDetailUtils {
  static Widget buildHeroBanner(BuildContext context, Course course) {
    return Container(
      height: 120,
      width: double.infinity,
      color: getSubjectColor(course.subject),
      child: Stack(
        children: [
          // Subject icon in the background
          Positioned(
            right: 20,
            bottom: -10,
            child: Icon(
              getSubjectIcon(course.subject),
              size: 100,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          // Course info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  course.subject,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grade ${course.grade}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  static Color getSubjectColor(String subject) {
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

  static IconData getSubjectIcon(String subject) {
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

  static String getCapacityStatusText(Course course) {
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
