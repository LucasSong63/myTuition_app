import 'package:mytuition/core/result/result.dart';

import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/ai_usage_repository.dart';

class SendMessageUseCase {
  final ChatRepository chatRepository;
  final AIUsageRepository aiUsageRepository;

  SendMessageUseCase({
    required this.chatRepository,
    required this.aiUsageRepository,
  });

  Future<Result<ChatMessage>> call({
    required String sessionId,
    required String message,
    required String studentId,
  }) async {
    // Check if student can send more messages today
    final canSendResult = await aiUsageRepository.canSendMessage(studentId);

    return switch (canSendResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final canSend) =>
        await _processMessage(canSend, sessionId, message, studentId),
    };
  }

  Future<Result<ChatMessage>> _processMessage(
    bool canSend,
    String sessionId,
    String message,
    String studentId,
  ) async {
    if (!canSend) {
      return const Error(
          'You have reached your daily question limit of 20 questions. Please try again tomorrow!');
    }

    // Send message and get response
    final result = await chatRepository.sendMessage(
      sessionId: sessionId,
      message: message,
      studentId: studentId,
    );

    // If successful, increment usage count
    return switch (result) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final response) =>
        await _incrementUsageAndReturn(response, studentId),
    };
  }

  Future<Result<ChatMessage>> _incrementUsageAndReturn(
    ChatMessage response,
    String studentId,
  ) async {
    await aiUsageRepository.incrementUsage(studentId);
    return Success(response);
  }
}
