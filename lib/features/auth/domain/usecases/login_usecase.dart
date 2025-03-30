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
    try {
      return await repository.login(
        email: email,
        password: password,
        isTutor: isTutor,
      );
    } catch (e) {
      if (e.toString().contains('email_not_verified')) {
        // Handle this special case in your BLoC
        throw Exception('email_not_verified');
      }
      rethrow;
    }
  }
}