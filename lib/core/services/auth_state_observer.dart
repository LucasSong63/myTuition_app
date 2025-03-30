import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthStateObserver {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthStateObserver(this._auth, this._firestore);

  void initialize() {
    _auth.authStateChanges().listen(_handleAuthStateChange);
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (user != null && user.emailVerified) {
      // Update Firestore user record when email is verified
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating email verification status: $e');
      }
    }
  }
}