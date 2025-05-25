import 'package:mytuition/core/result/result.dart';

import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

class GetArchivedSessionsUseCase {
  final ChatRepository chatRepository;

  GetArchivedSessionsUseCase(this.chatRepository);

  Future<Result<List<ChatSession>>> call(String studentId) {
    return chatRepository.getArchivedSessions(studentId);
  }
}
