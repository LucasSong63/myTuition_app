// lib/features/payments/data/repositories/payment_info_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';
import 'package:mytuition/features/payments/domain/repositories/payment_info_repository.dart';
import 'package:uuid/uuid.dart';

class PaymentInfoRepositoryImpl implements PaymentInfoRepository {
  final FirebaseFirestore _firestore;
  final String _tutorId;
  final Uuid _uuid = const Uuid();

  PaymentInfoRepositoryImpl(this._firestore, this._tutorId);

  @override
  Future<PaymentInfo> getPaymentInfo() async {
    try {
      final docRef = _firestore.collection('payment_info').doc(_tutorId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // If no document exists, create an empty one
        await docRef.set({
          'bankAccounts': [],
          'eWallets': [],
          'otherMethods': [],
          'additionalInfo': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return const PaymentInfo();
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      return PaymentInfo.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get payment information: $e');
    }
  }

  @override
  Future<void> savePaymentInfo(PaymentInfo paymentInfo) async {
    try {
      await _firestore.collection('payment_info').doc(_tutorId).set({
        ...paymentInfo.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save payment information: $e');
    }
  }

  @override
  Future<void> addBankAccount(BankAccount bankAccount) async {
    try {
      // Generate a new ID if not provided
      final String accountId =
          bankAccount.id.isEmpty ? _uuid.v4() : bankAccount.id;
      final updatedAccount = bankAccount.copyWith(id: accountId);

      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Add new bank account
      final updatedAccounts = [...paymentInfo.bankAccounts, updatedAccount];

      // Save updated payment info
      await savePaymentInfo(
          paymentInfo.copyWith(bankAccounts: updatedAccounts));
    } catch (e) {
      throw Exception('Failed to add bank account: $e');
    }
  }

  @override
  Future<void> updateBankAccount(BankAccount bankAccount) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Find and update the bank account
      final updatedAccounts = paymentInfo.bankAccounts.map((account) {
        return account.id == bankAccount.id ? bankAccount : account;
      }).toList();

      // Save updated payment info
      await savePaymentInfo(
          paymentInfo.copyWith(bankAccounts: updatedAccounts));
    } catch (e) {
      throw Exception('Failed to update bank account: $e');
    }
  }

  @override
  Future<void> deleteBankAccount(String accountId) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Remove the bank account
      final updatedAccounts = paymentInfo.bankAccounts
          .where((account) => account.id != accountId)
          .toList();

      // Save updated payment info
      await savePaymentInfo(
          paymentInfo.copyWith(bankAccounts: updatedAccounts));
    } catch (e) {
      throw Exception('Failed to delete bank account: $e');
    }
  }

  @override
  Future<void> addEWallet(EWallet eWallet) async {
    try {
      // Generate a new ID if not provided
      final String walletId = eWallet.id.isEmpty ? _uuid.v4() : eWallet.id;
      final updatedWallet = eWallet.copyWith(id: walletId);

      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Add new e-wallet
      final updatedWallets = [...paymentInfo.eWallets, updatedWallet];

      // Save updated payment info
      await savePaymentInfo(paymentInfo.copyWith(eWallets: updatedWallets));
    } catch (e) {
      throw Exception('Failed to add e-wallet: $e');
    }
  }

  @override
  Future<void> updateEWallet(EWallet eWallet) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Find and update the e-wallet
      final updatedWallets = paymentInfo.eWallets.map((wallet) {
        return wallet.id == eWallet.id ? eWallet : wallet;
      }).toList();

      // Save updated payment info
      await savePaymentInfo(paymentInfo.copyWith(eWallets: updatedWallets));
    } catch (e) {
      throw Exception('Failed to update e-wallet: $e');
    }
  }

  @override
  Future<void> deleteEWallet(String walletId) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Remove the e-wallet
      final updatedWallets = paymentInfo.eWallets
          .where((wallet) => wallet.id != walletId)
          .toList();

      // Save updated payment info
      await savePaymentInfo(paymentInfo.copyWith(eWallets: updatedWallets));
    } catch (e) {
      throw Exception('Failed to delete e-wallet: $e');
    }
  }

  @override
  Future<void> addOtherMethod(OtherPaymentMethod method) async {
    try {
      // Generate a new ID if not provided
      final String methodId = method.id.isEmpty ? _uuid.v4() : method.id;
      final updatedMethod = method.copyWith(id: methodId);

      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Add new payment method
      final updatedMethods = [...paymentInfo.otherMethods, updatedMethod];

      // Save updated payment info
      await savePaymentInfo(paymentInfo.copyWith(otherMethods: updatedMethods));
    } catch (e) {
      throw Exception('Failed to add other payment method: $e');
    }
  }

  @override
  Future<void> updateOtherMethod(OtherPaymentMethod method) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Find and update the payment method
      final updatedMethods = paymentInfo.otherMethods.map((m) {
        return m.id == method.id ? method : m;
      }).toList();

      // Save updated payment info
      await savePaymentInfo(paymentInfo.copyWith(otherMethods: updatedMethods));
    } catch (e) {
      throw Exception('Failed to update other payment method: $e');
    }
  }

  @override
  Future<void> deleteOtherMethod(String methodId) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Remove the payment method
      final updatedMethods = paymentInfo.otherMethods
          .where((method) => method.id != methodId)
          .toList();

      // Save updated payment info
      await savePaymentInfo(paymentInfo.copyWith(otherMethods: updatedMethods));
    } catch (e) {
      throw Exception('Failed to delete other payment method: $e');
    }
  }

  @override
  Future<void> updateAdditionalInfo(String additionalInfo) async {
    try {
      // Get current payment info
      final paymentInfo = await getPaymentInfo();

      // Save updated payment info
      await savePaymentInfo(
          paymentInfo.copyWith(additionalInfo: additionalInfo));
    } catch (e) {
      throw Exception('Failed to update additional information: $e');
    }
  }
}
