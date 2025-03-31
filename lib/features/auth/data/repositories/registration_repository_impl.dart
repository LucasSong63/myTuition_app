import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/repositories/registration_repository.dart';
import '../datasources/remote/email_service.dart';
import '../models/registration_model.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final EmailService _emailService;

  // Collection reference for registration requests
  final CollectionReference _registrationsCollection;

  // Constructor
  RegistrationRepositoryImpl(
      this._firestore,
      this._firebaseAuth,
      this._emailService,
      ) : _registrationsCollection = _firestore.collection('registration_requests');

  // Generate a unique student ID
  String _generateStudentId() {
    // Get current year's last two digits
    final year = DateTime.now().year.toString().substring(2);

    // Generate a random 4-digit number
    final random = Random();
    final uniqueNumber = random.nextInt(9000) + 1000; // 1000-9999 range

    // Format: MT + year + sequence number
    return 'MT$year-$uniqueNumber';
  }

  @override
  Future<void> submitRegistration({
    required String email,
    required String password,
    required String name,
    required String phone,
    required int grade,
    required List<String> subjects,
    required bool hasConsulted,
  }) async {
    try {
      // Check if email is already in use
      final isAvailable = await isEmailAvailable(email);

      if (!isAvailable) {
        throw Exception('Email is already in use or has a pending request');
      }

      // We'll store the password more securely
      final securePassword = _encryptPassword(password);

      await _registrationsCollection.add({
        'email': email,
        'name': name,
        'phone': phone,
        'grade': grade,
        'subjects': subjects,
        'hasConsulted': hasConsulted,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'securePassword': securePassword,
      });
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Stream<List<RegistrationRequest>> getPendingRegistrations() {
    return _registrationsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RegistrationRequest.fromDocument(doc))
          .toList();
    });
  }

  @override
  Future<RegistrationRequest> getRegistrationById(String id) async {
    try {
      final docSnapshot = await _registrationsCollection.doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Registration request not found');
      }

      return RegistrationRequest.fromDocument(docSnapshot);
    } catch (e) {
      throw _handleException(e);
    }
  }

// Generate a unique student ID with collision checking
  Future<String> _generateUniqueStudentId() async {
    // Maximum number of attempts to avoid infinite loops
    final maxAttempts = 10;
    int attempts = 0;

    while (attempts < maxAttempts) {
      // Get current year's last two digits
      final year = DateTime.now().year.toString().substring(2);

      // Generate a random 4-digit number
      final random = Random();
      final uniqueNumber = random.nextInt(9000) + 1000; // 1000-9999 range

      // Format: MT + year + sequence number
      final studentId = 'MT$year-$uniqueNumber';

      // Check if this ID already exists
      final query = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      // If no document found with this ID, it's unique
      if (query.docs.isEmpty) {
        return studentId;
      }

      // Increment attempt counter
      attempts++;
    }

    // If we reach here, we've tried multiple times and still have collisions
    // Generate a more complex ID with milliseconds to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    final year = DateTime.now().year.toString().substring(2);
    return 'MT$year-$timestamp';
  }

  @override
  Future<void> approveRegistration(String id) async {
    try {
      // Get the registration request
      final request = await getRegistrationById(id);

      // Generate a unique student ID (outside the transaction)
      final studentId = await _generateUniqueStudentId();

      // Begin a transaction
      return await _firestore.runTransaction((transaction) async {
        // Get the document data including encrypted password
        final docSnapshot = await transaction.get(_registrationsCollection.doc(id));
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Decrypt the password
        final password = _decryptPassword(data['securePassword']);

        // Create user in Firebase Auth
        final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: request.email,
          password: password,
        );

        if (userCredential.user == null) {
          throw Exception('Failed to create user account');
        }

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        final userId = userCredential.user!.uid;

        // Create user profile in users collection
        final userDoc = _firestore.collection('users').doc(userId);

        transaction.set(userDoc, {
          'name': request.name,
          'email': request.email,
          'phone': request.phone,
          'role': 'student',
          'grade': request.grade,
          'subjects': request.subjects,
          'studentId': studentId,
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send approval notification email
        await _emailService.sendApprovalEmail(request.email, request.name);

        // Delete the registration document after approval
        transaction.delete(_registrationsCollection.doc(id));
      });
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> rejectRegistration(String id, String reason) async {
    try {
      // Get the registration request first to get email and name
      final request = await getRegistrationById(id);

      // Update status to rejected
      await _registrationsCollection.doc(id).update({
        'status': 'rejected',
        'rejectReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send rejection notification email
      await _emailService.sendRejectionEmail(request.email, request.name, reason);

      // Delete the registration document after rejection
      await _registrationsCollection.doc(id).delete();
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Check Firebase Auth for existing account
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);

      if (methods.isNotEmpty) {
        return false; // Email already exists in auth
      }

      // Check pending registrations for this email
      final query = await _registrationsCollection
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();

      return query.docs.isEmpty; // Email is available if no pending requests
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> isEmailVerified(String userId) async {
    try {
      // First check Firebase Auth
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        // If this is the currently signed in user, reload to get latest status
        await currentUser.reload();
        return currentUser.emailVerified;
      }

      // Otherwise check Firestore (as a fallback)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['emailVerified'] ?? false;
      }

      return false;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> resendVerificationEmail(String userId) async {
    try {
      // Get the current user
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.sendEmailVerification();
      } else {
        throw Exception('Cannot resend verification email. User not logged in.');
      }
    } catch (e) {
      throw _handleException(e);
    }
  }

  // Password encryption - replace with a more secure method in production
  String _encryptPassword(String password) {
    // This is a simple implementation for demo purposes
    // In production, use a proper encryption library like encrypt package

    // For now, we'll use a simple encoding method
    // WARNING: This is NOT secure for production!
    final key = 'mytuition_secret_key';
    final bytes = utf8.encode(password);
    final keyBytes = utf8.encode(key);

    // XOR each byte with the corresponding byte from the key
    final encrypted = List<int>.generate(
      bytes.length,
          (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return base64.encode(encrypted);
  }

  // Password decryption
  String _decryptPassword(String encryptedPassword) {
    // Reverse of the encryption method
    final key = 'mytuition_secret_key';
    final bytes = base64.decode(encryptedPassword);
    final keyBytes = utf8.encode(key);

    final decrypted = List<int>.generate(
      bytes.length,
          (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return utf8.decode(decrypted);
  }

  // Helper method to handle exceptions
  Exception _handleException(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      return Exception('Authentication error: ${e.message}');
    }
    if (e is FirebaseException) {
      return Exception('Database error: ${e.message}');
    }
    return Exception('An unexpected error occurred: $e');
  }
}