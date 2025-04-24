import '../repositories/student_management_repository.dart';

class UpdateStudentProfileUseCase {
  final StudentManagementRepository repository;

  UpdateStudentProfileUseCase(this.repository);

  Future<void> execute({
    required String userId,
    String? name,
    String? phone,
    int? grade,
    List<String>? subjects,
  }) {
    return repository.updateStudentProfile(
      userId,
      name: name,
      phone: phone,
      grade: grade,
      subjects: subjects,
    );
  }
}
