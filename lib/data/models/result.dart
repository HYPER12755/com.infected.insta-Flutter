/// A Result type for handling success and failure states
/// This provides better error handling than returning nulls or empty lists
sealed class Result<T> {
  const Result();

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Get the data if success, throws if failure
  T get data {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw Exception('Cannot get data from failure result');
  }

  /// Get the error if failure, throws if success
  AppException get error {
    if (this is Failure<T>) {
      return (this as Failure<T>).exception;
    }
    throw Exception('Cannot get error from success result');
  }

  /// Map over the result
  Result<R> map<R>(R Function(T) transform) {
    if (this is Success<T>) {
      return Success(transform((this as Success<T>).value));
    }
    return Failure((this as Failure<T>).exception);
  }

  /// Fold the result to a single value
  R fold<R>(R Function(AppException) onFailure, R Function(T) onSuccess) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    }
    return onFailure((this as Failure<T>).exception);
  }
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Failure result containing an exception
class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

/// Custom exception class for app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.code = 'NETWORK_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    super.message = 'Database error occurred',
    super.code = 'DATABASE_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication error occurred',
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
    super.originalError,
    super.stackTrace,
  });
}
