// lib/features/attendance/presentation/widgets/attendance_header_info.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class AttendanceHeaderInfo extends StatelessWidget {
  final String courseId;
  final String courseName;
  final DateTime attendanceDate;
  final bool hasExistingRecords;
  final bool isUpdateMode;

  const AttendanceHeaderInfo({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.attendanceDate,
    this.hasExistingRecords = false,
    this.isUpdateMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.school, color: AppColors.primaryBlue, size: 28),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Course ID: $courseId',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isUpdateMode)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.orange[700]),
                      SizedBox(width: 1.w),
                      Text(
                        'Update Mode',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.today, color: AppColors.primaryBlue),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Date',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(attendanceDate),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
