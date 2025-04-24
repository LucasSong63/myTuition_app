import '../repositories/student_management_repository.dart';
import '../entities/student.dart';

class GetStudentByIdUseCase {
  final StudentManagementRepository repository;

  GetStudentByIdUseCase(this.repository);

  Future<Student> execute(String studentId) {
    return repository.getStudentById(studentId);
  }
}
