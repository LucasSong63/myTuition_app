import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../domain/entities/ai_usage.dart';
import '../../../../config/theme/app_colors.dart';

class DailyLimitReachedWidget extends StatelessWidget {
  final AIUsage usage;
  final VoidCallback? onStartNewSession;

  const DailyLimitReachedWidget({
    Key? key,
    required this.usage,
    this.onStartNewSession,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2.h),
      padding: EdgeInsets.all(2.5.h),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(2.h),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  color: AppColors.error,
                  size: 3.h,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Limit Reached! 🎯',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'You\'ve used all ${usage.dailyLimit} questions for today. Great job learning!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMedium,
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
            padding: EdgeInsets.all(1.5.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(1.h),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.refresh,
                  color: AppColors.primaryBlue,
                  size: 2.5.h,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    'Your questions reset at midnight. Come back tomorrow for more learning!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 14.sp,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
