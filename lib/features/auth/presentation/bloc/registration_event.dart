import 'package:equatable/equatable.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all pending registration requests
class LoadRegistrationsEvent extends RegistrationEvent {}

/// Event to load details of a specific registration request
class LoadRegistrationDetailsEvent extends RegistrationEvent {
  final String id;

  const LoadRegistrationDetailsEvent({required this.id});

  @override
  List<Object> get props => [id];
}

/// Event to approve a registration request
class ApproveRegistrationEvent extends RegistrationEvent {
  final String id;

  const ApproveRegistrationEvent({required this.id});

  @override
  List<Object> get props => [id];
}

/// Event to reject a registration request
class RejectRegistrationEvent extends RegistrationEvent {
  final String id;
  final String reason;

  const RejectRegistrationEvent({
    required this.id,
    required this.reason,
  });

  @override
  List<Object> get props => [id, reason];
}