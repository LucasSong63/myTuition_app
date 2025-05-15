// lib/features/payments/data/repositories/payment_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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

    // Update the payment record
    final paymentRef = _firestore.collection('payments').doc(payment.id);

    final DateTime now = DateTime.now();
    final String previousStatus = payment.status;

    // Determine new status based on payment amount and discount
    final double totalDue = payment.amount;
    final double totalPaid = amount;
    final double totalDiscount = discount;

    String newStatus;
    if (totalPaid + totalDiscount >= totalDue) {
      newStatus = 'paid';
    } else if (totalPaid > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'unpaid';
    }

    // Create payment data update
    final Map<String, dynamic> paymentUpdate = {
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(now),
    };

    // Add discount field if there is a discount
    if (discount > 0) {
      paymentUpdate['discount'] = discount;
    }

    // Add paidDate if payment is complete or partial
    if (newStatus == 'paid' || newStatus == 'partial') {
      paymentUpdate['paidDate'] = Timestamp.fromDate(now);
    }

    // Add remarks if provided
    if (remarks.isNotEmpty) {
      paymentUpdate['remarks'] = remarks;
    }

    // Add amountPaid field to track partial payments
    if (newStatus == 'partial') {
      paymentUpdate['amountPaid'] = amount;
    }

    batch.update(paymentRef, paymentUpdate);

    // Create payment history record
    final historyRef = _firestore.collection('payment_history').doc();
    Map<String, dynamic> historyData = {
      'paymentId': payment.id,
      'studentId': payment.studentId,
      'amount': amount,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'date': Timestamp.fromDate(now),
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(now),
      'month': payment.month,
      'year': payment.year,
    };

    // Add remarks if provided
    if (remarks.isNotEmpty) {
      historyData['remarks'] = remarks;
    }

    // Add discount field if there is a discount
    if (discount > 0) {
      historyData['discount'] = discount;
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
      // Calculate discount for each payment
      double paymentDiscount = 0.0;
      if (discount > 0) {
        // Apply the same discount percentage to each payment
        paymentDiscount = (discount / payments.length);
      }

      // Determine if payment is fully paid with discount
      final bool isFullyPaid = payment.amount <= paymentDiscount;

      // Update payment record
      final paymentRef = _firestore.collection('payments').doc(payment.id);

      final Map<String, dynamic> paymentUpdate = {
        'status': isFullyPaid ? 'paid' : 'partial',
        'paidDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Add remarks if provided
      if (remarks.isNotEmpty) {
        paymentUpdate['remarks'] = remarks;
      }

      // Add discount field if there is a discount
      if (paymentDiscount > 0) {
        paymentUpdate['discount'] = paymentDiscount;
      }

      batch.update(paymentRef, paymentUpdate);

      // Create payment history record
      final historyRef = _firestore.collection('payment_history').doc();

      Map<String, dynamic> historyData = {
        'paymentId': payment.id,
        'studentId': payment.studentId,
        'amount':
            isFullyPaid ? payment.amount : (payment.amount - paymentDiscount),
        'previousStatus': payment.status,
        'newStatus': isFullyPaid ? 'paid' : 'partial',
        'date': Timestamp.fromDate(now),
        'recordedBy': recordedBy,
        'createdAt': Timestamp.fromDate(now),
        'month': payment.month,
        'year': payment.year,
      };

      // Add remarks if provided
      if (remarks.isNotEmpty) {
        historyData['remarks'] = remarks;
      }

      // Add discount field if there is a discount
      if (paymentDiscount > 0) {
        historyData['discount'] = paymentDiscount;
      }

      batch.set(historyRef, historyData);
    }

    // Commit the batch
    await batch.commit();
  }

  @override
  Future<void> sendPaymentReminders(
      List<Payment> payments, String message) async {
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());

    for (final payment in payments) {
      // Create notification
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'studentId': payment.studentId,
        'type': 'payment_reminder',
        'title': 'Payment Reminder',
        'message': message,
        'isRead': false,
        'createdAt': now,
        'paymentId': payment.id,
        'amount': payment.amount,
        'month': payment.month,
        'year': payment.year,
      });
    }

    // Commit the batch
    await batch.commit();
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
        final Map<String, dynamic> data = doc.data();

        // Calculate outstanding amount considering discount and partial payments
        double outstanding = payment.amount;

        // Subtract discount if any
        if (data.containsKey('discount')) {
          outstanding -= (data['discount'] as num).toDouble();
        }

        // Subtract amount paid if this is a partial payment
        if (payment.status == 'partial' && data.containsKey('amountPaid')) {
          outstanding -= (data['amountPaid'] as num).toDouble();
        }

        // Only add to total if there is still an outstanding amount
        if (outstanding > 0) {
          total += outstanding;
        }
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate outstanding amount: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentPaymentStats(String studentId) async {
    try {
      final totalOutstanding = await calculateTotalOutstanding(studentId);

      // Get count of paid, unpaid, and partial payments
      final paidQuery = _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'paid');

      final unpaidQuery = _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'unpaid');

      final partialQuery = _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'partial');

      final paidSnapshot = await paidQuery.get();
      final unpaidSnapshot = await unpaidQuery.get();
      final partialSnapshot = await partialQuery.get();

      // Calculate total paid amount
      double totalPaid = 0;
      double totalDiscount = 0;

      // Calculate from paid payments
      for (var doc in paidSnapshot.docs) {
        final data = doc.data();
        final payment = Payment.fromFirestore(doc);

        // Add the full amount to total paid
        totalPaid += payment.amount;

        // Track discounts separately
        if (data.containsKey('discount')) {
          totalDiscount += (data['discount'] as num).toDouble();
        }
      }

      // Add partial payments to total paid
      for (var doc in partialSnapshot.docs) {
        final data = doc.data();

        // Add partial amount to total paid
        if (data.containsKey('amountPaid')) {
          totalPaid += (data['amountPaid'] as num).toDouble();
        }

        // Track discounts
        if (data.containsKey('discount')) {
          totalDiscount += (data['discount'] as num).toDouble();
        }
      }

      return {
        'totalOutstanding': totalOutstanding,
        'totalPaid': totalPaid,
        'totalDiscount': totalDiscount,
        'paidCount': paidSnapshot.docs.length,
        'unpaidCount': unpaidSnapshot.docs.length,
        'partialCount': partialSnapshot.docs.length,
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
