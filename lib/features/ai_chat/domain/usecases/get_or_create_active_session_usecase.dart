import 'package:mytuition/core/result/result.dart';

import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';
import '../repositories/ai_usage_repository.dart';

class GetOrCreateActiveSessionUseCase {
  final ChatRepository chatRepository;
  final AIUsageRepository aiUsageRepository;

  GetOrCreateActiveSessionUseCase({
    required this.chatRepository,
    required this.aiUsageRepository,
  });

  Future<Result<ChatSession>> call(String studentId) async {
    // Reset daily count if needed
    await aiUsageRepository.resetDailyCountIfNeeded(studentId);

    // Get or create active session
    return chatRepository.getOrCreateActiveSession(studentId);
  }
}
