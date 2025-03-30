import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  final FirebaseFirestore _firestore;

  EmailService(this._firestore);

  // Queue an approval email
  Future<void> sendApprovalEmail(String email, String name) async {
    try {
      await _firestore.collection('mail').add({
        'to': email,
        'template': 'registration_approved',
        'data': {
          'name': name,
          'loginUrl': 'https://mytuition.app/login',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log the email action
      await _firestore.collection('email_logs').add({
        'email': email,
        'type': 'registration_approved',
        'status': 'queued',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending approval email: $e');
    }
  }

  // Queue a rejection email
  Future<void> sendRejectionEmail(String email, String name, String reason) async {
    try {
      await _firestore.collection('mail').add({
        'to': email,
        'template': 'registration_rejected',
        'data': {
          'name': name,
          'reason': reason,
          'supportEmail': 'support@mytuition.app',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log the email action
      await _firestore.collection('email_logs').add({
        'email': email,
        'type': 'registration_rejected',
        'status': 'queued',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending rejection email: $e');
    }
  }
}