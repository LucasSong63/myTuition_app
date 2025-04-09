import '../repositories/task_repository.dart';
import '../entities/student_task.dart';

class GetTaskCompletionStatusUseCase {
  final TaskRepository repository;

  GetTaskCompletionStatusUseCase(this.repository);

  Future<List<StudentTask>> execute(String taskId) {
    return repository.getTaskCompletionStatus(taskId);
  }
}
