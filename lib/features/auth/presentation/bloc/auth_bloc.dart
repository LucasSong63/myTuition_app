import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  // final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required this.loginUseCase,
    // required this.logoutUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);

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
      emit(AuthError(message: 'Login failed: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await registerUseCase.execute(
        email: event.email,
        password: event.password,
        name: event.name,
        isTutor: event.isTutor,
        grade: event.grade,
        subjects: event.subjects,
      );
      emit(Authenticated(user: user, isTutor: user.isTutor));
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
      // await logoutUseCase.execute();

      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: ${e.toString()}'));
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

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
