import 'package:equatable/equatable.dart';
import '../../data/models/registration_model.dart';

abstract class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RegistrationInitial extends RegistrationState {}

/// Loading state for registration operations
class RegistrationLoading extends RegistrationState {}

/// State when registration requests are loaded
class RegistrationsLoaded extends RegistrationState {
  final List<RegistrationRequest> registrations;

  const RegistrationsLoaded({required this.registrations});

  @override
  List<Object> get props => [registrations];
}

/// State when a single registration's details are loaded
class RegistrationDetailsLoaded extends RegistrationState {
  final RegistrationRequest registration;

  const RegistrationDetailsLoaded({required this.registration});

  @override
  List<Object> get props => [registration];
}

/// State after a successful registration action (approve/reject)
class RegistrationActionSuccess extends RegistrationState {
  final String message;

  const RegistrationActionSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

/// Error state for registration operations
class RegistrationError extends RegistrationState {
  final String message;

  const RegistrationError({required this.message});

  @override
  List<Object> get props => [message];
}