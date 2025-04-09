import '../repositories/task_repository.dart';

class AddTaskRemarksUseCase {
  final TaskRepository repository;

  AddTaskRemarksUseCase(this.repository);

  Future<void> execute(String taskId, String studentId, String remarks) {
    return repository.addTaskRemarks(taskId, studentId, remarks);
  }
}
