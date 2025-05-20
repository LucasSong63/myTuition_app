// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

/// A simple logger utility for consistent logging throughout the app
class Logger {
  // Private constructor to prevent instantiation
  Logger._();

  // Log levels
  static const int _levelInfo = 0;
  static const int _levelDebug = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;

  // Default minimum log level (can be adjusted at runtime)
  static int _minLevel = kDebugMode ? _levelDebug : _levelWarning;

  /// Set the minimum log level for the application
  static void setLogLevel(int level) {
    _minLevel = level;
  }

  /// Log an info message
  static void info(String message) {
    if (_minLevel <= _levelInfo) {
      _log('INFO', message);
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (_minLevel <= _levelDebug) {
      _log('DEBUG', message);
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (_minLevel <= _levelWarning) {
      _log('WARNING', message);
    }
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_minLevel <= _levelError) {
      _log('ERROR', message);

      if (error != null) {
        debugPrint('ERROR DETAILS: $error');
      }

      if (stackTrace != null) {
        debugPrint('STACK TRACE: $stackTrace');
      }
    }
  }

  // Internal logging method
  static void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] $level: $message');

    // In a production app, this would also send logs to a service like Firebase Crashlytics
    // or another logging service when appropriate
  }
}
