import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorHandler {
  /// Get a user-friendly error message
  static String getUserFriendlyMessage(Exception error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    } else if (errorString.contains('not-found')) {
      return 'The requested data was not found.';
    } else if (errorString.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    } else if (errorString.contains('unavailable')) {
      return 'Service is currently unavailable. Please try again later.';
    }

    return 'An error occurred. Please try again.';
  }

  /// Check network connectivity
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Attempt to retry an operation with backoff
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    int initialDelayMs = 500,
  }) async {
    int attempt = 0;
    int delayMs = initialDelayMs;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // Exponential backoff
      }
    }
  }
}
