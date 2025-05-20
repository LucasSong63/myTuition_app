// lib/features/auth/presentation/pages/student_dashboard_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:mytuition/core/utils/logger.dart';

class StudentDashboardPage extends StatefulWidget {
  final String
      studentId; // This should be the actual student ID (MT25-XXXX format)

  const StudentDashboardPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late StreamSubscription<AuthState> _authSubscription;
  late NotificationManager _notificationManager;
  bool _isSendingTestNotification = false;

  @override
  void initState() {
    super.initState();

    // Get notification manager
    _notificationManager = GetIt.instance<NotificationManager>();

    // Listen for auth state changes
    _authSubscription = context.read<AuthBloc>().stream.listen((state) {
      if (state is Unauthenticated && mounted) {
        // Only navigate when state becomes Unauthenticated and widget is still mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).go('/login');
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _navigateToNotifications() {
    context.push('/notifications');
  }

  // Method to send a test notification
  Future<void> _sendTestNotification() async {
    if (_isSendingTestNotification) return;

    setState(() {
      _isSendingTestNotification = true;
    });

    try {
      final success = await _notificationManager.sendStudentNotification(
        studentId: widget.studentId,
        type: 'test_notification',
        title: 'Test Notification',
        message:
            'This is a test notification sent at ${DateTime.now().toString()}',
        data: {
          'testKey': 'testValue',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Test notification sent successfully!'
                : 'Failed to send test notification'),
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
          _isSendingTestNotification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          // Notification badge - Make sure we're using the studentId for notifications
          NotificationBadge(
            userId: widget.studentId,
            // This should be the studentId, not the doc ID
            onTap: _navigateToNotifications,
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            const Text(
              'Welcome to MyTuition!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Test Notification Button (For Development Only)
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.developer_mode, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Developer Tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use these tools during development to test functionality',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSendingTestNotification
                            ? null
                            : _sendTestNotification,
                        icon: _isSendingTestNotification
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notification_add),
                        label: const Text('Send Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification card
            Card(
              child: InkWell(
                onTap: _navigateToNotifications,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueLight.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Check your latest notifications',
                              style: TextStyle(color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Placeholder text for future content
            const Text(
              'More features coming soon!',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            child: const Text('Logout'),
            onPressed: () {
              // Close dialog first
              Navigator.of(dialogContext).pop();
              // Just dispatch the logout event and let the listener handle navigation
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
    );
  }
}
