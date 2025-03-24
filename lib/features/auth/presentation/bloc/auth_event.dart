import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final bool isTutor;

  const LoginEvent({
    required this.email,
    required this.password,
    required this.isTutor,
  });

  @override
  List<Object> get props => [email, password, isTutor];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final bool isTutor;
  final int? grade;
  final List<String>? subjects;

  const RegisterEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.isTutor,
    this.grade,
    this.subjects,
  });

  @override
  List<Object?> get props => [email, password, name, isTutor, grade, subjects];
}

class LogoutEvent extends AuthEvent {}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}
