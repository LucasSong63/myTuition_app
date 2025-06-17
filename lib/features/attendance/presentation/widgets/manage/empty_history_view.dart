// lib/features/attendance/presentation/widgets/manage/empty_history_view.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmptyHistoryView extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const EmptyHistoryView({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 4.w),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.w),
          Text(
            startDate != null && endDate != null
                ? 'No records in the selected date range'
                : 'No attendance records found for this course',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
