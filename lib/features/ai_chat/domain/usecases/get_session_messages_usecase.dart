import 'package:mytuition/core/result/result.dart';

import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetSessionMessagesUseCase {
  final ChatRepository chatRepository;

  GetSessionMessagesUseCase(this.chatRepository);

  Future<Result<List<ChatMessage>>> call(String sessionId) {
    return chatRepository.getSessionMessages(sessionId);
  }
}
