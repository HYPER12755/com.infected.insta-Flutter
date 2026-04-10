import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_client.dart';

/// Bucket name for storing posts media
const String postsBucket = 'posts';

/// Storage service for handling media uploads with Supabase Storage
class SupabaseStorageService {
  final SupabaseClient _supabase;

  SupabaseStorageService(this._supabase);

  /// Upload a file to Supabase Storage
  ///
  /// [filePath] - The local path to the file
  /// [storagePath] - The path to store the file in the bucket (e.g., 'user_id/image.jpg')
  /// [bucket] - The bucket name (defaults to 'posts')
  Future<String> uploadFile(
    String filePath,
    String storagePath, {
    String bucket = postsBucket,
  }) async {
    final file = File(filePath);

    // Upload the file to Supabase Storage
    await _supabase.storage.from(bucket).upload(storagePath, file);

    // Return the public URL
    return getPublicUrl(storagePath, bucket: bucket);
  }

  /// Get the public URL for a stored file
  String getPublicUrl(String storagePath, {String bucket = postsBucket}) {
    return _supabase.storage.from(bucket).getPublicUrl(storagePath);
  }

  /// Delete a file from Supabase Storage
  Future<void> deleteFile(
    String storagePath, {
    String bucket = postsBucket,
  }) async {
    await _supabase.storage.from(bucket).remove([storagePath]);
  }

  /// Delete multiple files from Supabase Storage
  Future<void> deleteFiles(
    List<String> storagePaths, {
    String bucket = postsBucket,
  }) async {
    await _supabase.storage.from(bucket).remove(storagePaths);
  }
}

/// Provider for Supabase Storage service
final storageProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService(supabase);
});
