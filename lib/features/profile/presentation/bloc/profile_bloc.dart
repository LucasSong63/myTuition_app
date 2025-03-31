import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/update_profile_picture_usecase.dart';
import '../../domain/usecases/remove_profile_picture_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final UpdateProfilePictureUseCase updateProfilePictureUseCase;
  final RemoveProfilePictureUseCase removeProfilePictureUseCase;

  ProfileBloc({
    required this.updateProfileUseCase,
    required this.updateProfilePictureUseCase,
    required this.removeProfilePictureUseCase,
  }) : super(ProfileInitial()) {
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfilePictureEvent>(_onUpdateProfilePicture);
    on<RemoveProfilePictureEvent>(_onRemoveProfilePicture);
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await updateProfileUseCase.execute(
        userId: event.userId,
        name: event.name,
        phone: event.phone,
      );
      emit(const ProfileUpdateSuccess(message: 'Profile updated successfully'));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfilePicture(
    UpdateProfilePictureEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await updateProfilePictureUseCase.execute(
        event.userId,
        event.imageFile,
      );
      emit(const ProfileUpdateSuccess(
          message: 'Profile picture updated successfully'));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onRemoveProfilePicture(
    RemoveProfilePictureEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await removeProfilePictureUseCase.execute(event.userId);
      emit(const ProfileUpdateSuccess(
          message: 'Profile picture removed successfully'));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
