import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/datasources/remote/email_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final EmailService _emailService;

  NotificationService(this._firestore, this._emailService);

  // Send payment reminder notification (in-app only)
  Future<void> sendPaymentReminder(
      String studentId, double amount, int month, int year) async {
    final monthName = _getMonthName(month);

    await _firestore.collection('notifications').add({
      'studentId': studentId,
      'type': 'payment_reminder',
      'title': 'Payment Reminder',
      'message': 'Your payment of RM $amount for $monthName $year is due.',
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Send payment confirmation (in-app + email)
  Future<void> sendPaymentConfirmation(String studentId, String studentEmail,
      String studentName, double amount, int month, int year) async {
    final monthName = _getMonthName(month);
    final now = DateTime.now();

    // In-app notification
    await _firestore.collection('notifications').add({
      'studentId': studentId,
      'type': 'payment_confirmed',
      'title': 'Payment Confirmed',
      'message':
          'Your payment of RM $amount for $monthName $year has been received.',
      'isRead': false,
      'createdAt': Timestamp.fromDate(now),
    });

    // Email notification using existing EmailService
    await _emailService.sendEmail(
      to: studentEmail,
      template: 'payment_confirmed',
      data: {
        'name': studentName,
        'amount': amount.toString(),
        'month': monthName,
        'year': year.toString(),
        'date': _formatDate(now),
      },
    );
  }

  // Send batch payment reminders
  Future<void> sendBatchPaymentReminders(
      List<Map<String, dynamic>> studentPayments) async {
    for (final payment in studentPayments) {
      await sendPaymentReminder(
        payment['studentId'],
        payment['amount'],
        payment['month'],
        payment['year'],
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
