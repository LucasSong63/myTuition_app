// lib/core/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mytuition/core/utils/logger.dart';
import 'package:mytuition/core/services/notification_navigation_service.dart';
import 'package:mytuition/config/router/route_config.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _fcmTokenKey = 'fcmToken';

  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save initial token
      await _saveTokenForCurrentUser();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      Logger.info('FCM Service initialized successfully');
    } catch (e) {
      Logger.error('Error initializing FCM service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    Logger.info('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        Logger.info('Local notification tapped: ${details.payload}');
      },
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Save FCM token for current user
  Future<void> _saveTokenForCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Logger.info('No authenticated user, skipping FCM token save');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        Logger.error('Failed to get FCM token');
        return;
      }

      await _saveTokenToFirestore(user.uid, token);
      Logger.info('FCM token saved for user: ${user.uid}');
    } catch (e) {
      Logger.error('Error saving FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _saveTokenToFirestore(user.uid, token);
        Logger.info('FCM token refreshed for user: ${user.uid}');
      }
    } catch (e) {
      Logger.error('Error handling token refresh: $e');
    }
  }

  /// Save token to Firestore
  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      // First, check if we have a user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        Logger.error('User document not found for FCM token update: $userId');
        return;
      }

      // Update the user document with FCM token
      await _firestore.collection('users').doc(userId).update({
        _fcmTokenKey: token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Also update based on studentId if it exists
      final userData = userDoc.data() as Map<String, dynamic>;
      final studentId = userData['studentId'] as String?;
      
      if (studentId != null && studentId.isNotEmpty) {
        // Find and update user document with this studentId
        final studentQuery = await _firestore
            .collection('users')
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (studentQuery.docs.isNotEmpty) {
          await studentQuery.docs.first.reference.update({
            _fcmTokenKey: token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }

      Logger.info('FCM token saved to Firestore');
    } catch (e) {
      Logger.error('Error saving token to Firestore: $e');
    }
  }

  /// Remove FCM token (for logout)
  Future<void> removeTokenForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        _fcmTokenKey: FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Also delete the token to prevent receiving notifications
      await _messaging.deleteToken();
      
      Logger.info('FCM token removed for user: $userId');
    } catch (e) {
      Logger.error('Error removing FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('Foreground message received: ${message.messageId}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    Logger.info('Notification tapped: ${message.data}');
    
    // Get the current context from the navigator key
    final context = navigatorKey.currentContext;
    if (context != null) {
      NotificationNavigationService().handleNotificationNavigation(
        context,
        message.data,
      );
    } else {
      Logger.warning('No context available for notification navigation');
    }
  }

  /// Ensure token is saved for authenticated user
  /// This is called from AuthStateObserver when auth state changes
  Future<void> ensureTokenForAuthenticatedUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _saveTokenForCurrentUser();
      }
    } catch (e) {
      Logger.error('Error ensuring FCM token for authenticated user: $e');
    }
  }
}
