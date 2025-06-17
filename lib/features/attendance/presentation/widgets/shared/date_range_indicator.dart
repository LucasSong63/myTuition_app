// lib/features/attendance/presentation/widgets/shared/date_range_indicator.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class DateRangeIndicator extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeIndicator({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.only(bottom: 4.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Text(
        'Showing data for ${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 13.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
