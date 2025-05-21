// lib/features/auth/presentation/pages/student_dashboard_page.dart

import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:mytuition/core/utils/logger.dart';
import 'package:http/http.dart' as http;

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
  bool _isListeningToMessages = false;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

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
    _foregroundMessageSubscription?.cancel();
    super.dispose();
  }

  void _navigateToNotifications() {
    context.push('/notifications');
  }

  // Method to send a test in-app notification
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

  // Method to send a push notification via callable function
  Future<void> sendTestPushNotification(String studentId,
      {String? title, String? message}) async {
    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the ID token explicitly
      final idToken = await user.getIdToken(true); // Force refresh
      print('Successfully obtained ID token for user: ${user.uid}');

      // Specify asia-southeast1 region where your function is deployed
      FirebaseFunctions functions = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      );

      // Make function callable
      final HttpsCallable callable = functions.httpsCallable(
        'testPushNotification',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      print('Calling testPushNotification with studentId: $studentId');

      // Call the function
      final result = await callable.call({
        'studentId': studentId,
        'title': title ?? 'Test Notification',
        'message': message ?? 'This is a test notification from MyTuition',
      });

      print('Push notification result: ${result.data}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Push notification sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      return result.data;
    } catch (e) {
      print('Error sending test notification: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to send a push notification via HTTP endpoint
  Future<void> testNotificationHttp(String studentId) async {
    try {
      final url =
          'https://asia-southeast1-mytuition-fyp.cloudfunctions.net/testPushNotificationHttp?studentId=$studentId';

      print('Calling HTTP function with URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('HTTP Function response: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Push notification sent via HTTP successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
            'Failed to call function: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error calling HTTP function: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to check notification permissions
  Future<void> checkNotificationPermissions() async {
    try {
      // Request permission for notifications
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions granted'),
            backgroundColor: Colors.green,
          ),
        );

        // Print the current FCM token for debugging
        final token = await FirebaseMessaging.instance.getToken();
        print('Current FCM token: $token');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  // Method to debug FCM token
  Future<void> debugFcmToken() async {
    try {
      // Get current FCM token
      final token = await FirebaseMessaging.instance.getToken();
      print('Current device FCM token: $token');

      if (token == null) {
        print('FCM token is null!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: FCM token is null'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Compare with Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('studentId', isEqualTo: widget.studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No user found with studentId: ${widget.studentId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user found with studentId: ${widget.studentId}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userData = snapshot.docs.first.data();
      final List<dynamic> storedTokens =
          userData['fcmTokens'] as List<dynamic>? ?? [];

      print('Tokens in Firestore: $storedTokens');

      bool tokenExists = storedTokens.contains(token);

      if (tokenExists) {
        print('Current token is in Firestore');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Current FCM token is properly registered in Firestore'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Current token NOT in Firestore!');

        // Update the token
        await FirebaseFirestore.instance
            .collection('users')
            .doc(snapshot.docs.first.id)
            .update({
          'fcmTokens': FieldValue.arrayUnion([token])
        });

        print('Token added to Firestore');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added FCM token to Firestore'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Copy token to clipboard for testing in Firebase Console
      await Clipboard.setData(ClipboardData(text: token));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'FCM Token copied to clipboard: ${token.substring(0, 10)}...'),
          backgroundColor: Colors.purple,
        ),
      );
    } catch (e) {
      print('Error debugging FCM token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to start listening for FCM messages
  void listenForFcmMessages() {
    if (_isListeningToMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already listening for FCM messages'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    _isListeningToMessages = true;

    // Listen for FCM messages when the app is in the foreground
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification:');
        print('Title: ${message.notification!.title}');
        print('Body: ${message.notification!.body}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '📱 FCM message received: ${message.notification!.title}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Started listening for FCM messages'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _testNotificationWithManager() async {
    if (_isSendingTestNotification) return;

    setState(() {
      _isSendingTestNotification = true;
    });

    try {
      // Get notification manager
      final notificationManager = GetIt.instance<NotificationManager>();

      // Use the new enhanced NotificationManager
      final success = await notificationManager.sendStudentNotification(
        studentId: widget.studentId,
        type: 'test_notification',
        title: 'Test Notification via Manager',
        message:
            'This tests the full notification stack at ${DateTime.now().toString()}',
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
      print('Error sending test notification: $e');
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
          // Notification badge
          NotificationBadge(
            userId: widget.studentId,
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
      body: SingleChildScrollView(
        child: Padding(
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

              // Display authenticated user info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Authenticated as: ${FirebaseAuth.instance.currentUser?.uid ?? "Not authenticated"}\n(${FirebaseAuth.instance.currentUser?.email ?? ""})',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Developer Tools Card
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

              // Notification Testing Section
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Push Notification Testing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notification Permission Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: checkNotificationPermissions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Check Notification Permissions'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // HTTP Notification Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              testNotificationHttp(widget.studentId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test HTTP Notification'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Callable Function Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              sendTestPushNotification(widget.studentId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Callable Function'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Debug FCM Token Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: debugFcmToken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Debug FCM Token'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Listen for Messages Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: listenForFcmMessages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Listening for FCM Messages'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Auth Status Check Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Authenticated as: ${user.uid} (${user.email})'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Not authenticated!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Check Auth Status'),
                ),
              ),
              const SizedBox(height: 24),

              // Button for testing NotificationManager
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testNotificationWithManager,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test NotificationManager'),
                ),
              ),

              // Placeholder text for future content
              const Text(
                'More features coming soon!',
                style: TextStyle(color: AppColors.textMedium),
              ),
            ],
          ),
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
