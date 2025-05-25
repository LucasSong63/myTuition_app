// features/ai_chat/domain/repositories/chat_repository.dart
import 'package:mytuition/core/result/result.dart';

import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

abstract class ChatRepository {
  /// Send a message and get AI response
  Future<Result<ChatMessage>> sendMessage({
    required String sessionId,
    required String message,
    required String studentId,
  });

  /// Get chat session by ID
  Future<Result<ChatSession>> getChatSession(String sessionId);

  /// Create a new chat session
  Future<Result<ChatSession>> createChatSession(String studentId);

  /// Get all messages in a session
  Future<Result<List<ChatMessage>>> getSessionMessages(String sessionId);

  /// Get active session for student (or create new one)
  Future<Result<ChatSession>> getOrCreateActiveSession(String studentId);

  /// Archive old session and create new one
  Future<Result<ChatSession>> startNewSession(String studentId);

  /// Get archived (inactive) sessions for a student
  Future<Result<List<ChatSession>>> getArchivedSessions(String studentId);

  /// Reactivate an archived session
  Future<Result<ChatSession>> reactivateSession(
      String sessionId, String studentId);

  /// Delete a chat session permanently
  Future<Result<void>> deleteSession(String sessionId);
}
