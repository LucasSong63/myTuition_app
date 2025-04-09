import '../repositories/task_repository.dart';
import '../entities/student_task.dart';

class GetStudentTaskUseCase {
  final TaskRepository repository;

  GetStudentTaskUseCase(this.repository);

  Future<StudentTask?> execute(String taskId, String studentId) {
    return repository.getStudentTask(taskId, studentId);
  }
}
