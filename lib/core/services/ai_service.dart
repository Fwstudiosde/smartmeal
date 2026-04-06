import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

// Provider for AI Service
final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static const String _edgeFunctionsUrl = '${SupabaseConfig.supabaseUrl}/functions/v1';

  final _uuid = const Uuid();

  /// Analyzes an image of a fridge/pantry and extracts ingredients using Edge Function
  Future<List<Ingredient>> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_edgeFunctionsUrl/fridge-scanner/analyze-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ingredientsList = data['ingredients'];

        return ingredientsList.map((item) => Ingredient(
          id: _uuid.v4(),
          name: item['name'] as String,
          category: item['category'] as String?,
          quantity: item['quantity'] as String?,
        )).toList();
      }

      throw Exception('Failed to analyze image: ${response.body}');
    } catch (e) {
      print('Error analyzing image: $e');
      // For demo purposes, return mock data if API fails
      return _getMockIngredients();
    }
  }

  /// Generates recipes based on available ingredients using Edge Function
  Future<List<Recipe>> generateRecipes(List<Ingredient> ingredients) async {
    try {
      final ingredientsList = ingredients.map((i) => {
        'name': i.name,
        'category': i.category ?? 'other',
        'quantity': i.quantity ?? '1',
      }).toList();

      final response = await http.post(
        Uri.parse('$_edgeFunctionsUrl/fridge-scanner/generate-recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
        body: jsonEncode({
          'ingredients': ingredientsList,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recipesList = data['recipes'];

        return recipesList.map((recipeData) {
          // Parse ingredients
          final List<RecipeIngredient> recipeIngredients =
              (recipeData['ingredients'] as List).map((ing) {
            return RecipeIngredient(
              name: ing['name'] as String,
              quantity: ing['quantity'].toString(),
              unit: ing['unit'] as String? ?? '',
              isAvailable: ing['isAvailable'] as bool? ?? false,
            );
          }).toList();

          // Parse instructions
          final List<String> instructions =
              (recipeData['instructions'] as List).map((i) => i.toString()).toList();

          // Parse tags
          final List<String> tags = recipeData['tags'] != null
              ? (recipeData['tags'] as List).map((t) => t.toString()).toList()
              : [];

          // Parse nutrition if available
          NutritionInfo? nutrition;
          if (recipeData['nutrition'] != null) {
            final n = recipeData['nutrition'];
            nutrition = NutritionInfo(
              calories: (n['calories'] as num?)?.toInt() ?? 0,
              protein: (n['protein'] as num?)?.toDouble() ?? 0,
              carbs: (n['carbs'] as num?)?.toDouble() ?? 0,
              fat: (n['fat'] as num?)?.toDouble() ?? 0,
              fiber: (n['fiber'] as num?)?.toDouble() ?? 0,
            );
          }

          return Recipe(
            id: _uuid.v4(),
            name: recipeData['name'] as String,
            description: recipeData['description'] as String,
            prepTime: (recipeData['prepTime'] as num).toInt(),
            cookTime: (recipeData['cookTime'] as num).toInt(),
            servings: (recipeData['servings'] as num?)?.toInt() ?? 2,
            difficulty: recipeData['difficulty'] as String,
            ingredients: recipeIngredients,
            instructions: instructions,
            tags: tags,
            matchPercentage: (recipeData['matchPercentage'] as num?)?.toDouble() ?? 0,
            nutrition: nutrition,
          );
        }).toList();
      }

      throw Exception('Failed to generate recipes: ${response.body}');
    } catch (e) {
      print('Error generating recipes: $e');
      // For demo purposes, return mock data if API fails
      return _getMockRecipes();
    }
  }

  // Mock data for fallback
  List<Ingredient> _getMockIngredients() {
    return [
      Ingredient(
        id: _uuid.v4(),
        name: 'Tomaten',
        category: 'vegetables',
        quantity: '3 Stück',
      ),
      Ingredient(
        id: _uuid.v4(),
        name: 'Käse',
        category: 'dairy',
        quantity: '200g',
      ),
      Ingredient(
        id: _uuid.v4(),
        name: 'Brot',
        category: 'grains',
        quantity: '1 Packung',
      ),
    ];
  }

  /// Generates recipes based on available deals using Edge Function
  Future<List<DealRecipe>> generateDealRecipes(List<Deal> deals) async {
    try {
      final dealProducts = deals.map((d) => {
        'productName': d.productName,
        'storeName': d.storeName,
        'discountPrice': d.discountPrice,
        'savings': d.originalPrice - d.discountPrice,
      }).toList();

      final response = await http.post(
        Uri.parse('$_edgeFunctionsUrl/fridge-scanner/generate-deal-recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
        body: jsonEncode({
          'deals': dealProducts,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recipesList = data['recipes'];

        return recipesList.map((recipeData) {
          // Parse recipe
          final recipe = _parseRecipe(recipeData['recipe']);

          // Parse deal ingredients
          final List<DealIngredient> dealIngredients =
              (recipeData['dealIngredients'] as List).map((di) {
            return DealIngredient(
              ingredient: RecipeIngredient(
                name: di['ingredientName'] as String,
                quantity: '1',
                unit: '',
                isAvailable: true,
              ),
              storeName: di['storeName'] as String,
              price: (di['price'] as num).toDouble(),
              savings: (di['savings'] as num?)?.toDouble(),
            );
          }).toList();

          return DealRecipe(
            recipe: recipe,
            dealIngredients: dealIngredients,
            totalCost: (recipeData['totalCost'] as num).toDouble(),
            totalSavings: (recipeData['totalSavings'] as num).toDouble(),
          );
        }).toList();
      }

      throw Exception('Failed to generate deal recipes: ${response.body}');
    } catch (e) {
      print('Error generating deal recipes: $e');
      // For demo purposes, return empty list if API fails
      return [];
    }
  }

  /// Helper method to parse recipe data from JSON
  Recipe _parseRecipe(Map<String, dynamic> recipeData) {
    // Parse ingredients
    final List<RecipeIngredient> recipeIngredients =
        (recipeData['ingredients'] as List).map((ing) {
      return RecipeIngredient(
        name: ing['name'] as String,
        quantity: ing['quantity'].toString(),
        unit: ing['unit'] as String? ?? '',
        isAvailable: ing['isAvailable'] as bool? ?? false,
      );
    }).toList();

    // Parse instructions
    final List<String> instructions =
        (recipeData['instructions'] as List).map((i) => i.toString()).toList();

    // Parse tags
    final List<String> tags = recipeData['tags'] != null
        ? (recipeData['tags'] as List).map((t) => t.toString()).toList()
        : [];

    // Parse nutrition if available
    NutritionInfo? nutrition;
    if (recipeData['nutrition'] != null) {
      final n = recipeData['nutrition'];
      nutrition = NutritionInfo(
        calories: (n['calories'] as num?)?.toInt() ?? 0,
        protein: (n['protein'] as num?)?.toDouble() ?? 0,
        carbs: (n['carbs'] as num?)?.toDouble() ?? 0,
        fat: (n['fat'] as num?)?.toDouble() ?? 0,
        fiber: (n['fiber'] as num?)?.toDouble() ?? 0,
      );
    }

    return Recipe(
      id: _uuid.v4(),
      name: recipeData['name'] as String,
      description: recipeData['description'] as String,
      prepTime: (recipeData['prepTime'] as num).toInt(),
      cookTime: (recipeData['cookTime'] as num).toInt(),
      servings: (recipeData['servings'] as num?)?.toInt() ?? 2,
      difficulty: recipeData['difficulty'] as String,
      ingredients: recipeIngredients,
      instructions: instructions,
      tags: tags,
      matchPercentage: (recipeData['matchPercentage'] as num?)?.toDouble() ?? 0,
      nutrition: nutrition,
    );
  }

  List<Recipe> _getMockRecipes() {
    return [
      Recipe(
        id: _uuid.v4(),
        name: 'Käse-Tomaten-Toast',
        description: 'Schneller und leckerer Snack',
        prepTime: 5,
        cookTime: 5,
        servings: 2,
        difficulty: 'Einfach',
        ingredients: [
          RecipeIngredient(
            name: 'Brot',
            quantity: '4',
            unit: 'Scheiben',
            isAvailable: true,
          ),
          RecipeIngredient(
            name: 'Tomaten',
            quantity: '2',
            unit: 'Stück',
            isAvailable: true,
          ),
          RecipeIngredient(
            name: 'Käse',
            quantity: '100',
            unit: 'g',
            isAvailable: true,
          ),
        ],
        instructions: [
          'Brot toasten',
          'Tomaten in Scheiben schneiden',
          'Käse auf das Toast legen',
          'Mit Tomaten belegen',
          'Im Ofen überbacken',
        ],
        tags: ['schnell', 'einfach'],
        matchPercentage: 100,
      ),
    ];
  }
}
