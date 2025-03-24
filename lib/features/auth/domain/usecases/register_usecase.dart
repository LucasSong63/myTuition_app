import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> execute({
    required String email,
    required String password,
    required String name,
    bool isTutor = false,
    int? grade,
    List<String>? subjects,
  }) async {
    return await repository.register(
      email: email,
      password: password,
      name: name,
      isTutor: isTutor,
      grade: grade,
      subjects: subjects,
    );
  }
}
