import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

const String postsBucket = 'posts';
const String avatarsBucket = 'avatars';

class SupabaseStorageService {
  final SupabaseClient _supabase;
  SupabaseStorageService(this._supabase);

  /// Upload a file and return its public URL.
  Future<String> uploadFile(
    String filePath,
    String storagePath, {
    String bucket = postsBucket,
  }) async {
    final file = File(filePath);
    await _supabase.storage.from(bucket).upload(
      storagePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return getPublicUrl(storagePath, bucket: bucket);
  }

  String getPublicUrl(String storagePath, {String bucket = postsBucket}) {
    return _supabase.storage.from(bucket).getPublicUrl(storagePath);
  }

  Future<void> deleteFile(String storagePath, {String bucket = postsBucket}) async {
    await _supabase.storage.from(bucket).remove([storagePath]);
  }
}

final storageProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService(supabase);
});
