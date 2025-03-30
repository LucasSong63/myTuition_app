import '../repositories/registration_repository.dart';

class SubmitRegistrationUseCase {
  final RegistrationRepository repository;

  SubmitRegistrationUseCase(this.repository);

  Future<void> execute({
    required String email,
    required String password,
    required String name,
    required String phone,
    required int grade,
    required List<String> subjects,
    required bool hasConsulted,
  }) async {
    return await repository.submitRegistration(
      email: email,
      password: password,
      name: name,
      phone: phone,
      grade: grade,
      subjects: subjects,
      hasConsulted: hasConsulted,
    );
  }
}