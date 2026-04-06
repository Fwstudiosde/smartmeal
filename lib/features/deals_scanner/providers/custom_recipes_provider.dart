import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';

class CustomRecipe {
  final String id;
  final String userId;
  final String name;
  final String description;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final List<Map<String, dynamic>> ingredients;
  final List<String> instructions;
  final bool isPublic;
  final String? authorName;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;

  const CustomRecipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    this.isPublic = false,
    this.authorName,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  factory CustomRecipe.fromJson(Map<String, dynamic> json, {int likeCount = 0, bool isLikedByMe = false}) {
    return CustomRecipe(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      prepTime: json['prep_time'] as int? ?? 0,
      cookTime: json['cook_time'] as int? ?? 0,
      servings: json['servings'] as int? ?? 2,
      difficulty: json['difficulty'] as String? ?? 'Einfach',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPublic: json['is_public'] as bool? ?? false,
      authorName: json['author_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: likeCount,
      isLikedByMe: isLikedByMe,
    );
  }
}

class CustomRecipesState {
  final List<CustomRecipe> recipes;
  final bool isLoading;
  final String? error;

  CustomRecipesState({
    this.recipes = const [],
    this.isLoading = false,
    this.error,
  });

  CustomRecipesState copyWith({
    List<CustomRecipe>? recipes,
    bool? isLoading,
    String? error,
  }) {
    return CustomRecipesState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomRecipesNotifier extends StateNotifier<CustomRecipesState> {
  final String? userId;

  CustomRecipesNotifier({this.userId}) : super(CustomRecipesState()) {
    loadRecipes();
  }

  final _client = SupabaseConfig.client;

  Future<void> loadRecipes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load recipes
      final response = await _client
          .from('custom_recipes')
          .select()
          .order('created_at', ascending: false);

      // Load all likes grouped by recipe
      final likesResponse = await _client
          .from('recipe_likes')
          .select('recipe_id');

      // Count likes per recipe
      final likeCounts = <String, int>{};
      for (final like in (likesResponse as List)) {
        final recipeId = like['recipe_id'] as String;
        likeCounts[recipeId] = (likeCounts[recipeId] ?? 0) + 1;
      }

      // Load my likes
      final myLikes = <String>{};
      if (userId != null) {
        final myLikesResponse = await _client
            .from('recipe_likes')
            .select('recipe_id')
            .eq('user_id', userId!);
        for (final like in (myLikesResponse as List)) {
          myLikes.add(like['recipe_id'] as String);
        }
      }

      final recipes = (response as List)
          .map((e) {
            final data = Map<String, dynamic>.from(e);
            final id = data['id'] as String;
            return CustomRecipe.fromJson(
              data,
              likeCount: likeCounts[id] ?? 0,
              isLikedByMe: myLikes.contains(id),
            );
          })
          .toList();

      state = state.copyWith(recipes: recipes, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleLike(String recipeId) async {
    if (userId == null) return;

    // Optimistic update
    final updated = state.recipes.map((r) {
      if (r.id != recipeId) return r;
      return CustomRecipe(
        id: r.id, userId: r.userId, name: r.name, description: r.description,
        prepTime: r.prepTime, cookTime: r.cookTime, servings: r.servings,
        difficulty: r.difficulty, ingredients: r.ingredients,
        instructions: r.instructions, isPublic: r.isPublic,
        authorName: r.authorName, createdAt: r.createdAt,
        likeCount: r.isLikedByMe ? r.likeCount - 1 : r.likeCount + 1,
        isLikedByMe: !r.isLikedByMe,
      );
    }).toList();
    state = state.copyWith(recipes: updated);

    try {
      final recipe = state.recipes.firstWhere((r) => r.id == recipeId);
      if (recipe.isLikedByMe) {
        // Was just liked (optimistic) -> insert
        await _client.from('recipe_likes').insert({
          'user_id': userId,
          'recipe_id': recipeId,
        });
      } else {
        // Was just unliked (optimistic) -> delete
        await _client
            .from('recipe_likes')
            .delete()
            .eq('user_id', userId!)
            .eq('recipe_id', recipeId);
      }
    } catch (e) {
      // Revert on error
      await loadRecipes();
    }
  }

  Future<void> togglePublic(String recipeId, {String? authorName}) async {
    // Optimistic update
    final updated = state.recipes.map((r) {
      if (r.id != recipeId) return r;
      return CustomRecipe(
        id: r.id, userId: r.userId, name: r.name, description: r.description,
        prepTime: r.prepTime, cookTime: r.cookTime, servings: r.servings,
        difficulty: r.difficulty, ingredients: r.ingredients,
        instructions: r.instructions, createdAt: r.createdAt,
        likeCount: r.likeCount, isLikedByMe: r.isLikedByMe,
        isPublic: !r.isPublic,
        authorName: authorName ?? r.authorName,
      );
    }).toList();
    state = state.copyWith(recipes: updated);

    try {
      final recipe = updated.firstWhere((r) => r.id == recipeId);
      await _client.from('custom_recipes').update({
        'is_public': recipe.isPublic,
        if (authorName != null) 'author_name': authorName,
      }).eq('id', recipeId);
    } catch (e) {
      await loadRecipes();
    }
  }

  Future<void> createRecipe({
    required String name,
    required String description,
    required int prepTime,
    required int cookTime,
    required int servings,
    required String difficulty,
    required List<Map<String, String>> ingredients,
    required List<String> instructions,
    bool isPublic = false,
    String? authorName,
  }) async {
    if (userId == null) throw Exception('Nicht angemeldet');

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.from('custom_recipes').insert({
        'user_id': userId,
        'name': name,
        'description': description,
        'prep_time': prepTime,
        'cook_time': cookTime,
        'servings': servings,
        'difficulty': difficulty,
        'ingredients': ingredients,
        'instructions': instructions,
        'is_public': isPublic,
        'author_name': authorName,
      });

      await loadRecipes();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.from('custom_recipes').delete().eq('id', recipeId);
      await loadRecipes();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final customRecipesProvider =
    StateNotifierProvider<CustomRecipesNotifier, CustomRecipesState>((ref) {
  final authState = ref.watch(authProvider);
  return CustomRecipesNotifier(userId: authState.user?.id);
});

// Own recipes (private + public by me)
final ownRecipesProvider = Provider<List<CustomRecipe>>((ref) {
  final state = ref.watch(customRecipesProvider);
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  return state.recipes.where((r) => r.userId == userId).toList();
});

// Community (public) recipes from all users
final communityRecipesProvider = Provider<List<CustomRecipe>>((ref) {
  final state = ref.watch(customRecipesProvider);
  return state.recipes.where((r) => r.isPublic).toList();
});
