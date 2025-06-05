// lib/features/payments/data/repositories/payment_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/features/notifications/domain/entities/notification_type.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/features/payments/domain/entities/payment_history_with_student.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_history.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepositoryImpl(this._firestore);

  @override
  Future<List<Payment>> getPaymentsByMonthYear(int month, int year) async {
    final querySnapshot = await _firestore
        .collection('payments')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .orderBy('studentName')
        .get();

    return querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
  }

  @override
  Future<Payment?> getStudentPayment(
      String studentId, int month, int year) async {
    final querySnapshot = await _firestore
        .collection('payments')
        .where('studentId', isEqualTo: studentId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return Payment.fromFirestore(querySnapshot.docs.first);
  }

  @override
  Future<List<Payment>> getStudentPayments(String studentId) async {
    final querySnapshot = await _firestore
        .collection('payments')
        .where('studentId', isEqualTo: studentId)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
  }

  @override
  Future<void> createPayment(Payment payment) async {
    try {
      final data = payment.toFirestore();

      // Create a new payment document
      final docRef = await _firestore.collection('payments').add(data);

      // If this is a direct paid payment, also create a payment history record
      if (payment.status == 'paid') {
        final historyRef = _firestore.collection('payment_history').doc();
        final now = DateTime.now();

        await historyRef.set({
          'paymentId': docRef.id,
          'studentId': payment.studentId,
          // Use the same studentId as in the payment
          'amount': payment.amount,
          'previousStatus': 'new',
          // New payment
          'newStatus': 'paid',
          'date': Timestamp.fromDate(now),
          'remarks': payment.remarks,
          'recordedBy': 'tutor-leong',
          // Should ideally come from auth
          'createdAt': Timestamp.fromDate(now),
          'month': payment.month,
          'year': payment.year,
        });
      }
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<void> updatePayment(Payment payment) async {
    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(payment.toFirestore());
  }

  @override
  Future<void> recordPayment(
      Payment payment, double amount, String remarks, String recordedBy,
      {double discount = 0.0}) async {
    // Start a batch to ensure both operations complete
    final batch = _firestore.batch();
    final paymentRef = _firestore.collection('payments').doc(payment.id);
    final DateTime now = DateTime.now();
    final String previousStatus = payment.status;

    // Get current cumulative amounts (from existing payment record)
    double currentAmountPaid = payment.amountPaid ?? 0.0;
    double currentDiscount = payment.discount ?? 0.0;

    // Calculate new cumulative amounts
    double newTotalAmountPaid = currentAmountPaid + amount;
    double newTotalDiscount = currentDiscount + discount;
    double totalDue = payment.amount;

    // Determine status based on cumulative payments
    String newStatus;
    if (newTotalAmountPaid + newTotalDiscount >= totalDue) {
      newStatus = 'paid';
    } else if (newTotalAmountPaid > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'unpaid';
    }

    // Create payment data update
    final Map<String, dynamic> paymentUpdate = {
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(now),
      'amountPaid': newTotalAmountPaid, // Cumulative amount paid
      'discount': newTotalDiscount, // Cumulative discount
    };

    // Add paidDate when payment is complete
    if (newStatus == 'paid') {
      paymentUpdate['paidDate'] = Timestamp.fromDate(now);
    }

    // Add remarks if provided (this will be the latest remark)
    if (remarks.isNotEmpty) {
      paymentUpdate['remarks'] = remarks;
    }

    batch.update(paymentRef, paymentUpdate);

    // Create payment history record for this specific transaction
    final historyRef = _firestore.collection('payment_history').doc();
    Map<String, dynamic> historyData = {
      'paymentId': payment.id,
      'studentId': payment.studentId,
      'amount': amount, // This transaction's amount
      'discount': discount, // This transaction's discount
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'date': Timestamp.fromDate(now),
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(now),
      'month': payment.month,
      'year': payment.year,
      // Track cumulative amounts for history tracking
      'cumulativeAmountPaid': newTotalAmountPaid,
      'cumulativeDiscount': newTotalDiscount,
    };

    if (remarks.isNotEmpty) {
      historyData['remarks'] = remarks;
    }

    batch.set(historyRef, historyData);

    // Commit the batch
    await batch.commit();
  }

  @override
  Future<List<PaymentHistory>> getPaymentHistory(String paymentId) async {
    final querySnapshot = await _firestore
        .collection('payment_history')
        .where('paymentId', isEqualTo: paymentId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PaymentHistory.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<PaymentHistory>> getStudentPaymentHistory(
      String studentId) async {
    final querySnapshot = await _firestore
        .collection('payment_history')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PaymentHistory.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> recordBulkPayments(
      List<Payment> payments, String remarks, String recordedBy,
      {double discount = 0.0}) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final payment in payments) {
      // Get current cumulative amounts
      double currentAmountPaid = payment.amountPaid ?? 0.0;
      double currentDiscount = payment.discount ?? 0.0;

      // Calculate outstanding amount for this payment
      double outstandingAmount =
          payment.amount - currentAmountPaid - currentDiscount;

      // For bulk "mark as paid", we want to pay the full outstanding amount
      // The discount parameter is applied per payment (not total)
      double paymentAmount = outstandingAmount - discount;

      // Ensure we don't have negative payment amounts
      if (paymentAmount < 0) {
        paymentAmount = 0;
      }

      // Calculate new cumulative totals
      double newTotalAmountPaid = currentAmountPaid + paymentAmount;
      double newTotalDiscount = currentDiscount + discount;

      // Determine new status - should be 'paid' since we're paying outstanding
      String newStatus;
      if (newTotalAmountPaid + newTotalDiscount >= payment.amount) {
        newStatus = 'paid';
      } else if (newTotalAmountPaid > 0) {
        newStatus = 'partial';
      } else {
        newStatus = 'unpaid';
      }

      // Update payment record
      final paymentRef = _firestore.collection('payments').doc(payment.id);
      final Map<String, dynamic> paymentUpdate = {
        'status': newStatus,
        'amountPaid': newTotalAmountPaid,
        'discount': newTotalDiscount,
        'updatedAt': Timestamp.fromDate(now),
      };

      // Set paidDate for completed payments
      if (newStatus == 'paid') {
        paymentUpdate['paidDate'] = Timestamp.fromDate(now);
      }

      // Add remarks if provided
      if (remarks.isNotEmpty) {
        paymentUpdate['remarks'] = remarks;
      }

      batch.update(paymentRef, paymentUpdate);

      // Create payment history record
      final historyRef = _firestore.collection('payment_history').doc();
      batch.set(historyRef, {
        'paymentId': payment.id,
        'studentId': payment.studentId,
        'amount': paymentAmount,
        'discount': discount,
        'previousStatus': payment.status,
        'newStatus': newStatus,
        'date': Timestamp.fromDate(now),
        'recordedBy': recordedBy,
        'createdAt': Timestamp.fromDate(now),
        'month': payment.month,
        'year': payment.year,
        'cumulativeAmountPaid': newTotalAmountPaid,
        'cumulativeDiscount': newTotalDiscount,
        'remarks': remarks.isNotEmpty ? remarks : null,
      });
    }

    // Commit the batch
    await batch.commit();
  }

  Future<void> sendPaymentReminders(
      List<Payment> payments, String message) async {
    try {
      // Get notification manager
      final notificationManager = GetIt.instance<NotificationManager>();

      // Send notifications to each student
      for (final payment in payments) {
        await notificationManager.sendStudentNotification(
          studentId: payment.studentId,
          type: NotificationType.paymentReminder,
          title: 'Payment Reminder',
          message: message.isEmpty
              ? 'Your payment of RM ${payment.amount.toStringAsFixed(2)} for ${_getMonthName(payment.month)} ${payment.year} is due.'
              : message,
          data: {
            'paymentId': payment.id,
            'amount': payment.amount,
            'month': payment.month,
            'year': payment.year,
          },
        );
      }
    } catch (e) {
      print('Error sending payment reminders: $e');
      throw Exception('Failed to send payment reminders: $e');
    }
  }

// Helper method
  String _getMonthName(int month) {
    final months = [
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

  @override
  Future<void> sendAllUnpaidReminders(
      int month, int year, String message) async {
    // Get all unpaid payments for the month/year
    final querySnapshot = await _firestore
        .collection('payments')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .where('status', isEqualTo: 'unpaid')
        .get();

    final unpaidPayments =
        querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();

    // Send reminders for those payments
    await sendPaymentReminders(unpaidPayments, message);
  }

  @override
  Future<List<PaymentHistoryWithStudent>> getAllPaymentHistory() async {
    final querySnapshot = await _firestore
        .collection('payment_history')
        .orderBy('createdAt', descending: true)
        .get();

    final List<PaymentHistoryWithStudent> result = [];

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final basicHistory = PaymentHistory.fromFirestore(doc);

      // Get payment details
      final paymentDoc = await _firestore
          .collection('payments')
          .doc(basicHistory.paymentId)
          .get();

      if (!paymentDoc.exists) continue;

      final paymentData = paymentDoc.data() as Map<String, dynamic>;

      result.add(
        PaymentHistoryWithStudent(
          id: basicHistory.id,
          paymentId: basicHistory.paymentId,
          studentId: basicHistory.studentId,
          studentName: paymentData['studentName'] ?? 'Unknown',
          amount: basicHistory.amount,
          previousStatus: basicHistory.previousStatus,
          newStatus: basicHistory.newStatus,
          date: basicHistory.date,
          remarks: basicHistory.remarks,
          recordedBy: basicHistory.recordedBy,
          createdAt: basicHistory.createdAt,
          month: paymentData['month'] ?? 0,
          year: paymentData['year'] ?? 0,
        ),
      );
    }

    return result;
  }

  @override
  Future<bool> hasOutstandingPayments(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: ['unpaid', 'partial'])
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check outstanding payments: $e');
    }
  }

  @override
  Future<double> calculateTotalOutstanding(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: ['unpaid', 'partial']).get();

      double total = 0;
      for (var doc in querySnapshot.docs) {
        final payment = Payment.fromFirestore(doc);
        // Use the entity method for consistency
        total += payment.getOutstandingAmount();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate outstanding amount: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentPaymentStats(String studentId) async {
    try {
      // Get all payments for this student
      final allPaymentsQuery = await _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .get();

      double totalOutstanding = 0;
      double totalPaid = 0;
      double totalDiscount = 0;
      int paidCount = 0;
      int unpaidCount = 0;
      int partialCount = 0;

      for (var doc in allPaymentsQuery.docs) {
        final payment = Payment.fromFirestore(doc);

        // Count by status
        switch (payment.status) {
          case 'paid':
            paidCount++;
            totalPaid += payment.amount;
            break;
          case 'unpaid':
            unpaidCount++;
            totalOutstanding += payment.amount;
            break;
          case 'partial':
            partialCount++;
            totalPaid += (payment.amountPaid ?? 0);
            totalOutstanding += payment.getOutstandingAmount();
            break;
        }

        // Add discount to total (if any)
        if (payment.discount != null) {
          totalDiscount += payment.discount!;
        }
      }

      return {
        'totalOutstanding': totalOutstanding,
        'totalPaid': totalPaid,
        'totalDiscount': totalDiscount,
        'paidCount': paidCount,
        'unpaidCount': unpaidCount,
        'partialCount': partialCount,
      };
    } catch (e) {
      throw Exception('Failed to get payment stats: $e');
    }
  }

  @override
  Future<int> generateMonthlyPayments(
      int month, int year, double defaultAmount) async {
    print('Generating monthly payments for month: $month, year: $year');
    // Get all active students
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    if (studentsSnapshot.docs.isEmpty) {
      return 0; // No students found
    }

    // Keep track of how many payments we create
    int createdPayments = 0;
    var batch = _firestore.batch();
    final now = DateTime.now();

    // For each student
    for (var studentDoc in studentsSnapshot.docs) {
      final userDocId = studentDoc.id;
      final studentData = studentDoc.data();
      final studentName = studentData['name'] ?? 'Unknown Student';
      final studentId = studentData['studentId'] as String?;

      if (studentId == null) {
        print('Student has no ID, skipping: $userDocId');
        continue;
      }

      // Check if payment for this month/year already exists
      final existingPaymentQuery = await _firestore
          .collection('payments')
          .where('studentId',
              isEqualTo: studentId) // FIXED: Use studentId instead of userDocId
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (existingPaymentQuery.docs.isNotEmpty) {
        print('Payment already exists for student $studentId, skipping');
        continue; // Skip - payment already exists
      }

      // Check if student is enrolled in any classes
      final enrolledClassesQuery = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      if (enrolledClassesQuery.docs.isEmpty) {
        print('Student $studentId is not enrolled in any classes, skipping');
        continue; // Skip students not enrolled in any classes
      }

      // Calculate tuition amount
      double totalAmount = await _calculateStudentTuition(userDocId);

      // If calculation fails or returns 0, continue to next student
      if (totalAmount <= 0) {
        print('No tuition calculated for student $studentId, skipping');
        continue;
      }

      // Create payment document
      final paymentRef = _firestore.collection('payments').doc();
      final payment = {
        'studentId': studentId, // FIXED: Use studentId instead of userDocId
        'studentName': studentName,
        'month': month,
        'year': year,
        'amount': totalAmount,
        'status': 'unpaid',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      batch.set(paymentRef, payment);
      createdPayments++;

      // Firestore batch limit
      if (createdPayments % 400 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    // Commit any remaining operations
    if (createdPayments > 0) {
      await batch.commit();
    }

    return createdPayments;
  }

  // Helper method to calculate student tuition based on enrolled classes
  Future<double> _calculateStudentTuition(String userDocId) async {
    double totalTuition = 0.0;

    // First, get the studentId from the user document
    final userDoc = await _firestore.collection('users').doc(userDocId).get();
    if (!userDoc.exists) {
      print('User document not found: $userDocId');
      return 0.0;
    }

    final userData = userDoc.data();
    if (userData == null || !userData.containsKey('studentId')) {
      print('User has no studentId field: $userDocId');
      return 0.0;
    }

    final studentId = userData['studentId'] as String;
    print('Looking up classes for studentId: $studentId, user: $userDocId');

    // Now get all classes where this studentId is enrolled
    final enrolledClassesQuery = await _firestore
        .collection('classes')
        .where('students', arrayContains: studentId)
        .get();

    print(
        'Found ${enrolledClassesQuery.docs.length} enrolled classes for studentId: $studentId');

    // For each enrolled class, get the corresponding subject cost
    for (var classDoc in enrolledClassesQuery.docs) {
      final classId = classDoc.id;
      print('Processing class: $classId');

      // Get subject cost for this class
      final classData = classDoc.data();

      // Check if the class directly has a subjectCost field
      if (classData.containsKey('subjectCost')) {
        final cost = (classData['subjectCost'] as num).toDouble();
        totalTuition += cost;
        print(
            'Added cost $cost for class $classId from class document, total now: $totalTuition');
        continue;
      }

      // Fall back to subject_costs collection
      final subjectCostDoc =
          await _firestore.collection('subject_costs').doc(classId).get();

      if (subjectCostDoc.exists) {
        final data = subjectCostDoc.data();
        if (data != null && data.containsKey('cost')) {
          final cost = (data['cost'] as num).toDouble();
          totalTuition += cost;
          print(
              'Added cost $cost for class $classId from subject_costs, total now: $totalTuition');
        } else {
          print(
              'No cost field found in subject cost document for class $classId');
        }
      } else {
        print('No subject cost document found for class $classId');
      }
    }

    print('Final tuition for student $studentId: $totalTuition');
    return totalTuition;
  }
}
