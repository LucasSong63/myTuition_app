import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/features/auth/data/models/user_model.dart';
import 'package:mytuition/features/auth/domain/entities/user.dart';
import 'package:mytuition/features/profile/data/datasources/remote/storage_service.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  ProfileRepositoryImpl(this._firestore, this._storageService);

  @override
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // Prepare update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;

      // Update the document
      await userDocRef.update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> updateProfilePicture(String userId, File imageFile) async {
    try {
      // Upload image to Firebase Storage
      final downloadUrl =
          await _storageService.uploadProfilePicture(userId, imageFile);

      // Update the profile picture URL in Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  @override
  Future<void> removeProfilePicture(String userId) async {
    try {
      // Delete from Firebase Storage
      await _storageService.deleteProfilePicture(userId);

      // Remove the URL from Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove profile picture: $e');
    }
  }

  @override
  Future<User> getProfile(String userId) async {
    try {
      final documentSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!documentSnapshot.exists) {
        throw Exception('User profile not found');
      }

      final data = documentSnapshot.data() as Map<String, dynamic>;

      return UserModel.fromMap({
        'id': userId,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }
}
