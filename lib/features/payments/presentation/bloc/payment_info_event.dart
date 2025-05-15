// lib/features/payments/presentation/bloc/payment_info_event.dart

part of 'payment_info_bloc.dart';

abstract class PaymentInfoEvent extends Equatable {
  const PaymentInfoEvent();

  @override
  List<Object> get props => [];
}

class LoadPaymentInfoEvent extends PaymentInfoEvent {}

class SavePaymentInfoEvent extends PaymentInfoEvent {
  final PaymentInfo paymentInfo;

  const SavePaymentInfoEvent({
    required this.paymentInfo,
  });

  @override
  List<Object> get props => [paymentInfo];
}

class AddBankAccountEvent extends PaymentInfoEvent {
  final BankAccount bankAccount;

  const AddBankAccountEvent({
    required this.bankAccount,
  });

  @override
  List<Object> get props => [bankAccount];
}

class UpdateBankAccountEvent extends PaymentInfoEvent {
  final BankAccount bankAccount;

  const UpdateBankAccountEvent({
    required this.bankAccount,
  });

  @override
  List<Object> get props => [bankAccount];
}

class DeleteBankAccountEvent extends PaymentInfoEvent {
  final String accountId;

  const DeleteBankAccountEvent({
    required this.accountId,
  });

  @override
  List<Object> get props => [accountId];
}

class AddEWalletEvent extends PaymentInfoEvent {
  final EWallet eWallet;

  const AddEWalletEvent({
    required this.eWallet,
  });

  @override
  List<Object> get props => [eWallet];
}

class UpdateEWalletEvent extends PaymentInfoEvent {
  final EWallet eWallet;

  const UpdateEWalletEvent({
    required this.eWallet,
  });

  @override
  List<Object> get props => [eWallet];
}

class DeleteEWalletEvent extends PaymentInfoEvent {
  final String walletId;

  const DeleteEWalletEvent({
    required this.walletId,
  });

  @override
  List<Object> get props => [walletId];
}

class AddOtherMethodEvent extends PaymentInfoEvent {
  final OtherPaymentMethod method;

  const AddOtherMethodEvent({
    required this.method,
  });

  @override
  List<Object> get props => [method];
}

class UpdateOtherMethodEvent extends PaymentInfoEvent {
  final OtherPaymentMethod method;

  const UpdateOtherMethodEvent({
    required this.method,
  });

  @override
  List<Object> get props => [method];
}

class DeleteOtherMethodEvent extends PaymentInfoEvent {
  final String methodId;

  const DeleteOtherMethodEvent({
    required this.methodId,
  });

  @override
  List<Object> get props => [methodId];
}

class UpdateAdditionalInfoEvent extends PaymentInfoEvent {
  final String additionalInfo;

  const UpdateAdditionalInfoEvent({
    required this.additionalInfo,
  });

  @override
  List<Object> get props => [additionalInfo];
}
