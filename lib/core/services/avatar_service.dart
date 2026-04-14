import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartmeal/core/config/supabase_config.dart';

class AvatarService {
  static final _client = SupabaseConfig.client;
  static const _bucketName = 'avatars';

  /// Pick an image from camera or gallery and upload to Supabase Storage
  static Future<String?> pickAndUploadAvatar({
    required String userId,
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final fileBytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last.toLowerCase();
      final filePath = '$userId/profile.$fileExt';

      // Upload to Supabase Storage
      await _client.storage.from(_bucketName).uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // Get public URL
      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(filePath);

      // Update user_profiles table
      await _client.from('user_profiles').upsert({
        'id': userId,
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Load avatar URL from user_profiles
  static Future<String?> getAvatarUrl(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      return response?['avatar_url'] as String?;
    } catch (e) {
      debugPrint('Error loading avatar URL: $e');
      return null;
    }
  }
}
