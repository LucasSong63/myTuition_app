import 'package:mytuition/core/result/result.dart';

abstract class OpenAIRepository {
  /// Initialize OpenAI assistant (if not exists)
  Future<Result<String>> initializeAssistant();

  /// Create a new conversation thread
  Future<Result<String>> createThread();

  /// Send message to OpenAI and get response
  Future<Result<String>> sendMessageToThread({
    required String threadId,
    required String message,
    required String assistantId,
  });

  /// Get assistant ID from Remote Config
  Future<Result<String>> getAssistantId();
}
