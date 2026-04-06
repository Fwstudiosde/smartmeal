import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/models/models.dart';
import '../../../core/services/deals_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/recipe_api_client.dart';
import '../../../core/config/supabase_config.dart';

// Service Providers
final aiServiceProvider = Provider((ref) => AIService());
final recipeApiClientProvider = Provider((ref) => RecipeApiClient());

// Selected Supermarkets Provider
final selectedSupermarketsProvider =
    StateNotifierProvider<SelectedSupermarketsNotifier, Set<String>>((ref) {
  return SelectedSupermarketsNotifier();
});

class SelectedSupermarketsNotifier extends StateNotifier<Set<String>> {
  SelectedSupermarketsNotifier() : super({});

  void toggle(String supermarketId) {
    if (state.contains(supermarketId)) {
      state = {...state}..remove(supermarketId);
    } else {
      state = {...state, supermarketId};
    }
  }

  void selectAll(List<String> ids) {
    state = ids.toSet();
  }

  void clear() {
    state = {};
  }
}

// Supermarkets Provider
final supermarketsProvider = FutureProvider<List<Supermarket>>((ref) async {
  final dealsService = ref.watch(dealsServiceProvider);
  return dealsService.getSupermarkets();
});

// Deals Provider
final dealsProvider = FutureProvider<List<Deal>>((ref) async {
  final dealsService = ref.watch(dealsServiceProvider);
  final selectedSupermarkets = ref.watch(selectedSupermarketsProvider);

  if (selectedSupermarkets.isEmpty) {
    return dealsService.fetchDeals();
  }

  return dealsService.fetchDeals(storeIds: selectedSupermarkets.toList());
});

// Deals By Supermarket Provider
final dealsBySupermarketProvider =
    Provider<Map<String, List<Deal>>>((ref) {
  final dealsAsync = ref.watch(dealsProvider);
  
  return dealsAsync.when(
    data: (deals) {
      final Map<String, List<Deal>> grouped = {};
      for (final deal in deals) {
        if (!grouped.containsKey(deal.storeName)) {
          grouped[deal.storeName] = [];
        }
        grouped[deal.storeName]!.add(deal);
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Deal Recipes Provider
final dealRecipesProvider = FutureProvider<List<DealRecipe>>((ref) async {
  final dealsAsync = ref.watch(dealsProvider);
  
  return dealsAsync.when(
    data: (deals) async {
      if (deals.isEmpty) {
        return [];
      }
      
      final aiService = ref.read(aiServiceProvider);
      return aiService.generateDealRecipes(deals);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Loading State for Deal Recipes
final isGeneratingRecipesProvider = StateProvider<bool>((ref) => false);

// Generate Deal Recipes Action
final generateDealRecipesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(isGeneratingRecipesProvider.notifier).state = true;
    
    try {
      // This will trigger the dealRecipesProvider to refresh
      ref.invalidate(dealRecipesProvider);
      await ref.read(dealRecipesProvider.future);
    } finally {
      ref.read(isGeneratingRecipesProvider.notifier).state = false;
    }
  };
});

// Total Savings Provider
final totalSavingsProvider = Provider<double>((ref) {
  final dealRecipesAsync = ref.watch(dealRecipesProvider);
  
  return dealRecipesAsync.when(
    data: (recipes) {
      return recipes.fold<double>(0, (sum, dr) => sum + dr.totalSavings);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Deal Category Filter Provider
final dealCategoryFilterProvider = StateProvider<String?>((ref) => null);

// Filtered Deals Provider
final filteredDealsProvider = Provider<List<Deal>>((ref) {
  final dealsAsync = ref.watch(dealsProvider);
  final categoryFilter = ref.watch(dealCategoryFilterProvider);
  
  return dealsAsync.when(
    data: (deals) {
      if (categoryFilter == null || categoryFilter.isEmpty) {
        return deals;
      }
      return deals.where((d) => d.category == categoryFilter).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Deal Categories Provider
final dealCategoriesProvider = Provider<List<String>>((ref) {
  final dealsAsync = ref.watch(dealsProvider);

  return dealsAsync.when(
    data: (deals) {
      final categories = deals
          .map((d) => d.category)
          .where((c) => c != null)
          .cast<String>()
          .toSet()
          .toList();
      categories.sort();
      return categories;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ==================== NEW RECIPE API PROVIDERS ====================

// Recipe Categories Provider
final recipeCategoriesProvider = FutureProvider<List<RecipeCategory>>((ref) async {
  final apiClient = ref.watch(recipeApiClientProvider);
  return apiClient.getCategories();
});

// Matched Recipes Provider (using new backend API)
final matchedRecipesProvider = FutureProvider<MatchedRecipesResponse>((ref) async {
  final apiClient = ref.watch(recipeApiClientProvider);

  // Get matched recipes from backend with default parameters
  return apiClient.getRecipesWithDeals(
    minCoverage: 0.5,  // 50% minimum coverage
    matchThreshold: 70, // 70% fuzzy match threshold
    limit: 50,          // Limit to 50 recipes
  );
});

// Matched Recipes by Category Provider
final matchedRecipesByCategoryProvider =
    FutureProvider.family<MatchedRecipesResponse, String?>((ref, category) async {
  final apiClient = ref.watch(recipeApiClientProvider);

  return apiClient.getRecipesWithDeals(
    minCoverage: 0.5,
    matchThreshold: 70,
    category: category,
  );
});

// Single Recipe Provider
final recipeByIdProvider =
    FutureProvider.family<MatchedRecipe, String>((ref, recipeId) async {
  final apiClient = ref.watch(recipeApiClientProvider);
  return apiClient.getRecipeById(recipeId);
});

// Use backend recipe matching API directly (without complex model conversion)
// Returns recipes with deals if available, otherwise returns all recipes
final apiDealRecipesProvider = FutureProvider<List<DealRecipe>>((ref) async {
  try {
    // First try to get recipes with deals from Edge Function
    final dealsResponse = await http.get(
      Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/recipes-with-deals?min_coverage=0.5&limit=50'),
      headers: {
        'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
      },
    );

    if (dealsResponse.statusCode != 200) {
      throw Exception('Failed to load recipes: ${dealsResponse.statusCode}');
    }

    final dealsData = json.decode(dealsResponse.body) as Map<String, dynamic>;
    final recipesWithDeals = dealsData['recipes'] as List<dynamic>;

    // If we found recipes with deals, return them
    if (recipesWithDeals.isNotEmpty) {
      return recipesWithDeals.map((recipeJson) {
        return _parseDealRecipe(recipeJson);
      }).toList();
    }

    // No recipes with deals found - return empty list
    // Note: In serverless mode, we only return recipes that have matching deals
    print('No recipes with deals found');
    return [];

  } catch (e) {
    print('Error loading recipes from API: $e');
    return [];
  }
});

// Helper function to parse deal recipe from JSON
DealRecipe _parseDealRecipe(Map<String, dynamic> recipeJson) {
  // Parse instructions from backend (array of {step_number, instruction})
  final instructionsData = recipeJson['instructions'] as List<dynamic>? ?? [];
  final instructions = instructionsData
      .map((inst) => inst['instruction'] as String)
      .toList();

  // Parse ingredients from backend FIRST
  final ingredientsData = recipeJson['ingredients'] as List<dynamic>? ?? [];
  final recipeIngredients = ingredientsData.map((ing) {
    return RecipeIngredient(
      name: (ing['ingredient_name'] ?? ing['name']) as String,
      quantity: (ing['quantity'] ?? '1') as String,
      unit: (ing['unit'] ?? 'Stück') as String,
      isAvailable: false,
    );
  }).toList();

  // Parse recipe basic info
  final category = recipeJson['category'] as String?;
  final recipe = Recipe(
    id: recipeJson['id'] as String,
    name: recipeJson['name'] as String,
    description: recipeJson['description'] as String,
    imageUrl: recipeJson['image_url'] as String?,
    prepTime: recipeJson['prep_time'] as int,
    cookTime: recipeJson['cook_time'] as int,
    servings: recipeJson['servings'] as int,
    difficulty: recipeJson['difficulty'] as String,
    ingredients: recipeIngredients, // Use ingredients from backend
    instructions: instructions,
    tags: category != null ? [category] : [],
    matchPercentage: ((recipeJson['score_breakdown']?['coverage_percentage'] as num?) ?? 0).toDouble(),
    nutrition: recipeJson['calories'] != null
        ? NutritionInfo(
            calories: (recipeJson['calories'] as num?)?.toInt() ?? 0,
            protein: (recipeJson['protein'] as num?)?.toDouble() ?? 0,
            carbs: (recipeJson['carbs'] as num?)?.toDouble() ?? 0,
            fat: (recipeJson['fat'] as num?)?.toDouble() ?? 0,
            fiber: (recipeJson['fiber'] as num?)?.toDouble() ?? 0,
          )
        : null,
  );

  // Parse matched deals
  final matchedDeals = recipeJson['matched_deals'] as List<dynamic>;
  final dealIngredients = matchedDeals.map((dealJson) {
    final deal = dealJson['deal'] as Map<String, dynamic>;
    final ingredientName = dealJson['ingredient_name'] as String;

    // Find the corresponding ingredient in the recipe to get the correct quantity
    final recipeIngredient = recipeIngredients.firstWhere(
      (ing) => ing.name.toLowerCase() == ingredientName.toLowerCase(),
      orElse: () => RecipeIngredient(
        name: ingredientName,
        quantity: '1',
        unit: 'Stück',
        isAvailable: false,
      ),
    );

    return DealIngredient(
      ingredient: RecipeIngredient(
        name: ingredientName,
        quantity: recipeIngredient.quantity,
        unit: recipeIngredient.unit,
        isAvailable: true,
      ),
      deal: Deal(
        id: '', // Backend doesn't provide deal ID
        productName: deal['product_name'] as String,
        storeName: deal['store_name'] as String,
        storeLogoUrl: '', // Will be filled from Supermarket.all
        originalPrice: ((deal['original_price'] as num?) ?? 0).toDouble(),
        discountPrice: ((deal['discount_price'] as num?) ?? 0).toDouble(),
        discountPercentage: ((deal['discount_percentage'] as num?) ?? 0).toDouble(),
        imageUrl: deal['image_url'] as String?,
        validFrom: DateTime.parse(deal['valid_from'] as String),
        validUntil: DateTime.parse(deal['valid_until'] as String),
        category: deal['category'] as String?,
        description: deal['description'] as String?,
      ),
      storeName: deal['store_name'] as String,
      price: ((deal['discount_price'] as num?) ?? 0).toDouble(),
      savings: (((deal['original_price'] as num?) ?? 0).toDouble() - ((deal['discount_price'] as num?) ?? 0).toDouble()),
    );
  }).toList();

  // Calculate total cost and savings
  final totalCost = dealIngredients.fold<double>(0.0, (sum, di) => sum + di.price);
  final totalSavings = dealIngredients.fold<double>(0.0, (sum, di) => sum + (di.savings ?? 0.0));

  return DealRecipe(
    recipe: recipe,
    dealIngredients: dealIngredients,
    totalCost: totalCost,
    totalSavings: totalSavings,
  );
}

// ==================== ALL RECIPES PROVIDER (NO DEAL FILTER) ====================

// All Recipes Provider - shows all recipes from database without deal matching
final allRecipesProvider = FutureProvider<List<DealRecipe>>((ref) async {
  try {
    // Get all recipes directly from Supabase
    final response = await http.get(
      Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/recipes?select=*,ingredients:recipe_ingredients(*),instructions:recipe_instructions(*)&order=created_at.desc&limit=100'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }

    final recipesData = json.decode(response.body) as List<dynamic>;

    // Convert to DealRecipe format (without deals)
    return recipesData.map((recipeJson) {
      return _parseAllRecipe(recipeJson);
    }).toList();

  } catch (e) {
    print('Error loading all recipes: $e');
    return [];
  }
});

// Helper function to parse recipe from JSON (without deals)
DealRecipe _parseAllRecipe(Map<String, dynamic> recipeJson) {
  // Parse instructions
  final instructionsData = recipeJson['instructions'] as List<dynamic>? ?? [];
  final instructions = instructionsData
      .map((inst) => inst['instruction'] as String)
      .toList();

  // Parse ingredients
  final ingredientsData = recipeJson['ingredients'] as List<dynamic>? ?? [];
  final recipeIngredients = ingredientsData.map((ing) {
    return RecipeIngredient(
      name: (ing['ingredient_name'] ?? ing['name']) as String,
      quantity: (ing['quantity'] ?? '1') as String,
      unit: (ing['unit'] ?? 'Stück') as String,
      isAvailable: false,
    );
  }).toList();

  // Parse recipe basic info
  final recipe = Recipe(
    id: recipeJson['id'] as String,
    name: recipeJson['name'] as String,
    description: recipeJson['description'] as String? ?? '',
    imageUrl: recipeJson['image_url'] as String?,
    prepTime: recipeJson['prep_time'] as int? ?? 0,
    cookTime: recipeJson['cook_time'] as int? ?? 0,
    servings: recipeJson['servings'] as int? ?? 1,
    difficulty: recipeJson['difficulty'] as String? ?? 'medium',
    ingredients: recipeIngredients,
    instructions: instructions,
    tags: [],
    matchPercentage: 0,
    nutrition: recipeJson['calories'] != null
        ? NutritionInfo(
            calories: (recipeJson['calories'] as num?)?.toInt() ?? 0,
            protein: (recipeJson['protein'] as num?)?.toDouble() ?? 0,
            carbs: (recipeJson['carbs'] as num?)?.toDouble() ?? 0,
            fat: (recipeJson['fat'] as num?)?.toDouble() ?? 0,
            fiber: (recipeJson['fiber'] as num?)?.toDouble() ?? 0,
          )
        : null,
  );

  return DealRecipe(
    recipe: recipe,
    dealIngredients: [], // No deals for all recipes mode
    totalCost: 0,
    totalSavings: 0,
  );
}

// ==================== UI STATE PROVIDERS ====================

// Savings Mode Provider - true = show only recipes with deals, false = show all recipes
final savingsModeProvider = StateProvider<bool>((ref) => true);

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Show Search Bar Provider
final showSearchBarProvider = StateProvider<bool>((ref) => false);

// Combined Recipes Provider - combines savings mode and search
final combinedRecipesProvider = FutureProvider<List<DealRecipe>>((ref) async {
  final savingsMode = ref.watch(savingsModeProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();

  // Get recipes based on mode
  List<DealRecipe> recipes;
  if (savingsMode) {
    // Savings mode: only recipes with deals
    final dealRecipesAsync = await ref.watch(apiDealRecipesProvider.future);
    recipes = dealRecipesAsync;
  } else {
    // All recipes mode
    final allRecipesAsync = await ref.watch(allRecipesProvider.future);
    recipes = allRecipesAsync;
  }

  // Apply search filter
  if (searchQuery.isEmpty) {
    return recipes;
  }

  return recipes.where((dealRecipe) {
    final name = dealRecipe.recipe.name.toLowerCase();
    final description = dealRecipe.recipe.description.toLowerCase();
    final ingredients = dealRecipe.recipe.ingredients
        .map((i) => i.name.toLowerCase())
        .join(' ');

    return name.contains(searchQuery) ||
           description.contains(searchQuery) ||
           ingredients.contains(searchQuery);
  }).toList();
});
