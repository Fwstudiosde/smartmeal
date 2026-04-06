import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../config/supabase_config.dart';

class RecipeApiClient {
  // Supabase Edge Functions URL
  static const String baseUrl = 'https://mededsdvznbtunrxyqnn.supabase.co/functions/v1';

  /// Get list of recipe categories with counts
  Future<List<RecipeCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-categories'),
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['categories'] != null) {
          final List<dynamic> categories = data['categories'];
          return categories.map((json) => RecipeCategory.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get recipes matched with current Kaufland deals
  ///
  /// Parameters:
  /// - minCoverage: Minimum percentage of ingredients with deals (0.0-1.0)
  /// - matchThreshold: Minimum fuzzy match score (0-100)
  /// - limit: Limit number of results
  /// - category: Filter by recipe category
  Future<MatchedRecipesResponse> getRecipesWithDeals({
    double minCoverage = 0.5,
    int matchThreshold = 70,
    int? limit,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'min_coverage': minCoverage.toString(),
      };

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse('$baseUrl/recipes-with-deals')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['recipes'] != null) {
          // Edge Function returns {success, recipes, total}
          // Convert to expected format
          final converted = {
            'total_matches': data['total'] ?? data['recipes'].length,
            'total_deals': 0,
            'filters': {
              'min_coverage': minCoverage,
              'match_threshold': matchThreshold,
            },
            'recipes': data['recipes'],
          };
          return MatchedRecipesResponse.fromJson(converted);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load recipes with deals: $e');
    }
  }

  /// Get complete details for a single recipe by ID
  Future<MatchedRecipe> getRecipeById(String recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recipes/$recipeId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MatchedRecipe.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Recipe not found');
      } else {
        throw Exception('Failed to load recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load recipe: $e');
    }
  }
}

// ==================== API MODELS ====================

class RecipeCategory {
  final String name;
  final int count;

  const RecipeCategory({
    required this.name,
    required this.count,
  });

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class MatchedRecipesResponse {
  final int totalMatches;
  final int totalDeals;
  final FilterInfo filters;
  final List<MatchedRecipe> recipes;

  const MatchedRecipesResponse({
    required this.totalMatches,
    required this.totalDeals,
    required this.filters,
    required this.recipes,
  });

  factory MatchedRecipesResponse.fromJson(Map<String, dynamic> json) {
    return MatchedRecipesResponse(
      totalMatches: json['total_matches'] as int,
      totalDeals: json['total_deals'] as int,
      filters: FilterInfo.fromJson(json['filters']),
      recipes: (json['recipes'] as List)
          .map((r) => MatchedRecipe.fromJson(r))
          .toList(),
    );
  }

}

class FilterInfo {
  final double minCoverage;
  final int matchThreshold;

  const FilterInfo({
    required this.minCoverage,
    required this.matchThreshold,
  });

  factory FilterInfo.fromJson(Map<String, dynamic> json) {
    return FilterInfo(
      minCoverage: (json['min_coverage'] as num).toDouble(),
      matchThreshold: json['match_threshold'] as int,
    );
  }
}

class MatchedRecipe {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final String category;
  final List<MatchedIngredient> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final NutritionInfo? nutrition;
  final double coverage;
  final int matchScore;
  final List<MatchedDeal> matchedDeals;

  const MatchedRecipe({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.category,
    required this.ingredients,
    required this.instructions,
    this.tags = const [],
    this.nutrition,
    required this.coverage,
    required this.matchScore,
    required this.matchedDeals,
  });

  int get totalTime => prepTime + cookTime;

  double get coveragePercentage => coverage * 100;

  /// Convert to Recipe model for UI compatibility
  Recipe toRecipe() {
    return Recipe(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: servings,
      difficulty: difficulty,
      ingredients: ingredients
          .map((mi) => RecipeIngredient(
                name: mi.name,
                quantity: mi.quantity,
                unit: mi.unit,
                isAvailable: mi.hasMatch,
              ))
          .toList(),
      instructions: instructions,
      tags: tags,
      matchPercentage: coveragePercentage,
      nutrition: nutrition,
    );
  }

  /// Calculate total savings from matched deals
  double get totalSavings {
    return matchedDeals.fold<double>(
      0.0,
      (sum, deal) => sum + (deal.savings ?? 0.0),
    );
  }

  /// Calculate total cost with deals
  double get totalCost {
    return matchedDeals.fold<double>(
      0.0,
      (sum, deal) => sum + deal.discountPrice,
    );
  }

  factory MatchedRecipe.fromJson(Map<String, dynamic> json) {
    return MatchedRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      prepTime: json['prep_time'] as int,
      cookTime: json['cook_time'] as int,
      servings: json['servings'] as int,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      ingredients: (json['ingredients'] as List)
          .map((i) => MatchedIngredient.fromJson(i))
          .toList(),
      instructions: List<String>.from(json['instructions'] as List),
      tags: List<String>.from(json['tags'] ?? []),
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'])
          : null,
      coverage: (json['coverage'] as num).toDouble(),
      matchScore: json['match_score'] as int,
      matchedDeals: (json['matched_deals'] as List)
          .map((d) => MatchedDeal.fromJson(d))
          .toList(),
    );
  }
}

class MatchedIngredient {
  final String name;
  final String quantity;
  final String unit;
  final int priority;
  final bool hasMatch;
  final String? matchedDealId;

  const MatchedIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.priority,
    required this.hasMatch,
    this.matchedDealId,
  });

  factory MatchedIngredient.fromJson(Map<String, dynamic> json) {
    return MatchedIngredient(
      name: json['name'] as String,
      quantity: json['quantity'].toString(),
      unit: json['unit'] as String,
      priority: json['priority'] as int,
      hasMatch: json['has_match'] as bool,
      matchedDealId: json['matched_deal_id'] as String?,
    );
  }
}

class MatchedDeal {
  final String id;
  final String productName;
  final String storeName;
  final double discountPrice;
  final double? originalPrice;
  final double? discountPercentage;
  final String? imageUrl;
  final String validFrom;
  final String validUntil;
  final int matchScore;
  final double? savings;

  const MatchedDeal({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.discountPrice,
    this.originalPrice,
    this.discountPercentage,
    this.imageUrl,
    required this.validFrom,
    required this.validUntil,
    required this.matchScore,
    this.savings,
  });

  /// Convert to Deal model for UI compatibility
  Deal toDeal() {
    final from = DateTime.parse(validFrom);
    final until = DateTime.parse(validUntil);

    // Find matching supermarket
    final supermarket = Supermarket.all.firstWhere(
      (s) => s.name.toLowerCase() == storeName.toLowerCase(),
      orElse: () => Supermarket.all.first,
    );

    // Calculate original price if not provided
    final origPrice = originalPrice ??
        (discountPercentage != null
            ? discountPrice / (1 - discountPercentage! / 100)
            : discountPrice / 0.7);

    final discPercent = discountPercentage ??
        ((origPrice - discountPrice) / origPrice * 100);

    return Deal(
      id: id,
      productName: productName,
      storeName: storeName,
      storeLogoUrl: supermarket.logoUrl,
      originalPrice: origPrice,
      discountPrice: discountPrice,
      discountPercentage: discPercent,
      imageUrl: imageUrl,
      validFrom: from,
      validUntil: until,
    );
  }

  factory MatchedDeal.fromJson(Map<String, dynamic> json) {
    return MatchedDeal(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      storeName: json['store_name'] as String,
      discountPrice: (json['discount_price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      validFrom: json['valid_from'] as String,
      validUntil: json['valid_until'] as String,
      matchScore: json['match_score'] as int,
      savings: (json['savings'] as num?)?.toDouble(),
    );
  }
}
