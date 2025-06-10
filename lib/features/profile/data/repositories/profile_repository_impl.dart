import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/features/auth/data/models/user_model.dart';
import 'package:mytuition/features/auth/domain/entities/user.dart';
import 'package:mytuition/features/profile/data/datasources/remote/storage_service.dart';
import 'package:mytuition/features/profile/domain/entities/student_payment_summary.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  ProfileRepositoryImpl(this._firestore, this._storageService);

  @override
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // Prepare update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;

      // Update the document
      await userDocRef.update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> updateProfilePicture(String userId, File imageFile) async {
    try {
      // Upload image to Firebase Storage
      final downloadUrl =
          await _storageService.uploadProfilePicture(userId, imageFile);

      // Update the profile picture URL in Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  @override
  Future<void> removeProfilePicture(String userId) async {
    try {
      // Delete from Firebase Storage
      await _storageService.deleteProfilePicture(userId);

      // Remove the URL from Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove profile picture: $e');
    }
  }

  @override
  Future<User> getProfile(String userId) async {
    try {
      final documentSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!documentSnapshot.exists) {
        throw Exception('User profile not found');
      }

      final data = documentSnapshot.data() as Map<String, dynamic>;

      return UserModel.fromMap({
        'id': userId,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<StudentPaymentSummary> getStudentPaymentSummary(
      String studentId) async {
    try {
      // Get outstanding payments (unpaid and partial)
      final outstandingPaymentsQuery = await _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: ['unpaid', 'partial'])
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      double totalOutstanding = 0;
      int unpaidCount = 0;
      int partialCount = 0;
      List<OutstandingPayment> outstandingPayments = [];

      for (var doc in outstandingPaymentsQuery.docs) {
        final data = doc.data();
        final totalAmount = (data['amount'] ?? 0).toDouble();
        final amountPaid = (data['amountPaid'] ?? 0).toDouble();
        final discount = (data['discount'] ?? 0).toDouble();

        // Calculate outstanding amount
        final outstandingAmount = totalAmount - amountPaid - discount;

        if (outstandingAmount > 0) {
          totalOutstanding += outstandingAmount;

          final status = data['status'] as String;
          if (status == 'unpaid') {
            unpaidCount++;
          } else if (status == 'partial') {
            partialCount++;
          }

          outstandingPayments.add(OutstandingPayment(
            id: doc.id,
            studentId: data['studentId'] ?? '',
            month: data['month'] ?? 0,
            year: data['year'] ?? 0,
            totalAmount: totalAmount,
            amountPaid: amountPaid,
            outstandingAmount: outstandingAmount,
            status: status,
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ));
        }
      }

      // Get recent payment transactions (last 10)
      final recentTransactionsQuery = await _firestore
          .collection('payment_history')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      List<RecentPaymentTransaction> recentTransactions = [];

      for (var doc in recentTransactionsQuery.docs) {
        final data = doc.data();
        recentTransactions.add(RecentPaymentTransaction(
          id: doc.id,
          paymentId: data['paymentId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          discount: (data['discount'] ?? 0).toDouble(),
          status: data['newStatus'] ?? '',
          date: data['date'] != null
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
          remarks: data['remarks'],
          month: data['month'] ?? 0,
          year: data['year'] ?? 0,
        ));
      }

      return StudentPaymentSummary(
        totalOutstanding: totalOutstanding,
        unpaidCount: unpaidCount,
        partialCount: partialCount,
        outstandingPayments: outstandingPayments,
        recentTransactions: recentTransactions,
      );
    } catch (e) {
      throw Exception('Failed to get student payment summary: $e');
    }
  }
}
