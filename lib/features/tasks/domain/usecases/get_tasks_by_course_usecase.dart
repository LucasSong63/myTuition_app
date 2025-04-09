import '../repositories/task_repository.dart';
import '../entities/task.dart';

class GetTasksByCourseUseCase {
  final TaskRepository repository;

  GetTasksByCourseUseCase(this.repository);

  Future<List<Task>> execute(String courseId) {
    return repository.getTasksByCourse(courseId);
  }
}
