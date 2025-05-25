import 'package:mytuition/core/result/result.dart';
import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

class StartNewSessionUseCase {
  final ChatRepository chatRepository;

  StartNewSessionUseCase(this.chatRepository);

  Future<Result<ChatSession>> call(String studentId) {
    return chatRepository.startNewSession(studentId);
  }
}
