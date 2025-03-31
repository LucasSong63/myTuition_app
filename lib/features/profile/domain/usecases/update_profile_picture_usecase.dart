import 'dart:io';
import '../repositories/profile_repository.dart';

class UpdateProfilePictureUseCase {
  final ProfileRepository repository;

  UpdateProfilePictureUseCase(this.repository);

  Future<void> execute(String userId, File imageFile) async {
    return await repository.updateProfilePicture(userId, imageFile);
  }
}
