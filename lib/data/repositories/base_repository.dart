import 'dart:async';
import '../models/result.dart';
import '../../supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseRepository {
  /// Current authenticated user
  User? get currentUser => supabase.auth.currentUser;

  /// Execute with retry logic
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
          return Failure(DatabaseException(message: e.toString(), originalError: e));
        }
        await Future.delayed(Duration(milliseconds: currentDelay));
        currentDelay = (currentDelay * backoffMultiplier).toInt();
      }
    }
  }

  Result<List<T>> handleEmptyQuery<T>() => const Success([]);
}
