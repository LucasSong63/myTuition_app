import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
    required bool isTutor,
  });

  Future<User> register({
    required String email,
    required String password,
    required String name,
    required bool isTutor,
    int? grade,
    List<String>? subjects,
  });

  Future<void> logout();

  Future<void> forgotPassword({required String email});

  Future<User?> getCurrentUser();

  Stream<User?> get authStateChanges;
}
