import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _displayNameKey = 'community_display_name';

// Loads display name from SharedPreferences on start
final displayNameProvider = StateNotifierProvider<DisplayNameNotifier, String?>((ref) {
  return DisplayNameNotifier();
});

class DisplayNameNotifier extends StateNotifier<String?> {
  DisplayNameNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_displayNameKey);
  }

  Future<void> setName(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, name);
  }
}

final profileImageUrlProvider = StateProvider<String?>((ref) => null);

// Whether this user has set a display name for community
final hasDisplayNameProvider = Provider<bool>((ref) {
  final name = ref.watch(displayNameProvider);
  return name != null && name.trim().isNotEmpty;
});
