import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  // Upload profile picture and return the download URL
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      final folderRef = _storage.ref().child('profile_pictures');
      final fileRef = folderRef.child('$userId.jpg');

      // Upload the file - using fileRef instead of storageRef
      final uploadTask = fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Delete a profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final storageRef = _storage.ref().child('profile_pictures/$userId.jpg');
      await storageRef.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete profile picture: $e');
    }
  }
}
