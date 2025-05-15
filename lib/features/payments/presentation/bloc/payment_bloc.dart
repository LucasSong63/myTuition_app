// lib/features/payments/presentation/bloc/payment_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:mytuition/features/notifications/data/notifications_service.dart';
import 'package:mytuition/features/auth/data/datasources/remote/email_service.dart';
import 'package:mytuition/features/payments/domain/entities/payment_history_with_student.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_history.dart';
import '../../domain/repositories/payment_repository.dart';

part 'payment_event.dart';

part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  final FirebaseFirestore _firestore; // Add this field

  PaymentBloc({
    required PaymentRepository paymentRepository,
  })  : _paymentRepository = paymentRepository,
        _firestore = FirebaseFirestore.instance,
        // Initialize it here
        super(PaymentInitial()) {
    on<LoadPaymentsByMonthEvent>(_onLoadPaymentsByMonth);
    on<LoadStudentPaymentEvent>(_onLoadStudentPayment);
    on<LoadStudentPaymentsEvent>(_onLoadStudentPayments);
    on<RecordPaymentEvent>(_onRecordPayment);
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
    on<LoadStudentPaymentHistoryEvent>(_onLoadStudentPaymentHistory);
    on<GenerateMonthlyPaymentsEvent>(_onGenerateMonthlyPayments);
    on<CheckStudentPaymentStatusEvent>(_onCheckStudentPaymentStatus);
    on<GetStudentPaymentStatsEvent>(_onGetStudentPaymentStats);
    on<CreatePaymentEvent>(_onCreatePayment);
    on<SendPaymentRemindersEvent>(_onSendPaymentReminders);
    on<SendAllUnpaidRemindersEvent>(_onSendAllUnpaidReminders);
    on<LoadAllPaymentHistoryEvent>(_onLoadAllPaymentHistory);
    on<BulkMarkPaymentsAsPaidEvent>(_onBulkMarkPaymentsAsPaid);
    // Add new event handler for generating missing payments
    on<GeneratePaymentForStudentEvent>(_onGeneratePaymentForStudent);
    on<GenerateMissingPaymentsEvent>(_onGenerateMissingPayments);
  }

  Future<void> _onLoadPaymentsByMonth(
      LoadPaymentsByMonthEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      print('Loading payments for month ${event.month}, year ${event.year}');
      final payments = await _paymentRepository.getPaymentsByMonthYear(
          event.month, event.year);
      print('Loaded ${payments.length} payments');
      emit(PaymentsByMonthLoaded(
          payments: payments, month: event.month, year: event.year));
    } catch (e, stackTrace) {
      print('Error loading payments: $e');
      print('Stack trace: $stackTrace');
      emit(PaymentError(message: 'Failed to load payments: $e'));
    }
  }

  Future<void> _onLoadStudentPayment(
      LoadStudentPaymentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final payment = await _paymentRepository.getStudentPayment(
          event.studentId, event.month, event.year);
      if (payment != null) {
        emit(StudentPaymentLoaded(payment: payment));
      } else {
        emit(PaymentNotFound());
      }
    } catch (e) {
      emit(PaymentError(message: 'Failed to load student payment: $e'));
    }
  }

  Future<void> _onLoadStudentPayments(
      LoadStudentPaymentsEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final payments =
          await _paymentRepository.getStudentPayments(event.studentId);
      emit(StudentPaymentsLoaded(
          payments: payments, studentId: event.studentId));
    } catch (e) {
      emit(PaymentError(message: 'Failed to load student payments: $e'));
    }
  }

  Future<void> _onRecordPayment(
      RecordPaymentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      await _paymentRepository.recordPayment(
        event.payment,
        event.amount,
        event.remarks,
        event.recordedBy,
        discount: event.discount,
      );

      // Reload the payment to get the updated data
      final payment = await _paymentRepository.getStudentPayment(
          event.payment.studentId, event.payment.month, event.payment.year);

      emit(PaymentRecorded(
        payment: payment ?? event.payment,
        message: 'Payment successfully recorded',
      ));
    } catch (e) {
      emit(PaymentError(message: 'Failed to record payment: $e'));
    }
  }

  Future<void> _onLoadPaymentHistory(
      LoadPaymentHistoryEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final history =
          await _paymentRepository.getPaymentHistory(event.paymentId);
      emit(PaymentHistoryLoaded(history: history));
    } catch (e) {
      emit(PaymentError(message: 'Failed to load payment history: $e'));
    }
  }

  Future<void> _onLoadStudentPaymentHistory(
      LoadStudentPaymentHistoryEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final history =
          await _paymentRepository.getStudentPaymentHistory(event.studentId);
      emit(StudentPaymentHistoryLoaded(
          history: history, studentId: event.studentId));
    } catch (e) {
      emit(PaymentError(message: 'Failed to load student payment history: $e'));
    }
  }

  Future<void> _onGenerateMonthlyPayments(
      GenerateMonthlyPaymentsEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      // Use the payment repository implementation directly
      final createdCount = await _paymentRepository.generateMonthlyPayments(
          event.month, event.year, event.defaultAmount);

      emit(PaymentOperationSuccess(
        message: 'Generated $createdCount new payment records',
      ));

      // Reload payments for the month
      add(LoadPaymentsByMonthEvent(month: event.month, year: event.year));
    } catch (e) {
      emit(PaymentError(message: 'Failed to generate monthly payments: $e'));
    }
  }

  // Handler for generating payment for a specific student
  Future<void> _onGeneratePaymentForStudent(
      GeneratePaymentForStudentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      // Get student info
      final userDoc =
          await _firestore.collection('users').doc(event.userDocId).get();
      if (!userDoc.exists) {
        emit(PaymentError(message: 'Student not found'));
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        emit(PaymentError(message: 'Invalid student data'));
        return;
      }

      final studentName = userData['name'] ?? 'Unknown Student';
      final studentId = userData['studentId'] as String?;
      if (studentId == null) {
        emit(PaymentError(message: 'Student has no ID'));
        return;
      }

      // Check if payment already exists
      final existingPaymentQuery = await _firestore
          .collection('payments')
          .where('studentId',
              isEqualTo: studentId) // Use studentId, not event.userDocId
          .where('month', isEqualTo: event.month)
          .where('year', isEqualTo: event.year)
          .limit(1)
          .get();

      if (existingPaymentQuery.docs.isNotEmpty) {
        emit(PaymentOperationSuccess(
            message: 'Payment already exists for this student'));
        return;
      }

      // Check if student is enrolled in classes
      final enrolledClassesQuery = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      if (enrolledClassesQuery.docs.isEmpty) {
        emit(PaymentError(message: 'Student is not enrolled in any classes'));
        return;
      }

      // Calculate tuition
      double totalAmount = await _calculateStudentTuition(event.userDocId);
      if (totalAmount <= 0) {
        emit(PaymentError(message: 'No tuition calculated for this student'));
        return;
      }

      // Create payment record
      await _firestore.collection('payments').add({
        'studentId': studentId, // Use studentId, not event.userDocId
        'studentName': studentName,
        'month': event.month,
        'year': event.year,
        'amount': totalAmount,
        'status': 'unpaid',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      emit(PaymentOperationSuccess(
        message: 'Generated payment for student: $studentName',
      ));

      // Reload payments
      add(LoadPaymentsByMonthEvent(month: event.month, year: event.year));
    } catch (e) {
      emit(PaymentError(message: 'Failed to generate payment: $e'));
    }
  }

  // Handler for generating payments for all students who don't have them yet
  Future<void> _onGenerateMissingPayments(
      GenerateMissingPaymentsEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      // Get all students
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Get existing payments
      final existingPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('month', isEqualTo: event.month)
          .where('year', isEqualTo: event.year)
          .get();

      // Create a set of student IDs who already have payments
      final Set<String> studentsWithPayments = {};
      for (var doc in existingPaymentsSnapshot.docs) {
        final data = doc.data();
        studentsWithPayments.add(data['studentId'] as String);
      }

      // Create a batch
      final batch = _firestore.batch();
      final now = DateTime.now();
      int createdCount = 0;

      // For each student without a payment
      for (var studentDoc in studentsSnapshot.docs) {
        final userDocId = studentDoc.id;
        final studentData = studentDoc.data();
        final studentName = studentData['name'] ?? 'Unknown Student';
        final studentId = studentData['studentId'] as String?;

        if (studentId == null) {
          continue;
        }

        // Skip if payment already exists - use studentId, not userDocId
        if (studentsWithPayments.contains(studentId)) {
          continue;
        }

        // Check if student is enrolled in any classes
        final enrolledClassesQuery = await _firestore
            .collection('classes')
            .where('students', arrayContains: studentId)
            .get();

        if (enrolledClassesQuery.docs.isEmpty) {
          continue; // Skip students not enrolled in any classes
        }

        // Calculate tuition
        double totalAmount = await _calculateStudentTuition(userDocId);
        if (totalAmount <= 0) {
          continue;
        }

        // Create payment document
        final paymentRef = _firestore.collection('payments').doc();
        batch.set(paymentRef, {
          'studentId': studentId, // Use studentId, not userDocId
          'studentName': studentName,
          'month': event.month,
          'year': event.year,
          'amount': totalAmount,
          'status': 'unpaid',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });

        createdCount++;
      }

      // Commit the batch if needed
      if (createdCount > 0) {
        await batch.commit();
      }

      emit(PaymentOperationSuccess(
        message: 'Generated $createdCount missing payment records',
      ));

      // Reload payments
      add(LoadPaymentsByMonthEvent(month: event.month, year: event.year));
    } catch (e) {
      emit(PaymentError(message: 'Failed to generate missing payments: $e'));
    }
  }

  // Helper method to calculate student tuition
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

    // Get all classes where this studentId is enrolled
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

      // Check if the class has a subjectCost field directly
      final classData = classDoc.data();
      if (classData.containsKey('subjectCost')) {
        final cost = (classData['subjectCost'] as num).toDouble();
        totalTuition += cost;
        print(
            'Added cost $cost for class $classId from class document, total now: $totalTuition');
        continue;
      }

      // Fall back to subject_costs collection if no direct cost in class document
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

  Future<void> _onBulkMarkPaymentsAsPaid(
      BulkMarkPaymentsAsPaidEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      await _paymentRepository.recordBulkPayments(
        event.payments,
        event.remarks,
        event.recordedBy,
        discount: event.discount,
      );

      if (event.sendNotification) {
        // Send payment confirmation notifications (you'll need to implement this)
        for (final payment in event.payments) {
          // Get student email from Firebase
          final studentDoc =
              await _firestore.collection('users').doc(payment.studentId).get();

          if (studentDoc.exists) {
            final studentData = studentDoc.data() as Map<String, dynamic>;
            final studentEmail = studentData['email'] as String?;

            if (studentEmail != null) {
              // Send confirmation notification
              final notificationService = NotificationService(
                _firestore,
                EmailService(_firestore),
              );

              await notificationService.sendPaymentConfirmation(
                payment.studentId,
                studentEmail,
                payment.studentName,
                payment.amount,
                payment.month,
                payment.year,
              );
            }
          }
        }
      }

      emit(PaymentOperationSuccess(
        message:
            'Successfully marked ${event.payments.length} payments as paid',
      ));

      // Reload payments
      if (event.payments.isNotEmpty) {
        final payment = event.payments.first;
        add(LoadPaymentsByMonthEvent(
          month: payment.month,
          year: payment.year,
        ));
      }
    } catch (e) {
      emit(PaymentError(message: 'Failed to process payments: $e'));
    }
  }

  Future<void> _onCheckStudentPaymentStatus(
      CheckStudentPaymentStatusEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final hasOutstanding = await _paymentRepository.hasOutstandingPayments(
        event.studentId,
      );
      emit(StudentPaymentStatusChecked(
        hasOutstandingPayments: hasOutstanding,
        studentId: event.studentId,
      ));
    } catch (e) {
      emit(PaymentError(message: 'Failed to check payment status: $e'));
    }
  }

  Future<void> _onGetStudentPaymentStats(
      GetStudentPaymentStatsEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final stats = await _paymentRepository.getStudentPaymentStats(
        event.studentId,
      );
      emit(StudentPaymentStatsLoaded(
        stats: stats,
        studentId: event.studentId,
      ));
    } catch (e) {
      emit(PaymentError(message: 'Failed to load payment stats: $e'));
    }
  }

  Future<void> _onSendPaymentReminders(
      SendPaymentRemindersEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      await _paymentRepository.sendPaymentReminders(
        event.payments,
        event.message,
      );
      emit(PaymentOperationSuccess(
        message: 'Reminders sent to ${event.payments.length} students',
      ));
    } catch (e) {
      emit(PaymentError(message: 'Failed to send reminders: $e'));
    }
  }

  Future<void> _onSendAllUnpaidReminders(
      SendAllUnpaidRemindersEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      await _paymentRepository.sendAllUnpaidReminders(
        event.month,
        event.year,
        event.message,
      );

      emit(PaymentOperationSuccess(
        message: 'Reminders sent to all students with unpaid payments',
      ));

      // Reload payments
      add(LoadPaymentsByMonthEvent(month: event.month, year: event.year));
    } catch (e) {
      emit(PaymentError(message: 'Failed to send reminders: $e'));
    }
  }

  Future<void> _onLoadAllPaymentHistory(
      LoadAllPaymentHistoryEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final history = await _paymentRepository.getAllPaymentHistory();
      emit(AllPaymentHistoryLoaded(history: history));
    } catch (e) {
      emit(PaymentError(message: 'Failed to load payment history: $e'));
    }
  }

  Future<void> _onCreatePayment(
      CreatePaymentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      await _paymentRepository.createPayment(event.payment);
      emit(PaymentRecorded(
        payment: event.payment,
        message: 'Payment successfully recorded',
      ));
    } catch (e) {
      emit(PaymentError(message: 'Failed to create payment: $e'));
    }
  }
}
