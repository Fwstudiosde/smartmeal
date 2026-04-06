import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/providers/auth_provider.dart';

class CustomRecipesState {
  final List<dynamic> recipes;
  final bool isLoading;
  final String? error;

  CustomRecipesState({
    this.recipes = const [],
    this.isLoading = false,
    this.error,
  });

  CustomRecipesState copyWith({
    List<dynamic>? recipes,
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
  final String baseUrl;
  final String? token;

  CustomRecipesNotifier({required this.baseUrl, this.token})
      : super(CustomRecipesState());

  Future<void> loadCustomRecipes() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/custom-recipes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipes = data['recipes'] ?? [];
        state = state.copyWith(recipes: recipes, isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Fehler beim Laden der Rezepte',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Convert ingredients to the format expected by the backend
      final ingredientsList = ingredients.map((ing) {
        return {
          'name': ing['name'],
          'quantity': ing['quantity'],
          'unit': ing['unit'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/custom-recipes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'prep_time': prepTime,
          'cook_time': cookTime,
          'servings': servings,
          'difficulty': difficulty,
          'ingredients': ingredientsList,
          'instructions': instructions,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload recipes after creation
        await loadCustomRecipes();
      } else {
        state = state.copyWith(
          error: 'Fehler beim Erstellen des Rezepts',
          isLoading: false,
        );
        throw Exception('Fehler beim Erstellen des Rezepts');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/custom-recipes/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Reload recipes after deletion
        await loadCustomRecipes();
      } else {
        state = state.copyWith(
          error: 'Fehler beim Löschen des Rezepts',
          isLoading: false,
        );
        throw Exception('Fehler beim Löschen des Rezepts');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final customRecipesProvider =
    StateNotifierProvider<CustomRecipesNotifier, CustomRecipesState>((ref) {
  final authState = ref.watch(authProvider);
  return CustomRecipesNotifier(
    baseUrl: 'https://mededsdvznbtunrxyqnn.supabase.co/functions/v1',
    token: authState.token,
  );
});
