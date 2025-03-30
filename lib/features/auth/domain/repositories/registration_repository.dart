import '../../data/models/registration_model.dart';


abstract class RegistrationRepository {
  // Submit a new registration request
  Future<void> submitRegistration({
    required String email,
    required String password, // Will be used only when approved
    required String name,
    required String phone,
    required int grade,
    required List<String> subjects,
    required bool hasConsulted,
  });

  // Get all pending registration requests
  Stream<List<RegistrationRequest>> getPendingRegistrations();

  // Get details of a specific registration request
  Future<RegistrationRequest> getRegistrationById(String id);

  // Approve a registration request
  Future<void> approveRegistration(String id);

  // Reject a registration request
  Future<void> rejectRegistration(String id, String reason);

  // Check if an email is already registered or has a pending request
  Future<bool> isEmailAvailable(String email);
}