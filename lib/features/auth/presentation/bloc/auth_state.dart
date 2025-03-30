import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final bool isTutor;

  const Authenticated({
    required this.user,
    required this.isTutor,
  });

  @override
  List<Object> get props => [user, isTutor];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class PasswordResetSent extends AuthState {}

// State when a user tries to log in but their registration is pending
class RegistrationPending extends AuthState {
  final String message;

  const RegistrationPending({required this.message});

  @override
  List<Object> get props => [message];
}

// New states for registration
class RegistrationSubmitted extends AuthState {
  final String email;

  const RegistrationSubmitted({required this.email});

  @override
  List<Object> get props => [email];
}

class RegistrationApproved extends AuthState {
  final User user;

  const RegistrationApproved({required this.user});

  @override
  List<Object> get props => [user];
}

class RegistrationRejected extends AuthState {
  final String reason;

  const RegistrationRejected({required this.reason});

  @override
  List<Object> get props => [reason];
}

class EmailVerificationRequired extends AuthState {
  final String email;

  const EmailVerificationRequired({required this.email});

  @override
  List<Object> get props => [email];
}

class EmailVerificationSent extends AuthState {
  const EmailVerificationSent();
}