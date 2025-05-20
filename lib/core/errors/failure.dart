// lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final Exception? originalException;

  const Failure({
    required this.message,
    this.originalException,
  });

  @override
  List<Object?> get props => [message, originalException];
}

/// Failure related to network operations
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Failure related to server errors
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Failure related to cache operations
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Failure related to notification operations
class NotificationFailure extends Failure {
  const NotificationFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Failure related to authentication
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Failure related to payment operations
class PaymentFailure extends Failure {
  const PaymentFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Failure related to task operations
class TaskFailure extends Failure {
  const TaskFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}

/// Generic validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    Exception? originalException,
  }) : super(
          message: message,
          originalException: originalException,
        );
}
