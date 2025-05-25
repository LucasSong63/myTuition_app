import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChatEvent extends ChatEvent {
  final String studentId;

  const InitializeChatEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

class SendMessageEvent extends ChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class LoadMessagesEvent extends ChatEvent {
  final String sessionId;

  const LoadMessagesEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class StartNewSessionEvent extends ChatEvent {
  final String studentId;

  const StartNewSessionEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

class CheckDailyLimitEvent extends ChatEvent {
  final String studentId;

  const CheckDailyLimitEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}
