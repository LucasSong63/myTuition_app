import '../repositories/task_repository.dart';

class MarkTaskAsIncompleteUseCase {
  final TaskRepository repository;

  MarkTaskAsIncompleteUseCase(this.repository);

  Future<void> execute(String taskId, String studentId) {
    return repository.markTaskAsIncomplete(taskId, studentId);
  }
}
