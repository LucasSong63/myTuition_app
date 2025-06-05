// lib/features/profile/presentation/bloc/profile_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final String name;
  final String phone;

  const UpdateProfileEvent({
    required this.userId,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [userId, name, phone];
}

class UpdateProfilePictureEvent extends ProfileEvent {
  final String userId;
  final File imageFile;

  const UpdateProfilePictureEvent({
    required this.userId,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [userId, imageFile];
}

class RemoveProfilePictureEvent extends ProfileEvent {
  final String userId;

  const RemoveProfilePictureEvent({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}

class LoadProfileEvent extends ProfileEvent {
  final String userId;

  const LoadProfileEvent({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}
