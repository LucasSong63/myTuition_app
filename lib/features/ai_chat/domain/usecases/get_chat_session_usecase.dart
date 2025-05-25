import 'package:mytuition/core/result/result.dart';

import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

class GetChatSessionUseCase {
  final ChatRepository chatRepository;

  GetChatSessionUseCase(this.chatRepository);

  Future<Result<ChatSession>> call(String sessionId) {
    return chatRepository.getChatSession(sessionId);
  }
}
