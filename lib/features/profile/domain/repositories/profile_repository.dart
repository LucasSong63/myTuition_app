import 'dart:io';

import 'package:mytuition/features/auth/domain/entities/user.dart';
import '../entities/student_payment_summary.dart';

abstract class ProfileRepository {
  // Update user's profile information
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
  });

  // Update profile picture
  Future<void> updateProfilePicture(String userId, File imageFile);

  // Remove profile picture
  Future<void> removeProfilePicture(String userId);

  // Get full profile data
  Future<User> getProfile(String userId);

  // Get student payment summary with outstanding amounts and recent transactions
  Future<StudentPaymentSummary> getStudentPaymentSummary(String studentId);
}
