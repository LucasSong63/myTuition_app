import 'package:mytuition/core/result/result.dart';

import '../../domain/repositories/openai_repository.dart';
import '../datasources/remote/openai_service.dart';

class OpenAIRepositoryImpl implements OpenAIRepository {
  final OpenAIService openaiService;

  OpenAIRepositoryImpl(this.openaiService);

  @override
  Future<Result<String>> initializeAssistant() async {
    // Assistant initialization is handled automatically in OpenAIService
    return const Success('Assistant initialized');
  }

  @override
  Future<Result<String>> createThread() async {
    return openaiService.createThread();
  }

  @override
  Future<Result<String>> sendMessageToThread({
    required String threadId,
    required String message,
    required String assistantId,
  }) async {
    return openaiService.sendMessageToThread(
      threadId: threadId,
      message: message,
    );
  }

  @override
  Future<Result<String>> getAssistantId() async {
    // Assistant ID is managed internally by OpenAIService
    return const Success('assistant-id-managed-internally');
  }
}
