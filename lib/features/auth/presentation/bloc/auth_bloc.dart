import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/auth/data/models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/submit_registration_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SubmitRegistrationUseCase submitRegistrationUseCase;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.getCurrentUserUseCase,
    required this.submitRegistrationUseCase,
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResendVerificationEmailEvent>(_onResendVerificationEmail);
    on<CheckEmailVerificationEvent>(_onCheckEmailVerification);

    // Check auth status when bloc is created
    add(CheckAuthStatusEvent());
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final User? user = await getCurrentUserUseCase.execute();
      if (user != null) {
        // Check if the email is verified for student users
        if (!user.isTutor) {
          final currentUser = _firebaseAuth.currentUser;
          if (currentUser != null && !currentUser.emailVerified) {
            emit(EmailVerificationRequired(email: user.email));
            return;
          }
        }
        emit(Authenticated(user: user, isTutor: user.isTutor));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(
      LoginEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase.execute(
        email: event.email,
        password: event.password,
        isTutor: event.isTutor,
      );
      emit(Authenticated(user: user, isTutor: user.isTutor));
    } catch (e) {
      // Check for special error messages
      if (e.toString().contains('email_not_verified')) {
        emit(EmailVerificationRequired(email: event.email));
      } else if (e.toString().contains('pending approval')) {
        emit(RegistrationPending(message: e.toString()));
      } else {
        emit(AuthError(message: 'Login failed: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRegister(
      RegisterEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      // If this is a tutor registration, use the normal registration flow
      if (event.isTutor) {
        final user = await registerUseCase.execute(
          email: event.email,
          password: event.password,
          name: event.name,
          isTutor: event.isTutor,
          grade: event.grade,
          subjects: event.subjects,
        );
        emit(Authenticated(user: user, isTutor: user.isTutor));
      }
      // For student registrations, use the pending approval flow
      else {
        await submitRegistrationUseCase.execute(
          email: event.email,
          password: event.password,
          name: event.name,
          phone: event.phone,
          grade: event.grade ?? 1,
          subjects: event.subjects ?? [],
          hasConsulted: event.hasConsulted,
        );

        // Emit state for pending approval
        emit(RegistrationSubmitted(email: event.email));

        // Return to unauthenticated after showing success message
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Registration failed: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogout(
      LogoutEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await logoutUseCase.execute();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: ${e.toString()}'));
      // Since logout failed, we need to check current auth status
      add(CheckAuthStatusEvent());
    }
  }

  Future<void> _onForgotPassword(
      ForgotPasswordEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await forgotPasswordUseCase.execute(email: event.email);
      emit(PasswordResetSent());
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Password reset failed: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onResendVerificationEmail(
      ResendVerificationEmailEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      // Get current user
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser != null && currentUser.email == event.email) {
        await currentUser.sendEmailVerification();
        emit(const EmailVerificationSent());
      } else {
        // This is a tricky case since we need the user to be logged in
        // We might need to adjust the flow for this case
        emit(AuthError(message: 'You need to be logged in to resend verification email'));
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to resend verification email: ${e.toString()}'));
    }
  }

  Future<void> _onCheckEmailVerification(
      CheckEmailVerificationEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      // Get current user
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser != null && currentUser.email == event.email) {
        // Reload user to get latest verification status
        await currentUser.reload();

        if (currentUser.emailVerified) {
          // Get user data from Firestore
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;

            // Update Firestore with verified status
            await _firestore.collection('users').doc(currentUser.uid).update({
              'emailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Emit authenticated state
            final user = UserModel.fromMap({
              'id': currentUser.uid,
              'email': currentUser.email ?? '',
              ...userData,
              'emailVerified': true,
            });

            emit(Authenticated(user: user, isTutor: user.role == 'tutor'));
          } else {
            emit(AuthError(message: 'User profile not found'));
            emit(Unauthenticated());
          }
        } else {
          // Explicitly emit EmailVerificationRequired state when not verified
          emit(EmailVerificationRequired(email: event.email));
        }
      } else {
        emit(AuthError(message: 'User not logged in or email mismatch'));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to check verification status: ${e.toString()}'));
      // Don't emit Unauthenticated here, so the user stays on the verification page
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}