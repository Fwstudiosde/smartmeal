import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';

const _displayNameKey = 'community_display_name';

// Loads display name from SharedPreferences on start
final displayNameProvider = StateNotifierProvider<DisplayNameNotifier, String?>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  return DisplayNameNotifier(userId: userId);
});

class DisplayNameNotifier extends StateNotifier<String?> {
  final String? userId;

  DisplayNameNotifier({this.userId}) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_displayNameKey);

    // Also try to load from Supabase if we have a userId
    if (userId != null) {
      try {
        final response = await SupabaseConfig.client
            .from('user_profiles')
            .select('community_name')
            .eq('id', userId!)
            .maybeSingle();

        final remoteName = response?['community_name'] as String?;
        if (remoteName != null && remoteName.isNotEmpty) {
          state = remoteName;
          await prefs.setString(_displayNameKey, remoteName);
        }
      } catch (_) {}
    }
  }

  Future<void> setName(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, name);

    // Sync to Supabase
    if (userId != null) {
      try {
        await SupabaseConfig.client.from('user_profiles').upsert({
          'id': userId,
          'community_name': name,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error syncing community name: $e');
      }
    }
  }
}

final profileImageUrlProvider = StateProvider<String?>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.profileImageUrl;
});

// Whether this user has set a display name for community
final hasDisplayNameProvider = Provider<bool>((ref) {
  final name = ref.watch(displayNameProvider);
  return name != null && name.trim().isNotEmpty;
});
