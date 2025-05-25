// features/ai_chat/domain/usecases/delete_session_usecase.dart

import 'package:mytuition/core/result/result.dart';

import '../repositories/chat_repository.dart';

class DeleteSessionUseCase {
  final ChatRepository chatRepository;

  DeleteSessionUseCase(this.chatRepository);

  Future<Result<void>> call(String sessionId) {
    return chatRepository.deleteSession(sessionId);
  }
}
