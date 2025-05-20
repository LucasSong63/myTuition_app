// lib/features/notifications/presentation/pages/notification_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/notification.dart' as app_notification;
import '../../../../config/theme/app_colors.dart';

class NotificationDetailPage extends StatelessWidget {
  final app_notification.Notification notification;

  const NotificationDetailPage({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and icon
            _buildHeader(),

            const Divider(height: 32),

            // Title
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              notification.message,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Timestamp
            _buildTimestamp(),

            // Data section if there's any data
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDataSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData iconData;
    Color iconColor;
    String typeText;

    // Determine icon and color based on notification type
    switch (notification.type) {
      case 'payment_reminder':
        iconData = Icons.account_balance_wallet;
        iconColor = AppColors.warning;
        typeText = 'Payment Reminder';
        break;
      case 'payment_confirmed':
        iconData = Icons.check_circle;
        iconColor = AppColors.success;
        typeText = 'Payment Confirmation';
        break;
      case 'task_created':
      case 'task_reminder':
        iconData = Icons.assignment_late;
        iconColor = AppColors.warning;
        typeText = 'Task Reminder';
        break;
      case 'task_feedback':
        iconData = Icons.rate_review;
        iconColor = AppColors.accentTeal;
        typeText = 'Task Feedback';
        break;
      case 'tutor_notification':
        iconData = Icons.campaign;
        iconColor = AppColors.accentOrange;
        typeText = 'Tutor Message';
        break;
      case 'class_announcement':
        iconData = Icons.school;
        iconColor = AppColors.primaryBlue;
        typeText = 'Class Announcement';
        break;
      case 'test_notification':
        iconData = Icons.bug_report;
        iconColor = Colors.purple;
        typeText = 'Test Notification';
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.primaryBlue;
        typeText = 'Notification';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          typeText,
          style: TextStyle(
            fontSize: 16,
            color: iconColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp() {
    final DateFormat dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');
    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(
          dateFormat.format(notification.createdAt),
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    // Skip if there's no data
    if (notification.data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Display all data entries
        ...notification.data.entries.map((entry) {
          // Format value based on type
          String valueText = '';
          if (entry.value == null) {
            valueText = 'N/A';
          } else if (entry.value is int && entry.key.contains('timestamp')) {
            // Format timestamps
            final timestamp =
                DateTime.fromMillisecondsSinceEpoch(entry.value as int);
            valueText = DateFormat('MMM d, yyyy h:mm a').format(timestamp);
          } else {
            valueText = entry.value.toString();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatKey(entry.key)}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                Expanded(
                  child: Text(
                    valueText,
                    style: const TextStyle(color: AppColors.textMedium),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Format keys for better display
  String _formatKey(String key) {
    // If camelCase or snake_case, convert to Title Case with spaces
    if (key.contains('_')) {
      // Handle snake_case
      return key
          .split('_')
          .map((word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
    } else {
      // Handle camelCase
      return key
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
          .trim()
          .capitalize();
    }
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
