/// Modern result type using Dart 3.0 sealed classes
/// Replaces Either<Failure, T> from dartz
sealed class Result<T> {
  const Result();

  /// Check if result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if result is an error
  bool get isError => this is Error<T>;

  /// Get data if success, otherwise return null
  T? get dataOrNull => switch (this) {
        Success(data: final data) => data,
        Error() => null,
      };

  /// Get error if error, otherwise return null
  String? get errorOrNull => switch (this) {
        Success() => null,
        Error(message: final message) => message,
      };

  /// Transform success data to another type
  Result<U> map<U>(U Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      Error(message: final message) => Error(message),
    };
  }

  /// Transform success data to another Result
  Result<U> flatMap<U>(Result<U> Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => transform(data),
      Error(message: final message) => Error(message),
    };
  }

  /// Execute function on success, return this
  Result<T> onSuccess(void Function(T data) action) {
    if (this case Success(data: final data)) {
      action(data);
    }
    return this;
  }

  /// Execute function on error, return this
  Result<T> onError(void Function(String message) action) {
    if (this case Error(message: final message)) {
      action(message);
    }
    return this;
  }

  /// Get data or return default value
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Error() => defaultValue(),
    };
  }

  /// Fold result into a single value
  U fold<U>(
    U Function(String message) onError,
    U Function(T data) onSuccess,
  ) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Error(message: final message) => onError(message),
    };
  }
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Error result containing error message
class Error<T> extends Result<T> {
  final String message;

  const Error(this.message);

  @override
  String toString() => 'Error($message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

// Extension methods for common operations
extension ResultExtensions<T> on Result<T> {
  /// Convert to nullable value
  T? toNullable() => dataOrNull;

  /// Convert to Stream
  Stream<T> toStream() async* {
    if (this case Success(data: final data)) {
      yield data;
    }
  }

  /// Convert to Future
  Future<T> toFuture() async {
    return switch (this) {
      Success(data: final data) => data,
      Error(message: final message) => throw Exception(message),
    };
  }
}

// Factory methods for common Result creation patterns
extension ResultFactory on Result {
  /// Create success result
  static Result<T> success<T>(T data) => Success(data);

  /// Create error result
  static Result<T> error<T>(String message) => Error<T>(message);

  /// Create result from nullable value
  static Result<T> fromNullable<T>(T? value, String errorMessage) {
    return value != null ? Success(value) : Error(errorMessage);
  }

  /// Create result from try-catch
  static Future<Result<T>> tryAsync<T>(Future<T> Function() computation) async {
    try {
      final result = await computation();
      return Success(result);
    } catch (e) {
      return Error(e.toString());
    }
  }

  /// Create result from synchronous try-catch
  static Result<T> trySync<T>(T Function() computation) {
    try {
      final result = computation();
      return Success(result);
    } catch (e) {
      return Error(e.toString());
    }
  }
}

// Helper functions for working with multiple Results
class ResultUtils {
  /// Combine two results into a tuple
  static Result<(T1, T2)> combine2<T1, T2>(
    Result<T1> result1,
    Result<T2> result2,
  ) {
    return switch ((result1, result2)) {
      (Success(data: final data1), Success(data: final data2)) =>
        Success((data1, data2)),
      (Error(message: final message), _) => Error(message),
      (_, Error(message: final message)) => Error(message),
    };
  }

  /// Combine three results into a tuple
  static Result<(T1, T2, T3)> combine3<T1, T2, T3>(
    Result<T1> result1,
    Result<T2> result2,
    Result<T3> result3,
  ) {
    return switch ((result1, result2, result3)) {
      (
        Success(data: final data1),
        Success(data: final data2),
        Success(data: final data3)
      ) =>
        Success((data1, data2, data3)),
      (Error(message: final message), _, _) => Error(message),
      (_, Error(message: final message), _) => Error(message),
      (_, _, Error(message: final message)) => Error(message),
    };
  }

  /// Execute function if all results are successful
  static Result<List<T>> sequence<T>(List<Result<T>> results) {
    final List<T> data = [];

    for (final result in results) {
      switch (result) {
        case Success(data: final value):
          data.add(value);
        case Error(message: final message):
          return Error(message);
      }
    }

    return Success(data);
  }
}

// Specific error types for better error handling
sealed class AppError {
  const AppError();

  String get message;
}

class NetworkError extends AppError {
  @override
  String get message => 'Please check your internet connection and try again.';
}

class DailyLimitReachedError extends AppError {
  @override
  String get message =>
      'You have reached your daily question limit of 20 questions. Please try again tomorrow!';
}

class OpenAIError extends AppError {
  final String details;

  const OpenAIError(this.details);

  @override
  String get message =>
      'Sorry, I\'m having trouble thinking right now. Please try again in a moment.';
}

class DatabaseError extends AppError {
  final String details;

  const DatabaseError(this.details);

  @override
  String get message =>
      'Something went wrong with saving your data. Please try again.';
}

class ConfigError extends AppError {
  final String details;

  const ConfigError(this.details);

  @override
  String get message => 'Configuration error. Please contact support.';
}

class UnexpectedError extends AppError {
  final String details;

  const UnexpectedError(this.details);

  @override
  String get message => 'Something unexpected happened. Please try again.';
}

// Extension for converting AppError to Result
extension AppErrorExtensions on AppError {
  Result<T> toResult<T>() => Error<T>(message);
}
