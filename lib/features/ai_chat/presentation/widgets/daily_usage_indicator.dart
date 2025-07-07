import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../domain/entities/ai_usage.dart';
import '../../../../config/theme/app_colors.dart';

class DailyUsageIndicator extends StatelessWidget {
  final AIUsage usage;

  const DailyUsageIndicator({Key? key, required this.usage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = usage.dailyCount / usage.dailyLimit;
    final remaining = usage.dailyLimit - usage.dailyCount;

    Color indicatorColor;
    if (percentage >= 1.0) {
      indicatorColor = AppColors.error;
    } else if (percentage >= 0.8) {
      indicatorColor = AppColors.warning;
    } else {
      indicatorColor = AppColors.success;
    }

    return Container(
      margin: EdgeInsets.all(2.h),
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(1.5.h),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: indicatorColor,
            size: 2.5.h,
          ),
          SizedBox(width: 1.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Questions: ${usage.dailyCount}/${usage.dailyLimit}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                ),
                SizedBox(height: 0.5.h),
                LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                ),
              ],
            ),
          ),
          SizedBox(width: 1.5.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(1.h),
            ),
            child: Text(
              '$remaining left',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
