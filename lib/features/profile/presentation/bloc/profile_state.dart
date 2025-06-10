// lib/features/profile/presentation/bloc/profile_state.dart

import 'package:equatable/equatable.dart';
import 'package:mytuition/features/auth/domain/entities/user.dart';
import 'package:mytuition/features/profile/domain/entities/student_payment_summary.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;

  const ProfileLoaded({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class ProfileUpdateSuccess extends ProfileState {
  final String message;

  const ProfileUpdateSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class StudentPaymentSummaryLoading extends ProfileState {}

class StudentPaymentSummaryLoaded extends ProfileState {
  final StudentPaymentSummary paymentSummary;

  const StudentPaymentSummaryLoaded({
    required this.paymentSummary,
  });

  @override
  List<Object?> get props => [paymentSummary];
}

class StudentPaymentSummaryError extends ProfileState {
  final String message;

  const StudentPaymentSummaryError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
