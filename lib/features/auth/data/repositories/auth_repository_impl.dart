import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get_it/get_it.dart';
import 'package:mytuition/core/services/fcm_service.dart';
import 'package:mytuition/core/utils/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/firebase_auth_service.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._authService, this._firestore);

  @override
  Future<User> login({
    required String email,
    required String password,
    bool isTutor = false,
  }) async {
    try {
      // First check if email has a pending registration
      final pendingQuery = await _firestore
          .collection('registration_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingQuery.docs.isNotEmpty) {
        throw Exception('Your registration is pending approval. Please wait for the tutor to review your application.');
      }

      // Sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      // Check if email is verified for students (not for tutors)
      if (!isTutor && !userCredential.user!.emailVerified) {
        throw Exception('email_not_verified');
      }

      // Get user data from Firestore
      final userId = userCredential.user!.uid;

      // Determine the collection based on role
      final collectionPath = 'users';

      final docSnapshot =
      await _firestore.collection(collectionPath).doc(userId).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        final userRole = userData['role'] as String;
        // Verify the role matches what was requested
        if ((isTutor && userRole != 'tutor') ||
            (!isTutor && userRole != 'student')) {
          throw Exception('Invalid user role');
        }
      }

      if (!docSnapshot.exists) {
        throw Exception('User profile not found');
      }

      // Convert Firestore data to User model
      final userData = docSnapshot.data() as Map<String, dynamic>;

      // Ensure FCM token is saved after successful login
      try {
        final fcmService = GetIt.instance<FCMService>();
        await fcmService.ensureTokenForAuthenticatedUser();
      } catch (e) {
        Logger.warning('FCM token update failed during login: $e');
        // Don't fail login if FCM token update fails
      }

      return UserModel.fromMap({
        'id': userId,
        'email': email,
        ...userData,
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get current user ID before signing out
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Remove FCM token before logout
        try {
          final fcmService = GetIt.instance<FCMService>();
          await fcmService.removeTokenForUser(currentUser.uid);
        } catch (e) {
          Logger.error('Failed to remove FCM token during logout: $e');
          // Continue with logout even if FCM token removal fails
        }

        // Update user status as offline
        try {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          Logger.error('Failed to update user status during logout: $e');
        }
      }

      // Sign out from Firebase Auth
      await _authService.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    bool isTutor = false,
    int? grade,
    List<String>? subjects,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user == null) {
        throw Exception('Registration failed');
      }

      final userId = userCredential.user!.uid;

      // Determine the collection based on role
      final role = isTutor ? 'tutor' : 'student';
      final collectionPath = 'users';

      // Create user profile in Firestore
      final userData = {
        'name': name,
        'role': role,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add student-specific fields
      if (!isTutor) {
        if (grade != null) {
          userData['grade'] = grade;
        }
        if (subjects != null) {
          userData['subjects'] = subjects;
        }
      }

      await _firestore.collection(collectionPath).doc(userId).set(userData);

      // Return the newly created user
      return UserModel.fromMap({
        'id': userId,
        'email': email,
        'name': name,
        'role': role,
        'grade': grade,
        'subjects': subjects,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _authService.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      var docSnapshot =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        
        // Ensure FCM token is saved for authenticated user
        try {
          final fcmService = GetIt.instance<FCMService>();
          await fcmService.ensureTokenForAuthenticatedUser();
        } catch (e) {
          Logger.warning('FCM token update failed when getting current user: $e');
        }

        return UserModel.fromMap({
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          ...userData,
        });
      }

      return null;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  @override
  Stream<User?> get authStateChanges {
    return _authService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        // Get user data from Firestore
        var docSnapshot =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          return UserModel.fromMap({
            'id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            ...userData,
          });
        }

        return null;
      } catch (e) {
        throw _handleAuthException(e);
      }
    });
  }

  // Helper method to handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email');
        case 'wrong-password':
          return Exception('Incorrect password');
        case 'email-already-in-use':
          return Exception('This email is already in use');
        case 'invalid-email':
          return Exception('Invalid email address');
        case 'user-disabled':
          return Exception('This account has been disabled');
        case 'operation-not-allowed':
          return Exception('Operation not allowed');
        case 'weak-password':
          return Exception('Please use a stronger password');
        case 'too-many-requests':
          return Exception('Too many login attempts. Please try again later');
        default:
          return Exception('Authentication error: ${e.message}');
      }
    }
    return Exception('An unexpected error occurred: $e');
  }
}
