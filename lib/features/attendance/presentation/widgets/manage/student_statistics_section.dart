// lib/features/attendance/presentation/widgets/manage/student_statistics_section.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class StudentStatisticsSection extends StatelessWidget {
  final List<Map<String, dynamic>> students;

  const StudentStatisticsSection({
    Key? key,
    required this.students,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return SizedBox.shrink();
    }

    // Calculate statistics based on the students data
    final totalStudents = students.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Statistics',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.w),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.w),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Enrolled Students:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    totalStudents.toString(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.w),
              Text(
                'This shows the total number of students enrolled in this course.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
