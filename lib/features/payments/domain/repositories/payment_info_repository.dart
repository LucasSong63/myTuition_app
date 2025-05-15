// lib/features/payments/domain/repositories/payment_info_repository.dart

import '../entities/payment_info.dart';

abstract class PaymentInfoRepository {
  /// Get payment information for the tutor
  Future<PaymentInfo> getPaymentInfo();

  /// Save payment information for the tutor
  Future<void> savePaymentInfo(PaymentInfo paymentInfo);

  /// Add a bank account
  Future<void> addBankAccount(BankAccount bankAccount);

  /// Update a bank account
  Future<void> updateBankAccount(BankAccount bankAccount);

  /// Delete a bank account
  Future<void> deleteBankAccount(String accountId);

  /// Add an e-wallet
  Future<void> addEWallet(EWallet eWallet);

  /// Update an e-wallet
  Future<void> updateEWallet(EWallet eWallet);

  /// Delete an e-wallet
  Future<void> deleteEWallet(String walletId);

  /// Add another payment method
  Future<void> addOtherMethod(OtherPaymentMethod method);

  /// Update another payment method
  Future<void> updateOtherMethod(OtherPaymentMethod method);

  /// Delete another payment method
  Future<void> deleteOtherMethod(String methodId);

  /// Update additional payment information
  Future<void> updateAdditionalInfo(String additionalInfo);
}
