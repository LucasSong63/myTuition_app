import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

// Config imports
import 'config/router/route_config.dart';
import 'config/theme/app_theme.dart';

// Core services import
import 'core/services/auth_state_observer.dart';

// Feature imports
import 'features/auth/data/datasources/remote/email_service.dart';
import 'features/auth/data/datasources/remote/firebase_auth_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/repositories/registration_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/registration_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/bloc/registration_bloc.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/submit_registration_usecase.dart';

// Profile features
import 'features/profile/data/datasources/remote/storage_service.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/update_profile_usecase.dart';
import 'features/profile/domain/usecases/update_profile_picture_usecase.dart';
import 'features/profile/domain/usecases/remove_profile_picture_usecase.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

// Firebase config
import 'firebase_option.dart';

// Get instance of GetIt
final getIt = GetIt.instance;

// Initialize dependencies
Future<void> initDependencies() async {
  // Core Services
  final authStateObserver = AuthStateObserver(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
  authStateObserver.initialize();

  // Firebase instances
  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  // Services
  getIt.registerLazySingleton(
    () => FirebaseAuthService(),
  );

  getIt.registerLazySingleton(
    () => EmailService(FirebaseFirestore.instance),
  );

  getIt.registerLazySingleton(
    () => StorageService(firebaseStorage),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<FirebaseAuthService>(),
      firestore,
    ),
  );

  getIt.registerLazySingleton<RegistrationRepository>(
    () => RegistrationRepositoryImpl(
      firestore,
      firebaseAuth,
      getIt<EmailService>(),
    ),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      firestore,
      getIt<StorageService>(),
    ),
  );

  // Auth use cases
  getIt.registerLazySingleton(
    () => LoginUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => RegisterUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => ForgotPasswordUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // Registration use case
  getIt.registerLazySingleton(
    () => SubmitRegistrationUseCase(getIt<RegistrationRepository>()),
  );

  // Profile use cases
  getIt.registerLazySingleton(
    () => UpdateProfileUseCase(getIt<ProfileRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateProfilePictureUseCase(getIt<ProfileRepository>()),
  );

  getIt.registerLazySingleton(
    () => RemoveProfilePictureUseCase(getIt<ProfileRepository>()),
  );

  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      forgotPasswordUseCase: getIt<ForgotPasswordUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      submitRegistrationUseCase: getIt<SubmitRegistrationUseCase>(),
    ),
  );

  // Registration BLoC
  getIt.registerFactory(
    () => RegistrationBloc(
      registrationRepository: getIt<RegistrationRepository>(),
    ),
  );

  // Profile BLoC
  getIt.registerFactory(
    () => ProfileBloc(
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      updateProfilePictureUseCase: getIt<UpdateProfilePictureUseCase>(),
      removeProfilePictureUseCase: getIt<RemoveProfilePictureUseCase>(),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization with additional error handling
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'myTuition_FYP', // Add a custom name
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app('myTuition_FYP'); // Use the named app
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  // Initialize dependency injection
  await initDependencies();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyTuitionApp());
}

class MyTuitionApp extends StatelessWidget {
  const MyTuitionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>(),
        ),
        // Other BLoCs can be added here as needed
      ],
      // Remove the BlocListener and just return the MaterialApp.router directly
      child: MaterialApp.router(
        title: 'myTuition',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // Default to light theme
        debugShowCheckedModeBanner: false,
        routerDelegate: AppRouter.router.routerDelegate,
        routeInformationParser: AppRouter.router.routeInformationParser,
        routeInformationProvider: AppRouter.router.routeInformationProvider,
      ),
    );
  }
}
