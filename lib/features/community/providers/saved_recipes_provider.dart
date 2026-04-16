import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';
import 'package:smartmeal/features/deals_scanner/providers/custom_recipes_provider.dart';

class SavedRecipesNotifier extends StateNotifier<Set<String>> {
  final String? userId;

  SavedRecipesNotifier({this.userId}) : super({}) {
    if (userId != null) _load();
  }

  final _client = SupabaseConfig.client;

  Future<void> _load() async {
    if (userId == null) return;
    try {
      final response = await _client
          .from('saved_recipes')
          .select('recipe_id')
          .eq('user_id', userId!);

      state = (response as List)
          .map((e) => e['recipe_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint('Error loading saved recipes: $e');
    }
  }

  bool isSaved(String recipeId) => state.contains(recipeId);

  Future<void> toggleSave(String recipeId) async {
    if (userId == null) return;

    if (isSaved(recipeId)) {
      // Optimistic unsave
      state = Set.from(state)..remove(recipeId);
      try {
        await _client
            .from('saved_recipes')
            .delete()
            .eq('user_id', userId!)
            .eq('recipe_id', recipeId);
      } catch (e) {
        state = {...state, recipeId};
        debugPrint('Error unsaving recipe: $e');
      }
    } else {
      // Optimistic save
      state = {...state, recipeId};
      try {
        await _client.from('saved_recipes').insert({
          'user_id': userId,
          'recipe_id': recipeId,
        });
      } catch (e) {
        state = Set.from(state)..remove(recipeId);
        debugPrint('Error saving recipe: $e');
      }
    }
  }
}

final savedRecipeIdsProvider =
    StateNotifierProvider<SavedRecipesNotifier, Set<String>>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  return SavedRecipesNotifier(userId: userId);
});

/// Full saved recipe objects for display in "Eigene" tab
final savedRecipesListProvider = Provider<List<CustomRecipe>>((ref) {
  final savedIds = ref.watch(savedRecipeIdsProvider);
  final allRecipes = ref.watch(customRecipesProvider).recipes;
  return allRecipes.where((r) => savedIds.contains(r.id)).toList();
});
