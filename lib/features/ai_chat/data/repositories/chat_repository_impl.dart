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
    // IMPORTANT: Always get fresh session data to ensure we have the latest thread ID
    final freshSessionResult = await localDatasource.getChatSession(session.id);
    final freshSession = switch (freshSessionResult) {
      Error() => session,
      Success(data: final s) => s,
    };
    
    String threadId = freshSession.openaiThreadId ?? '';

    print('\n=== PROCESS MESSAGE ===');
    print('Session ID: ${freshSession.id}');
    print('Current thread ID: ${threadId.isEmpty ? "NONE - WILL CREATE NEW" : threadId}');
    print('Message count: ${freshSession.messageCount}');
    print('======================\n');

    // Create OpenAI thread if not exists
    if (threadId.isEmpty) {
      print('Creating new OpenAI thread for session...');
      final threadResult = await openaiService.createThread();

      return switch (threadResult) {
        Error(message: final errorMessage) => Error(errorMessage),
        Success(data: final newThreadId) =>
          await _processWithThread(freshSession, message, newThreadId),
      };
    } else {
      print('Using existing thread: $threadId');
      return await _processWithThread(freshSession, message, threadId);
    }
  }

  Future<Result<ChatMessage>> _processWithThread(
    ChatSessionModel session,
    String message,
    String threadId,
  ) async {
    // Update session with thread ID if needed
    if (session.openaiThreadId != threadId) {
      print('\n=== UPDATING SESSION WITH THREAD ID ===');
      print('Session ID: ${session.id}');
      print('New Thread ID: $threadId');
      
      final updatedSession = session.copyWith(openaiThreadId: threadId);
      final updateResult = await localDatasource.updateSession(updatedSession);
      
      if (updateResult case Error(message: final errorMessage)) {
        print('Failed to update session with thread ID: $errorMessage');
        return Error(errorMessage);
      }
      
      print('Session updated successfully with thread ID');
      print('=================================\n');
      
      // Use updated session for further processing
      session = updatedSession;
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
      Error(message: final errorMessage) => 
        await _handleThreadError(errorMessage, session, message),
      Success(data: final aiResponse) =>
        await _saveAIResponse(session, aiResponse),
    };
  }

  Future<Result<ChatMessage>> _handleThreadError(
    String errorMessage,
    ChatSessionModel session,
    String message,
  ) async {
    // Check if it's a thread not found error (expired or deleted)
    if (errorMessage.contains('No thread found') || 
        errorMessage.contains('thread_') ||
        errorMessage.contains('404')) {
      
      print('Thread expired or not found, creating new thread...');
      
      // Create new thread
      final newThreadResult = await openaiService.createThread();
      
      return switch (newThreadResult) {
        Error(message: final error) => Error(error),
        Success(data: final newThreadId) => 
          await _processWithThread(session, message, newThreadId),
      };
    }
    
    // For other errors, return as is
    return Error(errorMessage);
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
    // First reactivate the session in Firestore
    final reactivateResult = await localDatasource.reactivateSession(sessionId, studentId);
    
    return switch (reactivateResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final session) => await _ensureThreadHasHistory(session),
    };
  }
  
  Future<Result<ChatSession>> _ensureThreadHasHistory(ChatSessionModel session) async {
    // Check if thread exists and is valid
    String threadId = session.openaiThreadId ?? '';
    
    if (threadId.isEmpty) {
      // Create new thread and sync messages
      final threadResult = await openaiService.createThread();
      
      return switch (threadResult) {
        Error(message: final errorMessage) => Error(errorMessage),
        Success(data: final newThreadId) => await _syncMessagesToThread(session, newThreadId),
      };
    }
    
    // Thread exists, but we should still sync messages in case thread was lost
    // OpenAI threads can expire after inactivity
    return await _syncMessagesToThread(session, threadId);
  }
  
  Future<Result<ChatSession>> _syncMessagesToThread(
    ChatSessionModel session, 
    String threadId
  ) async {
    // Get all messages from Firestore
    final messagesResult = await localDatasource.getSessionMessages(session.id);
    
    if (messagesResult case Success(data: final messages)) {
      // If there are existing messages, we need to recreate the thread with history
      if (messages.isNotEmpty) {
        // Create a new thread since we can't add old messages to existing thread
        final newThreadResult = await openaiService.createThread();
        
        if (newThreadResult case Success(data: final newThreadId)) {
          // Update session with new thread ID
          final updatedSession = session.copyWith(openaiThreadId: newThreadId);
          await localDatasource.updateSession(updatedSession);
          
          return Success(updatedSession);
        }
      }
    }
    
    // Update session with thread ID if not already set
    if (session.openaiThreadId != threadId) {
      final updatedSession = session.copyWith(openaiThreadId: threadId);
      await localDatasource.updateSession(updatedSession);
      return Success(updatedSession);
    }
    
    return Success(session);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    return localDatasource.deleteSession(sessionId);
  }
}
