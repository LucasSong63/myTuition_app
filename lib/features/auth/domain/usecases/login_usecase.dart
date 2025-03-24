import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> execute({
    required String email,
    required String password,
    required bool isTutor,
  }) async {
    return await repository.login(
      email: email,
      password: password,
      isTutor: isTutor,
    );
  }
}
