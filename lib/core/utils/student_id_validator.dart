/// Utility class for validating student IDs across the application
class StudentIdValidator {
  /// Basic pattern for MyTuition student IDs: MT[YY]-[NNNN]
  static final RegExp _basicPattern = RegExp(r'^MT\d{2}-\d{4}$');

  /// Validates if a string matches the basic student ID format
  static bool isValidFormat(String id) {
    return _basicPattern.hasMatch(id);
  }

  /// Validates student ID with year range checking
  static bool isValidWithYearCheck(
    String id, {
    int? minYear,
    int? maxYear,
  }) {
    if (!isValidFormat(id)) return false;

    try {
      // Extract year from ID
      final year = extractYear(id);
      if (year == null) return false;

      final currentYear = DateTime.now().year;
      final checkMinYear =
          minYear ?? currentYear - 10; // Default: 10 years back
      final checkMaxYear = maxYear ?? currentYear + 2; // Default: 2 years ahead

      return year >= checkMinYear && year <= checkMaxYear;
    } catch (e) {
      return false;
    }
  }

  /// Extracts the year from a student ID
  static int? extractYear(String id) {
    if (!isValidFormat(id)) return null;

    try {
      final yearPart = id.substring(2, 4); // Get YY part
      final year = int.parse(yearPart);
      return 2000 + year; // Convert to full year
    } catch (e) {
      return null;
    }
  }

  /// Extracts the student number from a student ID
  static int? extractStudentNumber(String id) {
    if (!isValidFormat(id)) return null;

    try {
      final parts = id.split('-');
      return int.parse(parts[1]);
    } catch (e) {
      return null;
    }
  }

  /// Generates a student ID for a given year and number
  static String generateStudentId(int year, int number) {
    final yearSuffix = year % 100; // Get last 2 digits of year
    final numberStr = number.toString().padLeft(4, '0'); // Ensure 4 digits
    return 'MT${yearSuffix.toString().padLeft(2, '0')}-$numberStr';
  }

  /// Validates if student exists in a given list
  static bool existsInList(String id, List<Map<String, dynamic>> students) {
    return students.any((student) => student['studentId'] == id);
  }

  /// Comprehensive validation combining format, year, and enrollment checks
  static bool validateForAttendance(
    String id,
    List<Map<String, dynamic>> enrolledStudents, {
    int? minYear,
    int? maxYear,
  }) {
    // First check basic format
    if (!isValidFormat(id)) return false;

    // Then check year range
    if (!isValidWithYearCheck(id, minYear: minYear, maxYear: maxYear)) {
      return false;
    }

    // Finally check if student is enrolled
    return existsInList(id, enrolledStudents);
  }
}

/// Helper class for validation results with detailed feedback
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? studentId;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.studentId,
  });

  factory ValidationResult.valid(String studentId) {
    return ValidationResult(isValid: true, studentId: studentId);
  }

  factory ValidationResult.invalid(String errorMessage) {
    return ValidationResult(isValid: false, errorMessage: errorMessage);
  }
}
