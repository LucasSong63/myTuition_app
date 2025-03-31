import '../repositories/profile_repository.dart';

class RemoveProfilePictureUseCase {
  final ProfileRepository repository;

  RemoveProfilePictureUseCase(this.repository);

  Future<void> execute(String userId) async {
    return await repository.removeProfilePicture(userId);
  }
}
