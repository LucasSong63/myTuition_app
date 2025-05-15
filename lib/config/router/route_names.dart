/// Route name constants for the application
///
/// This file contains all route names used with GoRouter
/// Each route has both a name (for references in code)
/// and a path (for the actual URL path)
class RouteNames {
  // Don't allow instantiation
  RouteNames._();

  // Auth routes
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String verifyEmail = 'verifyEmail';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

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
  static const String tutorTasks = 'tutorTasks';
  static const String tutorTaskDetails = 'tutorTaskDetails';
  static const String tutorAttendance = 'tutorAttendance';
  static const String tutorPayments = 'tutorPayments';
  static const String tutorCourseDetails = 'tutorCourseDetails';
  static const String tutorSubjectCosts = 'tutorSubjectCosts';
  static const String tutorPaymentInfo = 'tutorPaymentInfo';
}
