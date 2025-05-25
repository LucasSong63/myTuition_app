// features/ai_chat/domain/usecases/reactivate_session_usecase.dart

import 'package:mytuition/core/result/result.dart';

import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

class ReactivateSessionUseCase {
  final ChatRepository chatRepository;

  ReactivateSessionUseCase(this.chatRepository);

  Future<Result<ChatSession>> call(String sessionId, String studentId) {
    return chatRepository.reactivateSession(sessionId, studentId);
  }
}
