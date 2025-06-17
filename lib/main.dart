import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/core/services/fcm_service.dart';
import 'package:mytuition/features/attendance/domain/usecases/check_schedule_attendance_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_course_schedules_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_past_seven_days_attendance_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_schedule_attendance_status_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/update_attendance_usecase.dart';
import 'package:mytuition/features/profile/domain/usecases/get_student_payment_summary_usecase.dart';
import 'package:mytuition/features/student_dashboard/data/repositories/student_dashboard_repository_impl.dart';
import 'package:mytuition/features/student_dashboard/domain/repositories/student_dashboard_repository.dart';
import 'package:mytuition/features/student_dashboard/domain/usecases/get_student_dashboard_stats_usecase.dart';
import 'package:mytuition/features/student_dashboard/presentation/bloc/student_dashboard_bloc.dart';
import 'package:mytuition/features/tutor_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mytuition/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sizer/sizer.dart'; // Added Sizer import
import 'package:mytuition/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:mytuition/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_attendance_by_date_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_course_attendance_stats_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_enrolled_students_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/get_student_attendance_usecase.dart';
import 'package:mytuition/features/attendance/domain/usecases/record_bulk_attendance_usecase.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mytuition/features/courses/data/repositories/course_repository_impl.dart';
import 'package:mytuition/features/courses/data/repositories/subject_cost_repository_impl.dart';
import 'package:mytuition/features/courses/domain/repositories/course_repository.dart';
import 'package:mytuition/features/courses/domain/repositories/subject_cost_repository.dart';
import 'package:mytuition/features/courses/domain/usecases/add_schedule_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/delete_schedule_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/get_course_by_id_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/get_enrolled_courses_usecase.dart'
    as courses_get_enrolled_courses_usecase;
import 'package:mytuition/features/courses/domain/usecases/get_upcoming_schedules_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/update_course_active_status_usecase.dart';
import 'package:mytuition/features/courses/domain/usecases/update_course_capacity_usecase.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/subject_cost_bloc.dart';
import 'package:mytuition/features/notifications/data/services/notifications_service.dart';
import 'package:mytuition/features/payments/data/repositories/payment_info_repository_impl.dart';
import 'package:mytuition/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:mytuition/features/payments/domain/repositories/payment_info_repository.dart';
import 'package:mytuition/features/payments/domain/repositories/payment_repository.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:http/http.dart' as http;

// Student Management imports
import 'features/student_management/data/repositories/student_management_repository_impl.dart';
import 'features/student_management/domain/repositories/student_management_repository.dart';
import 'features/student_management/domain/usecases/get_all_students_usecase.dart';
import 'features/student_management/domain/usecases/get_student_by_id_usecase.dart';
import 'features/student_management/domain/usecases/get_enrolled_courses_usecase.dart'
    as student_management_get_enrolled_courses_usecase;
import 'features/student_management/domain/usecases/get_available_courses_usecase.dart';
import 'features/student_management/domain/usecases/check_course_capacity_usecase.dart';
import 'features/student_management/domain/usecases/enroll_student_in_course_usecase.dart';
import 'features/student_management/domain/usecases/remove_student_from_course_usecase.dart';
import 'features/student_management/domain/usecases/update_student_profile_usecase.dart';
import 'features/student_management/presentation/bloc/student_management_bloc.dart';

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
import 'features/courses/domain/usecases/get_tutor_courses_usecase.dart';
import 'features/courses/domain/usecases/update_schedule_usecase.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/get_tasks_by_course_usecase.dart';
import 'features/tasks/domain/usecases/get_tasks_for_student_usecase.dart';
import 'features/tasks/domain/usecases/get_student_task_usecase.dart';
import 'features/tasks/domain/usecases/create_task_usecase.dart';
import 'features/tasks/domain/usecases/update_task_usecase.dart';
import 'features/tasks/domain/usecases/delete_task_usecase.dart';
import 'features/tasks/domain/usecases/mark_task_as_completed_usecase.dart';
import 'features/tasks/domain/usecases/mark_task_as_incomplete_usecase.dart';
import 'features/tasks/domain/usecases/add_task_remarks_usecase.dart';
import 'features/tasks/domain/usecases/get_task_completion_status_usecase.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';

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

// AI Chat imports
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mytuition/features/ai_chat/data/datasources/local/chat_local_datasource.dart';
import 'package:mytuition/features/ai_chat/data/datasources/remote/openai_service.dart';
import 'package:mytuition/features/ai_chat/data/repositories/ai_usage_repository_impl.dart';
import 'package:mytuition/features/ai_chat/data/repositories/chat_repository_impl.dart';
import 'package:mytuition/features/ai_chat/data/repositories/openai_repository_impl.dart';
import 'package:mytuition/features/ai_chat/domain/repositories/ai_usage_repository.dart';
import 'package:mytuition/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:mytuition/features/ai_chat/domain/repositories/openai_repository.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/get_ai_usage_usecase.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/get_or_create_active_session_usecase.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/get_session_messages_usecase.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/send_message_usecase.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/start_new_session_usecase.dart';
import 'package:mytuition/features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/get_archived_sessions_usecase.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/reactivate_session_usecase.dart';
import 'package:mytuition/features/ai_chat/domain/usecases/delete_session_usecase.dart';
import 'package:mytuition/features/ai_chat/presentation/bloc/chat_history_bloc.dart';

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

  getIt.registerLazySingleton(
    () => GetStudentPaymentSummaryUseCase(getIt<ProfileRepository>()),
  );

  // BLoCs
  getIt.registerLazySingleton<AuthBloc>(
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

// Profile BLoC - Now with AuthBloc dependency
  getIt.registerFactory(
    () => ProfileBloc(
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      updateProfilePictureUseCase: getIt<UpdateProfilePictureUseCase>(),
      removeProfilePictureUseCase: getIt<RemoveProfilePictureUseCase>(),
      authBloc: getIt<AuthBloc>(),
      getStudentPaymentSummaryUseCase: getIt<GetStudentPaymentSummaryUseCase>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(
      FirebaseFirestore.instance,
    ),
  );

// Course use cases
  getIt.registerLazySingleton(
    () => courses_get_enrolled_courses_usecase.GetEnrolledCoursesUseCase(
        getIt<CourseRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetCourseByIdUseCase(getIt<CourseRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetUpcomingSchedulesUseCase(getIt<CourseRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTutorCoursesUseCase(getIt<CourseRepository>()),
  );
  getIt.registerLazySingleton(
    () => AddScheduleUseCase(getIt<CourseRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateScheduleUseCase(getIt<CourseRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteScheduleUseCase(getIt<CourseRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateCourseActiveStatusUseCase(getIt<CourseRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateCourseCapacityUseCase(getIt<CourseRepository>()),
  );

// Course BLoC
  getIt.registerFactory(
    () => CourseBloc(
      getEnrolledCoursesUseCase: getIt<
          courses_get_enrolled_courses_usecase.GetEnrolledCoursesUseCase>(),
      getCourseByIdUseCase: getIt<GetCourseByIdUseCase>(),
      getUpcomingSchedulesUseCase: getIt<GetUpcomingSchedulesUseCase>(),
      getTutorCoursesUseCase: getIt<GetTutorCoursesUseCase>(),
      addScheduleUseCase: getIt<AddScheduleUseCase>(),
      updateScheduleUseCase: getIt<UpdateScheduleUseCase>(),
      deleteScheduleUseCase: getIt<DeleteScheduleUseCase>(),
      updateCourseActiveStatusUseCase: getIt<UpdateCourseActiveStatusUseCase>(),
      updateCourseCapacityUseCase: getIt<UpdateCourseCapacityUseCase>(),
    ),
  );

  // Task Repository
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      FirebaseFirestore.instance,
    ),
  );

  // Task Use Cases
  getIt.registerLazySingleton(
    () => GetTasksByCourseUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetTasksForStudentUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetStudentTaskUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => CreateTaskUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateTaskUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteTaskUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => MarkTaskAsCompletedUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => MarkTaskAsIncompleteUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => AddTaskRemarksUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetTaskCompletionStatusUseCase(getIt<TaskRepository>()),
  );

  // Task BLoC
  getIt.registerFactory(
    () => TaskBloc(
      getTasksByCourseUseCase: getIt<GetTasksByCourseUseCase>(),
      getTasksForStudentUseCase: getIt<GetTasksForStudentUseCase>(),
      getStudentTaskUseCase: getIt<GetStudentTaskUseCase>(),
      createTaskUseCase: getIt<CreateTaskUseCase>(),
      updateTaskUseCase: getIt<UpdateTaskUseCase>(),
      deleteTaskUseCase: getIt<DeleteTaskUseCase>(),
      markTaskAsCompletedUseCase: getIt<MarkTaskAsCompletedUseCase>(),
      markTaskAsIncompleteUseCase: getIt<MarkTaskAsIncompleteUseCase>(),
      addTaskRemarksUseCase: getIt<AddTaskRemarksUseCase>(),
      getTaskCompletionStatusUseCase: getIt<GetTaskCompletionStatusUseCase>(),
    ),
  );

  // Attendance Repository
  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(FirebaseFirestore.instance),
  );

  // Attendance Use Cases
  getIt.registerLazySingleton(
    () => GetAttendanceByDateUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetEnrolledStudentsUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => RecordBulkAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetStudentAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetCourseAttendanceStatsUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetCourseSchedulesUseCase(getIt<AttendanceRepository>()),
  );

  // NEW: Schedule-specific attendance use cases
  getIt.registerLazySingleton(
    () => CheckScheduleAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetScheduleAttendanceStatusUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetPast7DaysAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  // Attendance BLoC
  getIt.registerFactory(
    () => AttendanceBloc(
      getAttendanceByDateUseCase: getIt<GetAttendanceByDateUseCase>(),
      getEnrolledStudentsUseCase: getIt<GetEnrolledStudentsUseCase>(),
      recordBulkAttendanceUseCase: getIt<RecordBulkAttendanceUseCase>(),
      getStudentAttendanceUseCase: getIt<GetStudentAttendanceUseCase>(),
      getCourseAttendanceStatsUseCase: getIt<GetCourseAttendanceStatsUseCase>(),
      getCourseSchedulesUseCase: getIt<GetCourseSchedulesUseCase>(),
      checkScheduleAttendanceUseCase: getIt<CheckScheduleAttendanceUseCase>(),
      getScheduleAttendanceStatusUseCase:
          getIt<GetScheduleAttendanceStatusUseCase>(),
      getPast7DaysAttendanceUseCase: getIt<GetPast7DaysAttendanceUseCase>(),
      updateAttendanceUseCase: getIt<UpdateAttendanceUseCase>(),
    ),
  );

  // Subject Cost Repository
  getIt.registerLazySingleton<SubjectCostRepository>(
    () => SubjectCostRepositoryImpl(
      FirebaseFirestore.instance,
    ),
  );

  // Subject Cost BLoC
  getIt.registerFactory<SubjectCostBloc>(
    () => SubjectCostBloc(
      subjectCostRepository: getIt<SubjectCostRepository>(),
    ),
  );

// Simplified NotificationService
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(
      FirebaseFirestore.instance,
    ),
  );

// Simplified NotificationRepository
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      FirebaseFirestore.instance,
    ),
  );

  getIt.registerLazySingleton<NotificationManager>(
    () => NotificationManager(
      getIt<NotificationRepository>(),
      httpClient: http.Client(),
    ),
  );

  // Student Management Repository
  getIt.registerLazySingleton<StudentManagementRepository>(
    () => StudentManagementRepositoryImpl(
      FirebaseFirestore.instance,
    ),
  );

  // Student Management Use Cases
  getIt.registerLazySingleton(
    () => GetAllStudentsUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetStudentByIdUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => student_management_get_enrolled_courses_usecase
        .GetEnrolledCoursesUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAvailableCoursesUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => CheckCourseCapacityUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => EnrollStudentInCourseUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => RemoveStudentFromCourseUseCase(getIt<StudentManagementRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateStudentProfileUseCase(getIt<StudentManagementRepository>()),
  );

  // Student Management BLoC
  getIt.registerFactory(
    () => StudentManagementBloc(
      getAllStudentsUseCase: getIt<GetAllStudentsUseCase>(),
      getStudentByIdUseCase: getIt<GetStudentByIdUseCase>(),
      getEnrolledCoursesUseCase: getIt<
          student_management_get_enrolled_courses_usecase
          .GetEnrolledCoursesUseCase>(),
      getAvailableCoursesUseCase: getIt<GetAvailableCoursesUseCase>(),
      checkCourseCapacityUseCase: getIt<CheckCourseCapacityUseCase>(),
      enrollStudentInCourseUseCase: getIt<EnrollStudentInCourseUseCase>(),
      removeStudentFromCourseUseCase: getIt<RemoveStudentFromCourseUseCase>(),
      updateStudentProfileUseCase: getIt<UpdateStudentProfileUseCase>(),
    ),
  );

  // Payment repository registration - add this with other repositories
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      FirebaseFirestore.instance,
    ),
  );

// Payment BLoC registration - add this with other BLoCs
  getIt.registerFactory<PaymentBloc>(
    () => PaymentBloc(
      paymentRepository: getIt<PaymentRepository>(),
    ),
  );

  // Payment Info Repository
  getIt.registerLazySingleton<PaymentInfoRepository>(
    () => PaymentInfoRepositoryImpl(
      FirebaseFirestore.instance,
      'tutor-leong', // Default tutor ID - should come from auth
    ),
  );

  // Payment Info BLoC
  getIt.registerFactory<PaymentInfoBloc>(
    () => PaymentInfoBloc(
      paymentInfoRepository: getIt<PaymentInfoRepository>(),
    ),
  );

  // Firebase Remote Config
  getIt.registerLazySingleton<FirebaseRemoteConfig>(
    () => FirebaseRemoteConfig.instance,
  );

  // AI Chat Data Sources
  getIt.registerLazySingleton<ChatLocalDatasource>(
    () => ChatLocalDatasource(FirebaseFirestore.instance),
  );

  getIt.registerLazySingleton<OpenAIService>(
    () => OpenAIService(
      httpClient: http.Client(),
      remoteConfig: getIt<FirebaseRemoteConfig>(),
    ),
  );

  // AI Chat Repositories
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      localDatasource: getIt<ChatLocalDatasource>(),
      openaiService: getIt<OpenAIService>(),
    ),
  );

  getIt.registerLazySingleton<AIUsageRepository>(
    () => AIUsageRepositoryImpl(getIt<ChatLocalDatasource>()),
  );

  getIt.registerLazySingleton<OpenAIRepository>(
    () => OpenAIRepositoryImpl(getIt<OpenAIService>()),
  );

  // AI Chat Use Cases
  getIt.registerLazySingleton<SendMessageUseCase>(
    () => SendMessageUseCase(
      chatRepository: getIt<ChatRepository>(),
      aiUsageRepository: getIt<AIUsageRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetOrCreateActiveSessionUseCase>(
    () => GetOrCreateActiveSessionUseCase(
      chatRepository: getIt<ChatRepository>(),
      aiUsageRepository: getIt<AIUsageRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetSessionMessagesUseCase>(
    () => GetSessionMessagesUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton<GetAIUsageUseCase>(
    () => GetAIUsageUseCase(getIt<AIUsageRepository>()),
  );

  getIt.registerLazySingleton<StartNewSessionUseCase>(
    () => StartNewSessionUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton<GetArchivedSessionsUseCase>(
    () => GetArchivedSessionsUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton<ReactivateSessionUseCase>(
    () => ReactivateSessionUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton<DeleteSessionUseCase>(
    () => DeleteSessionUseCase(getIt<ChatRepository>()),
  );

  // AI Chat BLoC
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      sendMessageUseCase: getIt<SendMessageUseCase>(),
      getOrCreateActiveSessionUseCase: getIt<GetOrCreateActiveSessionUseCase>(),
      getSessionMessagesUseCase: getIt<GetSessionMessagesUseCase>(),
      getAIUsageUseCase: getIt<GetAIUsageUseCase>(),
      startNewSessionUseCase: getIt<StartNewSessionUseCase>(),
    ),
  );

  //Chat History BLoC
  getIt.registerFactory<ChatHistoryBloc>(
    () => ChatHistoryBloc(
      getArchivedSessionsUseCase: getIt<GetArchivedSessionsUseCase>(),
      reactivateSessionUseCase: getIt<ReactivateSessionUseCase>(),
      deleteSessionUseCase: getIt<DeleteSessionUseCase>(),
    ),
  );

  // Dashboard BLoC
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      getAllStudentsUseCase: getIt<GetAllStudentsUseCase>(),
      getTutorCoursesUseCase: getIt<GetTutorCoursesUseCase>(),
      registrationRepository: getIt<RegistrationRepository>(),
      paymentRepository: getIt<PaymentRepository>(),
      firestore: FirebaseFirestore.instance,
    ),
  );

  // Student Dashboard Repository
  getIt.registerLazySingleton<StudentDashboardRepository>(
    () => StudentDashboardRepositoryImpl(FirebaseFirestore.instance),
  );

  // Student Dashboard Use Cases
  getIt.registerLazySingleton<GetStudentDashboardStatsUseCase>(
    () => GetStudentDashboardStatsUseCase(
      studentDashboardRepository: getIt<StudentDashboardRepository>(),
      aiUsageRepository: getIt<AIUsageRepository>(),
    ),
  );

  // Student Dashboard BLoC (add this with your other BLoC registrations)
  getIt.registerFactory<StudentDashboardBloc>(
    () => StudentDashboardBloc(
      getStudentDashboardStatsUseCase: getIt<GetStudentDashboardStatsUseCase>(),
      studentDashboardRepository: getIt<StudentDashboardRepository>(),
    ),
  );
}

Future<void> initFirebaseRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(seconds: 0), // For debugging only
  ));

  await remoteConfig.setDefaults({
    'openai_api_key': '',
    'openai_assistant_id': '',
    'daily_question_limit': 20,
  });

  try {
    // Add debugging
    print('Fetching Remote Config...');
    bool updated = await remoteConfig.fetchAndActivate();
    print('Remote Config fetch result: $updated');

    // Check the actual value
    final apiKey = remoteConfig.getString('openai_api_key');
    print(
        'API Key found: ${apiKey.isNotEmpty ? "YES (${apiKey.length} chars)" : "NO"}');
    print(
        'First 10 chars: ${apiKey.length > 10 ? apiKey.substring(0, 10) : apiKey}');
  } catch (e) {
    print('Remote Config fetch error: $e');
  }
}

// Define this outside any class
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp(
    name: 'myTuition_FYP',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
}

// Create this as a global variable
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Add this function
Future<void> setupFirebaseMessaging() async {
  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configure local notifications for foreground messages
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Create the Android notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Got a message in foreground!");
    print("Message data: ${message.data}");

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@drawable/ic_notification',
          ),
        ),
      );
    }
  });

  // Print the FCM token for debugging
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
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

  // Initialize FCM Service
  final fcmService = FCMService();
  await fcmService.initialize();
  await setupFirebaseMessaging();

  // Initialize Remote Config
  await initFirebaseRemoteConfig();

  // Register FCM service in GetIt
  getIt.registerSingleton<FCMService>(fcmService);

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
      // Wrap MaterialApp.router with Sizer widget
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp.router(
            title: 'myTuition',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            // Default to light theme
            debugShowCheckedModeBanner: false,
            routerDelegate: AppRouter.router.routerDelegate,
            routeInformationParser: AppRouter.router.routeInformationParser,
            routeInformationProvider: AppRouter.router.routeInformationProvider,
          );
        },
      ),
    );
  }
}
