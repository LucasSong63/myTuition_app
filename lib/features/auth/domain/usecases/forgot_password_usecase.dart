import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<void> execute({required String email}) async {
    return await repository.forgotPassword(email: email);
  }
}
