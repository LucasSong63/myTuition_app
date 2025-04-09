import '../repositories/task_repository.dart';
import '../entities/task.dart';

class GetTasksForStudentUseCase {
  final TaskRepository repository;

  GetTasksForStudentUseCase(this.repository);

  Future<List<Task>> execute(String studentId) {
    return repository.getTasksForStudent(studentId);
  }
}
