// lib/features/notifications/presentation/widgets/send_notification_bottom_sheet.dart (simplified)

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/core/utils/logger.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// A simple bottom sheet for sending notifications to students
class SendNotificationBottomSheet {
  /// Shows the notification bottom sheet and returns whether a notification was sent
  static Future<bool?> show({
    required BuildContext context,
    required List<String> studentIds,
    required List<String> studentNames,
    String defaultTitle = '',
    String defaultMessage = '',
    String notificationType = 'tutor_notification',
  }) async {
    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          'Send Notification to ${studentIds.length} ${studentIds.length == 1 ? 'Student' : 'Students'}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _NotificationContent(
            studentIds: studentIds,
            studentNames: studentNames,
            defaultTitle: defaultTitle,
            defaultMessage: defaultMessage,
            notificationType: notificationType,
          ),
        ),
      );
    }

    final result = await WoltModalSheet.show<bool>(
      context: context,
      pageListBuilder: (context) => [pageBuilder(context)],
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(false),
    );

    return result;
  }
}

class _NotificationContent extends StatefulWidget {
  final List<String> studentIds;
  final List<String> studentNames;
  final String defaultTitle;
  final String defaultMessage;
  final String notificationType;

  const _NotificationContent({
    required this.studentIds,
    required this.studentNames,
    this.defaultTitle = '',
    this.defaultMessage = '',
    required this.notificationType,
  });

  @override
  State<_NotificationContent> createState() => _NotificationContentState();
}

class _NotificationContentState extends State<_NotificationContent> {
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  bool _isSending = false;
  NotificationManager? _notificationManager;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
    _messageController = TextEditingController(text: widget.defaultMessage);

    // Get notification manager from GetIt if available
    try {
      _notificationManager = GetIt.instance<NotificationManager>();
    } catch (e) {
      Logger.error('NotificationManager not registered with GetIt: $e');
      // We'll create it on demand if needed
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotifications() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Make sure we have a notification manager
      final notificationManager =
          _notificationManager ?? GetIt.instance<NotificationManager>();

      // Send to each student
      int successCount = 0;
      for (final studentId in widget.studentIds) {
        final success = await notificationManager.sendStudentNotification(
          studentId: studentId,
          type: widget.notificationType,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          data: {},
        );

        if (success) successCount++;
      }

      if (mounted) {
        Navigator.of(context).pop(successCount > 0);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sent notifications to $successCount/${widget.studentIds.length} students'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error sending notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipients info
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recipients: ${widget.studentIds.length} students',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (widget.studentIds.length <= 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    children: widget.studentNames
                        .map((name) => Chip(
                              label: Text(name),
                              backgroundColor: Colors.grey[200],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),

        // Title input
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Notification Title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLength: 80,
        ),
        const SizedBox(height: 12),

        // Message input
        TextField(
          controller: _messageController,
          decoration: InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 5,
          maxLength: 500,
        ),
        const SizedBox(height: 16),

        // Send button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Send Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
