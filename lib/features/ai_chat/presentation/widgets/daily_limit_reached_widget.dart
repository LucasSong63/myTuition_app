import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Limit Reached! 🎯',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You\'ve used all ${usage.dailyLimit} questions for today. Great job learning!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMedium,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.refresh,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your questions reset at midnight. Come back tomorrow for more learning!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (onStartNewSession != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onStartNewSession,
                icon: const Icon(Icons.add_comment),
                label: const Text('Start Fresh Conversation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
