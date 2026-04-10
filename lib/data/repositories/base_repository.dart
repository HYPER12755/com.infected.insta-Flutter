import 'dart:async';
import '../models/result.dart';

/// Base repository with common functionality like retry logic
abstract class BaseRepository {
  /// Execute a function with retry logic
  /// [maxRetries] - Maximum number of retry attempts
  /// [initialDelay] - Initial delay between retries in milliseconds
  /// [backoffMultiplier] - Multiplier for exponential backoff
  Future<Result<T>> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    int initialDelay = 500,
    double backoffMultiplier = 2.0,
  }) async {
    int currentDelay = initialDelay;
    int attempts = 0;

    while (true) {
      try {
        final result = await operation();
        return Success(result);
      } on Exception catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return Failure(
            DatabaseException(
              message: e.toString(),
              originalError: e,
            ),
          );
        }
        await Future.delayed(Duration(milliseconds: currentDelay));
        currentDelay = (currentDelay * backoffMultiplier).toInt();
      }
    }
  }

  /// Handle database query returning no results
  Result<List<T>> handleEmptyQuery<T>() {
    return const Success([]);
  }
}
