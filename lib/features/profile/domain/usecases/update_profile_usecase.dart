
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<void> execute({
    required String userId,
    String? name,
    String? phone,
  }) async {
    return await repository.updateProfile(
      userId: userId,
      name: name,
      phone: phone,
    );
  }
}