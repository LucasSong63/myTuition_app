import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
      // Sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      // Get user data from Firestore
      final userId = userCredential.user!.uid;

      // Determine the collection based on role
      final collectionPath = isTutor ? 'users/tutors' : 'users/students';

      final docSnapshot =
          await _firestore.collection(collectionPath).doc(userId).get();

      if (!docSnapshot.exists) {
        throw Exception('User profile not found');
      }

      // Convert Firestore data to User model
      final userData = docSnapshot.data() as Map<String, dynamic>;

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
      final collectionPath = isTutor ? 'users/tutors' : 'users/students';

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

      // First check if user is in tutors collection
      var docSnapshot = await _firestore
          .collection('users/tutors')
          .doc(firebaseUser.uid)
          .get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        return UserModel.fromMap({
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'role': 'tutor',
          ...userData,
        });
      }

      // If not in tutors, check students collection
      docSnapshot = await _firestore
          .collection('users/students')
          .doc(firebaseUser.uid)
          .get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        return UserModel.fromMap({
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'role': 'student',
          ...userData,
        });
      }

      return null;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _authService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        // First check if user is in tutors collection
        var docSnapshot = await _firestore
            .collection('users/tutors')
            .doc(firebaseUser.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          return UserModel.fromMap({
            'id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'role': 'tutor',
            ...userData,
          });
        }

        // If not in tutors, check students collection
        docSnapshot = await _firestore
            .collection('users/students')
            .doc(firebaseUser.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          return UserModel.fromMap({
            'id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'role': 'student',
            ...userData,
          });
        }

        return null;
      } catch (e) {
        throw _handleAuthException(e);
        return null;
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
