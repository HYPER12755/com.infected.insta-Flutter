import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';

/// Base repository with common functionality like retry logic
abstract class BaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

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
      } on FirebaseException catch (e) {
        attempts++;
        if (attempts >= maxRetries || !_isRetryable(e)) {
          return Failure(DatabaseException(
            message: e.message ?? 'Database operation failed',
            code: e.code,
            originalError: e,
          ));
        }
        await Future.delayed(Duration(milliseconds: currentDelay));
        currentDelay = (currentDelay * backoffMultiplier).toInt();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return Failure(AppException(
            message: e.toString(),
            originalError: e,
          ));
        }
        await Future.delayed(Duration(milliseconds: currentDelay));
        currentDelay = (currentDelay * backoffMultiplier).toInt();
      }
    }
  }

  /// Check if the error is retryable
  bool _isRetryable(FirebaseException e) {
    // Retry on network-related errors
    final retryableCodes = [
      'network-error',
      'server-error',
      'unavailable',
      'deadline-exceeded',
      'internal',
      'unknown',
    ];
    return retryableCodes.contains(e.code);
  }

  /// Handle Firestore document not found
  Result<T> handleDocumentNotFound<T>(DocumentSnapshot doc) {
    if (!doc.exists) {
      return const Failure(NotFoundException(
        message: 'Document not found',
      ));
    }
    return Success(doc.data() as T);
  }

  /// Handle Firestore query returning no results
  Result<List<T>> handleEmptyQuery<T>(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      return const Success([]);
    }
    return Success(snapshot.docs.map((doc) => doc.data() as T).toList());
  }
}
