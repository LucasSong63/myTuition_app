// lib/core/services/auth_state_observer.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/core/services/fcm_service.dart';
import 'package:mytuition/core/utils/logger.dart';

/// Observes authentication state changes and updates Firestore accordingly
class AuthStateObserver {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authStateSubscription;
  FCMService? _fcmService;

  AuthStateObserver(this._auth, this._firestore);

  void initialize() {
    _authStateSubscription = _auth.authStateChanges().listen(_handleAuthStateChange);
    
    // Try to get FCM service if available
    try {
      if (GetIt.instance.isRegistered<FCMService>()) {
        _fcmService = GetIt.instance<FCMService>();
      }
    } catch (e) {
      Logger.info('FCM Service not yet registered: $e');
    }
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (user != null) {
      // User signed in
      await _updateUserStatus(user.uid, true);
      
      // Ensure FCM token is saved for authenticated user
      await _ensureFCMToken();
    } else {
      // User signed out
      // Note: We can't update status when signed out as we don't have access to the user ID
    }
  }

  Future<void> _updateUserStatus(String userId, bool isOnline) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        await userRef.update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
          if (isOnline) 'lastActive': FieldValue.serverTimestamp(),
        });
        
        Logger.info('User status updated: $userId - Online: $isOnline');
      } else {
        Logger.error('User document not found: $userId');
      }
    } catch (e) {
      Logger.error('Error updating user status: $e');
    }
  }

  Future<void> _ensureFCMToken() async {
    try {
      // Try to get FCM service again if not available
      _fcmService ??= GetIt.instance.isRegistered<FCMService>() 
          ? GetIt.instance<FCMService>() 
          : null;
      
      if (_fcmService != null) {
        await _fcmService!.ensureTokenForAuthenticatedUser();
        Logger.info('FCM token ensured for authenticated user');
      } else {
        Logger.warning('FCM Service not available for token initialization');
      }
    } catch (e) {
      Logger.error('Error ensuring FCM token: $e');
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
  }
}
