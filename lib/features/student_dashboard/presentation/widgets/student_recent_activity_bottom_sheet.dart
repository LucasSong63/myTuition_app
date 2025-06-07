// lib/features/student_dashboard/presentation/widgets/student_recent_activity_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_dashboard/domain/entities/student_dashboard_stats.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class StudentRecentActivityBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required List<StudentActivity> activities,
  }) async {
    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: const Text(
          'Recent Activity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: const EdgeInsets.all(16),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600, // Limit width on larger screens
                ),
                child: _StudentRecentActivityContent(activities: activities),
              ),
            );
          },
        ),
      );
    }

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [pageBuilder(context)],
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(),
    );
  }
}

class _StudentRecentActivityContent extends StatelessWidget {
  final List<StudentActivity> activities;

  const _StudentRecentActivityContent({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.1),
                    AppColors.primaryBlue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚡',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Recent Activities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${activities.length} activities found',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Activities list
            if (activities.isNotEmpty) ...[
              Expanded(
                child: ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildDetailedActivityItem(activity, index);
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔍',
                        style: TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Activities will appear here as they happen',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Bottom spacing
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method for detailed activity items
  Widget _buildDetailedActivityItem(StudentActivity activity, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getActivityColor(activity.type).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity icon with number
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getActivityColor(activity.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getActivityColor(activity.type).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        activity.type.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getActivityColor(activity.type),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Activity content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Activity type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getActivityColor(activity.type)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            activity.type.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getActivityColor(activity.type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Time ago
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            activity.timeAgo,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      activity.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                        height: 1.4,
                      ),
                    ),

                    // Additional data if available
                    if (activity.data != null && activity.data!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Details:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...activity.data!.entries.map((entry) {
                              // Skip internal keys that aren't user-friendly
                              if (['taskId', 'courseId'].contains(entry.key)) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ${_formatDataKey(entry.key)}: ',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],

                    // Show timestamp in a more detailed format
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDetailedTimestamp(activity.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get activity color
  Color _getActivityColor(StudentActivityType type) {
    switch (type) {
      case StudentActivityType.taskAssigned:
        return AppColors.primaryBlue;
      case StudentActivityType.taskRemarks:
        return AppColors.success;
      case StudentActivityType.scheduleChange:
        return AppColors.accentTeal;
      case StudentActivityType.scheduleReplacement:
        return AppColors.warning;
    }
  }

  // Helper method to format data keys
  String _formatDataKey(String key) {
    // Convert camelCase to readable format
    return key.split(RegExp(r'(?=[A-Z])')).map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Helper method to format detailed timestamp
  String _formatDetailedTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    final timeString =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (activityDate.isAtSameMomentAs(today)) {
      return 'Today at $timeString';
    } else if (activityDate
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday at $timeString';
    } else {
      final dateString =
          '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      return '$dateString at $timeString';
    }
  }
}
