import '../repositories/task_repository.dart';

class MarkTaskAsCompletedUseCase {
  final TaskRepository repository;

  MarkTaskAsCompletedUseCase(this.repository);

  Future<void> execute(String taskId, String studentId, {String remarks = ''}) {
    return repository.markTaskAsCompleted(taskId, studentId, remarks: remarks);
  }
}
