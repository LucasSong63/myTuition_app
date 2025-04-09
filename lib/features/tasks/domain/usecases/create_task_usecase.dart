import '../repositories/task_repository.dart';
import '../entities/task.dart';

class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<Task> execute(
      String courseId, String title, String description, DateTime? dueDate) {
    return repository.createTask(courseId, title, description, dueDate);
  }
}
