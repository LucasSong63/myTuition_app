// lib/features/payments/presentation/bloc/payment_info_state.dart

part of 'payment_info_bloc.dart';

abstract class PaymentInfoState extends Equatable {
  const PaymentInfoState();

  @override
  List<Object?> get props => [];
}

class PaymentInfoInitial extends PaymentInfoState {}

class PaymentInfoLoading extends PaymentInfoState {}

class PaymentInfoLoaded extends PaymentInfoState {
  final PaymentInfo paymentInfo;

  const PaymentInfoLoaded({
    required this.paymentInfo,
  });

  @override
  List<Object?> get props => [paymentInfo];
}

class PaymentInfoSaved extends PaymentInfoLoaded {
  final String message;

  const PaymentInfoSaved({
    required this.message,
    required PaymentInfo paymentInfo,
  }) : super(paymentInfo: paymentInfo);

  @override
  List<Object?> get props => [message, paymentInfo];
}

class PaymentInfoError extends PaymentInfoState {
  final String message;

  const PaymentInfoError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
