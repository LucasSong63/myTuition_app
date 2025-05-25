import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: indicatorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Questions: ${usage.dailyCount}/${usage.dailyLimit}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$remaining left',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
