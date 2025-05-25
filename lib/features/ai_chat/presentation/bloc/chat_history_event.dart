import 'package:equatable/equatable.dart';

abstract class ChatHistoryEvent extends Equatable {
  const ChatHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadArchivedSessionsEvent extends ChatHistoryEvent {
  final String studentId;

  const LoadArchivedSessionsEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

class ReactivateSessionEvent extends ChatHistoryEvent {
  final String sessionId;
  final String studentId;

  const ReactivateSessionEvent(this.sessionId, this.studentId);

  @override
  List<Object?> get props => [sessionId, studentId];
}

class DeleteSessionEvent extends ChatHistoryEvent {
  final String sessionId;

  const DeleteSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class RefreshHistoryEvent extends ChatHistoryEvent {
  final String studentId;

  const RefreshHistoryEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}
