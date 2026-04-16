import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:smartmeal/features/deals_scanner/providers/custom_recipes_provider.dart';

class UserProfile {
  final String id;
  final String? communityName;
  final String? avatarUrl;

  const UserProfile({required this.id, this.communityName, this.avatarUrl});
}

/// Load a user's profile by ID
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  try {
    final response = await SupabaseConfig.client
        .from('user_profiles')
        .select('id, community_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserProfile(
      id: response['id'] as String,
      communityName: response['community_name'] as String?,
      avatarUrl: response['avatar_url'] as String?,
    );
  } catch (e) {
    debugPrint('Error loading user profile: $e');
    return null;
  }
});

/// Load public recipes for a specific user (newest first)
final userPublicRecipesProvider = FutureProvider.family<List<CustomRecipe>, String>((ref, userId) async {
  try {
    final response = await SupabaseConfig.client
        .from('custom_recipes')
        .select()
        .eq('user_id', userId)
        .eq('is_public', true)
        .order('created_at', ascending: false);

    // Load likes
    final likesResponse = await SupabaseConfig.client
        .from('recipe_likes')
        .select('recipe_id');
    final likeCounts = <String, int>{};
    for (final like in (likesResponse as List)) {
      final recipeId = like['recipe_id'] as String;
      likeCounts[recipeId] = (likeCounts[recipeId] ?? 0) + 1;
    }

    return (response as List).map((e) {
      final data = Map<String, dynamic>.from(e);
      final id = data['id'] as String;
      return CustomRecipe.fromJson(data, likeCount: likeCounts[id] ?? 0);
    }).toList();
  } catch (e) {
    debugPrint('Error loading user recipes: $e');
    return [];
  }
});
