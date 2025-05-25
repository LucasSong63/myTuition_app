// features/ai_chat/data/repositories/chat_repository_impl.dart
import 'package:mytuition/core/result/result.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/local/chat_local_datasource.dart';
import '../datasources/remote/openai_service.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDatasource localDatasource;
  final OpenAIService openaiService;

  ChatRepositoryImpl({
    required this.localDatasource,
    required this.openaiService,
  });

  @override
  Future<Result<ChatMessage>> sendMessage({
    required String sessionId,
    required String message,
    required String studentId,
  }) async {
    // Get the session to get OpenAI thread ID
    final sessionResult = await localDatasource.getChatSession(sessionId);

    return switch (sessionResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final session) => await _processMessage(session, message),
    };
  }

  Future<Result<ChatMessage>> _processMessage(
    ChatSessionModel session,
    String message,
  ) async {
    String threadId = session.openaiThreadId ?? '';

    // Create OpenAI thread if not exists
    if (threadId.isEmpty) {
      final threadResult = await openaiService.createThread();

      return switch (threadResult) {
        Error(message: final errorMessage) => Error(errorMessage),
        Success(data: final newThreadId) =>
          await _processWithThread(session, message, newThreadId),
      };
    } else {
      return await _processWithThread(session, message, threadId);
    }
  }

  Future<Result<ChatMessage>> _processWithThread(
    ChatSessionModel session,
    String message,
    String threadId,
  ) async {
    // Update session with thread ID if needed
    if (session.openaiThreadId != threadId) {
      final updatedSession = session.copyWith(openaiThreadId: threadId);
      await localDatasource.updateSession(updatedSession);
    }

    // Save user message to Firestore
    final userMessage = ChatMessageModel(
      id: '',
      // Will be set by Firestore
      sessionId: session.id,
      content: message,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );

    final savedUserMessageResult =
        await localDatasource.saveMessage(userMessage);

    return switch (savedUserMessageResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final savedUserMessage) =>
        await _getAIResponse(session, message, threadId),
    };
  }

  Future<Result<ChatMessage>> _getAIResponse(
    ChatSessionModel session,
    String message,
    String threadId,
  ) async {
    // Send to OpenAI and get response
    final aiResponseResult = await openaiService.sendMessageToThread(
      threadId: threadId,
      message: message,
    );

    return switch (aiResponseResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final aiResponse) =>
        await _saveAIResponse(session, aiResponse),
    };
  }

  Future<Result<ChatMessage>> _saveAIResponse(
    ChatSessionModel session,
    String aiResponse,
  ) async {
    // Save AI response to Firestore
    final assistantMessage = ChatMessageModel(
      id: '',
      // Will be set by Firestore
      sessionId: session.id,
      content: aiResponse,
      type: ChatMessageType.assistant,
      timestamp: DateTime.now(),
    );

    final savedAssistantMessageResult =
        await localDatasource.saveMessage(assistantMessage);

    return switch (savedAssistantMessageResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final savedAssistantMessage) =>
        await _updateSessionStats(session, savedAssistantMessage),
    };
  }

  Future<Result<ChatMessage>> _updateSessionStats(
    ChatSessionModel session,
    ChatMessageModel savedAssistantMessage,
  ) async {
    // Update session last active time and message count
    final updatedSession = session.copyWith(
      lastActive: DateTime.now(),
      messageCount: session.messageCount + 2, // User + Assistant messages
    );

    final updateResult = await localDatasource.updateSession(updatedSession);

    return switch (updateResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success() => Success(savedAssistantMessage),
    };
  }

  @override
  Future<Result<ChatSession>> getChatSession(String sessionId) async {
    return localDatasource.getChatSession(sessionId);
  }

  @override
  Future<Result<ChatSession>> createChatSession(String studentId) async {
    final now = DateTime.now();
    final session = ChatSessionModel(
      id: '',
      // Will be set by Firestore
      studentId: studentId,
      createdAt: now,
      lastActive: now,
      isActive: true,
    );

    return localDatasource.createChatSession(session);
  }

  @override
  Future<Result<List<ChatMessage>>> getSessionMessages(String sessionId) async {
    final result = await localDatasource.getSessionMessages(sessionId);

    return switch (result) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final messages) => Success(messages.cast<ChatMessage>()),
    };
  }

  @override
  Future<Result<ChatSession>> getOrCreateActiveSession(String studentId) async {
    // Try to get existing active session
    final existingSessionResult =
        await localDatasource.getActiveSession(studentId);

    return switch (existingSessionResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final existingSession) => existingSession != null
          ? Success(existingSession)
          : await createChatSession(studentId),
    };
  }

  @override
  Future<Result<ChatSession>> startNewSession(String studentId) async {
    // Deactivate existing sessions
    final existingSessionResult =
        await localDatasource.getActiveSession(studentId);

    if (existingSessionResult case Success(data: final existingSession)
        when existingSession != null) {
      final deactivatedSession = existingSession.copyWith(isActive: false);
      await localDatasource.updateSession(deactivatedSession);
    }

    // Create new active session
    return await createChatSession(studentId);
  }

  @override
  Future<Result<List<ChatSession>>> getArchivedSessions(
      String studentId) async {
    return localDatasource.getArchivedSessions(studentId);
  }

  @override
  Future<Result<ChatSession>> reactivateSession(
      String sessionId, String studentId) async {
    return localDatasource.reactivateSession(sessionId, studentId);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    return localDatasource.deleteSession(sessionId);
  }
}
