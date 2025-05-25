import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/ai_usage.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatSession session;
  final List<ChatMessage> messages;
  final AIUsage aiUsage;
  final bool isSendingMessage;

  const ChatLoaded({
    required this.session,
    required this.messages,
    required this.aiUsage,
    this.isSendingMessage = false,
  });

  ChatLoaded copyWith({
    ChatSession? session,
    List<ChatMessage>? messages,
    AIUsage? aiUsage,
    bool? isSendingMessage,
  }) {
    return ChatLoaded(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      aiUsage: aiUsage ?? this.aiUsage,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }

  @override
  List<Object?> get props => [session, messages, aiUsage, isSendingMessage];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class DailyLimitReached extends ChatState {
  final ChatSession session;
  final List<ChatMessage> messages;
  final AIUsage aiUsage;

  const DailyLimitReached({
    required this.session,
    required this.messages,
    required this.aiUsage,
  });

  @override
  List<Object?> get props => [session, messages, aiUsage];
}
