import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_session.dart';

abstract class ChatHistoryState extends Equatable {
  const ChatHistoryState();

  @override
  List<Object?> get props => [];
}

class ChatHistoryInitial extends ChatHistoryState {}

class ChatHistoryLoading extends ChatHistoryState {}

class ChatHistoryLoaded extends ChatHistoryState {
  final List<ChatSession> archivedSessions;
  final bool isRefreshing;

  const ChatHistoryLoaded({
    required this.archivedSessions,
    this.isRefreshing = false,
  });

  ChatHistoryLoaded copyWith({
    List<ChatSession>? archivedSessions,
    bool? isRefreshing,
  }) {
    return ChatHistoryLoaded(
      archivedSessions: archivedSessions ?? this.archivedSessions,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [archivedSessions, isRefreshing];
}

class ChatHistoryError extends ChatHistoryState {
  final String message;

  const ChatHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class SessionReactivated extends ChatHistoryState {
  final ChatSession reactivatedSession;

  const SessionReactivated(this.reactivatedSession);

  @override
  List<Object?> get props => [reactivatedSession];
}

class SessionDeleted extends ChatHistoryState {
  final String deletedSessionId;

  const SessionDeleted(this.deletedSessionId);

  @override
  List<Object?> get props => [deletedSessionId];
}
