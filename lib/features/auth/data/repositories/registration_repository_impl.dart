import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/repositories/registration_repository.dart';
import '../models/registration_model.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  // Collection reference for registration requests
  final CollectionReference _registrationsCollection;

  // Constructor
  RegistrationRepositoryImpl(this._firestore, this._firebaseAuth)
      : _registrationsCollection = _firestore.collection('registration_requests');

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

      // Store request in Firestore
      await _registrationsCollection.add({
        'email': email,
        'name': name,
        'phone': phone,
        'grade': grade,
        'subjects': subjects,
        'hasConsulted': hasConsulted,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        // Store password securely (in a real app, consider more secure options)
        'password': _encryptPassword(password), // This is a placeholder
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

  @override
  Future<void> approveRegistration(String id) async {
    try {
      // Get the registration request
      final request = await getRegistrationById(id);

      // Begin a transaction
      return await _firestore.runTransaction((transaction) async {
        // Get the document data including password
        final docSnapshot = await transaction.get(_registrationsCollection.doc(id));
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Create user in Firebase Auth
        final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: request.email,
          password: _decryptPassword(data['password']), // Decrypt password
        );

        if (userCredential.user == null) {
          throw Exception('Failed to create user account');
        }

        final userId = userCredential.user!.uid;

        // Create user profile in users collection
        final userDoc = _firestore.collection('users').doc(userId);

        transaction.set(userDoc, {
          'name': request.name,
          'email': request.email,
          'phone': request.phone,
          'role': 'student', // Always student for registration
          'grade': request.grade,
          'subjects': request.subjects,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update request status to approved
        transaction.update(_registrationsCollection.doc(id), {
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> rejectRegistration(String id, String reason) async {
    try {
      await _registrationsCollection.doc(id).update({
        'status': 'rejected',
        'rejectReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  // Placeholder for password encryption (in a real app, use secure methods)
  String _encryptPassword(String password) {
    // Warning: This is NOT secure and just for demo purposes
    // In a real app, consider more secure options or let Firebase handle it
    return password; // Do NOT do this in production
  }

  // Placeholder for password decryption
  String _decryptPassword(String encryptedPassword) {
    // Warning: This is NOT secure and just for demo purposes
    return encryptedPassword; // Do NOT do this in production
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