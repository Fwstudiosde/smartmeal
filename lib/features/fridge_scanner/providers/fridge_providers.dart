import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/ai_service.dart';

// Ingredients state notifier
class IngredientsNotifier extends StateNotifier<List<Ingredient>> {
  IngredientsNotifier() : super([]);

  void setIngredients(List<Ingredient> ingredients) {
    state = ingredients;
  }

  void addIngredient(Ingredient ingredient) {
    state = [...state, ingredient];
  }

  void removeIngredient(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void updateIngredient(Ingredient ingredient) {
    state = state.map((i) => i.id == ingredient.id ? ingredient : i).toList();
  }

  void clearIngredients() {
    state = [];
  }
}

final ingredientsProvider = StateNotifierProvider<IngredientsNotifier, List<Ingredient>>((ref) {
  return IngredientsNotifier();
});

// Recipes state
class RecipesNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final Ref ref;
  
  RecipesNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> generateRecipes() async {
    final ingredients = ref.read(ingredientsProvider);
    
    if (ingredients.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final recipes = await aiService.generateRecipes(ingredients);
      state = AsyncValue.data(recipes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clearRecipes() {
    state = const AsyncValue.data([]);
  }
}

final recipesProvider = StateNotifierProvider<RecipesNotifier, AsyncValue<List<Recipe>>>((ref) {
  return RecipesNotifier(ref);
});

// Selected recipe for detail view
final selectedRecipeProvider = StateProvider<Recipe?>((ref) => null);

// Filter options for recipes
enum RecipeFilter { all, quick, easy, highMatch }

final recipeFilterProvider = StateProvider<RecipeFilter>((ref) => RecipeFilter.all);

// Filtered recipes
final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final recipesAsync = ref.watch(recipesProvider);
  final filter = ref.watch(recipeFilterProvider);
  
  return recipesAsync.when(
    data: (recipes) {
      List<Recipe> filtered;
      
      switch (filter) {
        case RecipeFilter.quick:
          filtered = recipes.where((r) => r.totalTime <= 30).toList();
          break;
        case RecipeFilter.easy:
          filtered = recipes.where((r) => r.difficulty == 'easy').toList();
          break;
        case RecipeFilter.highMatch:
          filtered = recipes.where((r) => (r.matchPercentage ?? 0) >= 80).toList();
          break;
        case RecipeFilter.all:
        default:
          filtered = recipes;
      }
      
      // Sort by match percentage
      filtered.sort((a, b) => 
        (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0)
      );
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Ingredient categories for filtering
final selectedCategoryProvider = StateProvider<IngredientCategory?>((ref) => null);

final filteredIngredientsProvider = Provider<List<Ingredient>>((ref) {
  final ingredients = ref.watch(ingredientsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  if (selectedCategory == null) {
    return ingredients;
  }
  
  return ingredients.where((i) => 
    i.category?.toLowerCase() == selectedCategory.name.toLowerCase()
  ).toList();
});
