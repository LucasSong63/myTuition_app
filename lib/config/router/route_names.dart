// lib/config/route/route_names.dart
class RouteNames {
  RouteNames._();

  // Auth routes
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String verifyEmail = 'verifyEmail';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

  // Admin routes
  static const String adminSetup = 'adminSetup';

  // Notification routes
  static const String notifications = 'notifications';

  // Student routes
  static const String studentRoot = 'studentRoot';
  static const String studentDashboard = 'studentDashboard';
  static const String studentProfile = 'studentProfile';
  static const String studentCourses = 'studentCourses';
  static const String studentCourseDetails = 'studentCourseDetails';
  static const String studentAiChat = 'studentAiChat';
  static const String studentTasks = 'studentTasks';
  static const String studentTaskDetails = 'studentTaskDetails';
  static const String studentAttendance = 'studentAttendance';
  static const String studentAttendanceHistory = 'studentAttendanceHistory';
  static const String studentPayments = 'studentPayments';

  // Tutor routes
  static const String tutorRoot = 'tutorRoot';
  static const String tutorDashboard = 'tutorDashboard';
  static const String tutorProfile = 'tutorProfile';
  static const String tutorSubjects = 'tutorSubjects';
  static const String tutorSubjectDetails = 'tutorSubjectDetails';
  static const String tutorStudents = 'tutorStudents';
  static const String tutorStudentDetails = 'tutorStudentDetails';
  static const String tutorClasses = 'tutorClasses';
  static const String tutorClassDetails = 'tutorClassDetails';
  static const String tutorCourseDetails = 'tutorCourseDetails';
  static const String tutorTasks = 'tutorTasks';
  static const String tutorTaskDetails = 'tutorTaskDetails';
  static const String tutorAttendance = 'tutorAttendance';
  static const String tutorPayments = 'tutorPayments';
  static const String tutorSubjectCosts = 'tutorSubjectCosts';
  static const String tutorPaymentInfo = 'tutorPaymentInfo';
  static const String tutorRegistrations = 'tutorRegistrations';
  static const String registrationDetails = 'registrationDetails';

  // Course management routes
  static const String tutorCourseTaskManagement = 'tutorCourseTaskManagement';
  static const String tutorTaskProgress = 'tutorTaskProgress';

  // Attendance routes
  static const String manageAttendance = 'manageAttendance';
  static const String takeAttendance = 'takeAttendance';
  static const String editAttendance = 'editAttendance';

  // Legacy routes
  static const String legacyCourseDetail = 'legacyCourseDetail';
}
