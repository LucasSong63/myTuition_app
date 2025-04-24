import '../repositories/student_management_repository.dart';
import '../entities/student.dart';

class GetAllStudentsUseCase {
  final StudentManagementRepository repository;

  GetAllStudentsUseCase(this.repository);

  Future<List<Student>> execute() {
    return repository.getAllStudents();
  }
}
