// lib/features/notifications/presentation/widgets/test_notification_dialog.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/core/utils/logger.dart';

class TestNotificationDialog extends StatefulWidget {
  final String defaultStudentId;

  const TestNotificationDialog({
    Key? key,
    this.defaultStudentId = '',
  }) : super(key: key);

  static Future<void> show(BuildContext context, {String defaultStudentId = ''}) {
    return showDialog(
      context: context,
      builder: (context) => TestNotificationDialog(defaultStudentId: defaultStudentId),
    );
  }

  @override
  State<TestNotificationDialog> createState() => _TestNotificationDialogState();
}

class _TestNotificationDialogState extends State<TestNotificationDialog> {
  late TextEditingController _studentIdController;
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  String _selectedType = 'test_notification';
  bool _isSending = false;

  final List<Map<String, String>> _notificationTypes = [
    {'value': 'test_notification', 'label': 'Test Notification'},
    {'value': 'payment_reminder', 'label': 'Payment Reminder'},
    {'value': 'task_reminder', 'label': 'Task Reminder'},
    {'value': 'schedule_change', 'label': 'Schedule Change'},
    {'value': 'tutor_notification', 'label': 'Tutor Message'},
  ];

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController(text: widget.defaultStudentId);
    _titleController = TextEditingController(text: 'Test Notification');
    _messageController = TextEditingController(text: 'This is a test notification from MyTuition');
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTestNotification() async {
    if (_studentIdController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final notificationManager = GetIt.instance<NotificationManager>();
      
      final success = await notificationManager.sendStudentNotification(
        studentId: _studentIdController.text.trim(),
        type: _selectedType,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'test_dialog',
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Test notification sent successfully!'
                  : 'Failed to send notification',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Test Notification'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                hintText: 'e.g., MT25-2656',
                helperText: 'Enter the student ID (not email)',
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Notification Type',
              ),
              items: _notificationTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Test Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This will send both an in-app notification and a push notification to the student\'s device.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendTestNotification,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
