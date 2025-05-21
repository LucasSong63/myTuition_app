// lib/core/services/fcm_service.dart

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../features/notifications/domain/notification_manager.dart';

// Global navigator key to use for navigation from outside of context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase
  await Firebase.initializeApp();

  print('Handling a background message: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Initialize and request permissions
  Future<void> initialize() async {
    print('Initializing FCM service...');

    // Setup local notifications for foreground
    await _setupLocalNotifications();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
      print('FCM Token: $token');
    } else {
      print('Failed to get FCM token');
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

    // Handle notification taps when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    print('FCM service initialized');
  }

  // Setup local notifications for foreground display
  Future<void> _setupLocalNotifications() async {
    print('Setting up local notifications...');

    // Create the Android notification channel
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
    }

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    // Combined initialization settings with only Android
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Initialize the plugin
    await _flutterLocalNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        _handleNotificationTap(details);
      },
    );

    print('Local notifications setup complete');
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      print('Saving FCM token to Firestore: $token');

      // Get current user ID - you'll need to adapt this to your auth service
      final String? userId = await _getCurrentUserId();

      if (userId == null) {
        print('Cannot save token: No user ID available');
        return;
      }

      // Save token to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

      print('FCM token saved successfully');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Get current user ID - replace with your actual implementation
  Future<String?> _getCurrentUserId() async {
    // Get Firebase Auth UID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser
          .uid; // This will be the document ID (like "5mK8w62wQGPrBcr7OGVeYGUNtMj1")
    }

    // If not logged in, return null
    return null;
  }

  // Handle foreground message display
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Create in-app notification using flutter_local_notifications
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      print('Notification: ${notification.title} - ${notification.body}');

      // Show notification using local notifications plugin
      await _flutterLocalNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@drawable/ic_notification',
          ),
        ),
        payload: jsonEncode(message.data),
      );

      // Also create an in-app notification in your system
      try {
        final notificationManager = GetIt.instance<NotificationManager>();
        await notificationManager.createNotificationFromRemoteMessage(message);
      } catch (e) {
        print('Error creating in-app notification: $e');
      }
    }
  }

  // Handle notification tap from local notifications
  void _handleNotificationTap(NotificationResponse details) {
    print('Notification tapped: ${details.payload}');

    // Parse payload and navigate
    if (details.payload != null) {
      try {
        final data = jsonDecode(details.payload!);
        _navigateBasedOnNotification(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle message opened from terminated state
  Future<void> _handleInitialMessage(RemoteMessage? message) async {
    print('Initial message: ${message?.messageId}');

    if (message != null) {
      _navigateBasedOnNotification(message.data);
    }
  }

  // Handle message opened from background state
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    _navigateBasedOnNotification(message.data);
  }

  // Navigation logic based on notification data
  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    print('Navigating based on notification: $data');

    final type = data['type'];

    // Make sure we have a valid navigator key context
    if (navigatorKey.currentContext == null) {
      print('No valid context for navigation');
      return;
    }

    switch (type) {
      case 'payment_reminder':
      case 'payment_overdue':
      case 'payment_confirmed':
        // Navigate to payment details
        final paymentId = data['paymentId'];
        if (paymentId != null) {
          GoRouter.of(navigatorKey.currentContext!)
              .go('/payments/details/$paymentId');
        } else {
          GoRouter.of(navigatorKey.currentContext!).go('/payments');
        }
        break;

      case 'task_reminder':
      case 'task_overdue':
      case 'task_feedback':
        // Navigate to task details
        final taskId = data['taskId'];
        if (taskId != null) {
          GoRouter.of(navigatorKey.currentContext!)
              .go('/tasks/details/$taskId');
        } else {
          GoRouter.of(navigatorKey.currentContext!).go('/tasks');
        }
        break;

      case 'schedule_change':
        // Navigate to schedule view
        GoRouter.of(navigatorKey.currentContext!).go('/schedule');
        break;

      default:
        // Navigate to notification list
        GoRouter.of(navigatorKey.currentContext!).go('/notifications');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    print('Subscribing to topic: $topic');
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    print('Unsubscribing from topic: $topic');
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Subscribe to relevant topics for user
  Future<void> subscribeToRelevantTopics(
      String studentId, List<String> courses) async {
    print('Subscribing to relevant topics for student: $studentId');

    // Subscribe to student-specific topic
    await subscribeToTopic('student-$studentId');

    // Subscribe to course topics
    for (final courseId in courses) {
      await subscribeToTopic('course-$courseId');
    }

    // Subscribe to general topics
    await subscribeToTopic('all-students');

    print('Topic subscriptions complete');
  }
}

// Extension method for NotificationManager to handle remote messages
extension NotificationManagerExtension on NotificationManager {
  Future<void> createNotificationFromRemoteMessage(
      RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Get student ID from data or use a default identifier
    final studentId = data['studentId'] ?? data['userId'] ?? 'unknown';

    // Create in-app notification
    await sendStudentNotification(
      studentId: studentId,
      type: data['type'] ?? 'system_notification',
      title: notification.title ?? 'New Notification',
      message: notification.body ?? '',
      data: data,
    );
  }
}
