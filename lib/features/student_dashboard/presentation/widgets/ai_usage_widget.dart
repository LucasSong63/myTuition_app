// lib/features/student_dashboard/presentation/widgets/ai_usage_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/ai_chat/domain/entities/ai_usage.dart';

class AIUsageWidget extends StatelessWidget {
  final AIUsage aiUsage;

  const AIUsageWidget({
    Key? key,
    required this.aiUsage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usagePercentage = (aiUsage.dailyCount / aiUsage.dailyLimit) * 100;
    final remainingQuestions = aiUsage.dailyLimit - aiUsage.dailyCount;
    final isNearLimit = usagePercentage >= 80;
    final hasReachedLimit = aiUsage.hasReachedDailyLimit;

    Color _getUsageColor() {
      if (hasReachedLimit) return AppColors.error;
      if (isNearLimit) return AppColors.warning;
      return AppColors.success;
    }

    String _getUsageMessage() {
      if (hasReachedLimit) {
        return 'Daily limit reached. You can ask more questions tomorrow!';
      } else if (isNearLimit) {
        return 'You\'re almost at your daily limit. Use your remaining questions wisely!';
      } else if (remainingQuestions <= 5) {
        return 'You have $remainingQuestions questions left today.';
      } else {
        return 'You have $remainingQuestions questions remaining today.';
      }
    }

    String _getUsageEmoji() {
      if (hasReachedLimit) return '🚫';
      if (isNearLimit) return '⚠️';
      return '🤖';
    }

    return Card(
      elevation: 0.5.w,
      shadowColor: _getUsageColor().withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: InkWell(
        onTap: hasReachedLimit ? null : () => context.push('/student/ai-chat'),
        borderRadius: BorderRadius.circular(4.w),
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.w),
            gradient: LinearGradient(
              colors: [
                _getUsageColor().withOpacity(0.1),
                _getUsageColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: _getUsageColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                        child: Text(
                          _getUsageEmoji(),
                          style: TextStyle(fontSize: 6.w),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'AI Tutor Questions',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (!hasReachedLimit)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: _getUsageColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1.5.w),
                      ),
                      child: Text(
                        'Ask AI',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _getUsageColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 3.h),

              // Usage stats
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Usage numbers
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              aiUsage.dailyCount.toString(),
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: _getUsageColor(),
                              ),
                            ),
                            Text(
                              ' / ${aiUsage.dailyLimit}',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Questions Used Today',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Progress bar
                        Container(
                          height: 2.h,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(1.h),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                height: 2.h,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(1.h),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor:
                                    (usagePercentage / 100).clamp(0.0, 1.0),
                                child: Container(
                                  height: 2.h,
                                  decoration: BoxDecoration(
                                    color: _getUsageColor(),
                                    borderRadius: BorderRadius.circular(1.h),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '${usagePercentage.toStringAsFixed(0)}% Used',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Usage message
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: _getUsageColor().withOpacity(0.2),
                    width: 0.3.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getUsageMessage(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    if (!hasReachedLimit) ...[
                      SizedBox(height: 1.h),
                      Text(
                        'Tap to start asking questions!',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _getUsageColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Total questions stat (if useful)
              if (aiUsage.totalQuestions > 0) ...[
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz,
                      size: 4.w,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Total questions asked: ${aiUsage.totalQuestions}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
