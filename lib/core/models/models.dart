import 'package:flutter/material.dart';

// ==================== INGREDIENT MODEL ====================

class Ingredient {
  final String id;
  final String name;
  final String? quantity;
  final String? unit;
  final String? category;
  final DateTime? expiryDate;
  final String? imageUrl;
  
  const Ingredient({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    this.expiryDate,
    this.imageUrl,
  });
  
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expiryDate': expiryDate?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
  
  Ingredient copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? category,
    DateTime? expiryDate,
    String? imageUrl,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

// ==================== RECIPE MODEL ====================

class Recipe {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int prepTime; // in minutes
  final int cookTime; // in minutes
  final int servings;
  final String difficulty; // easy, medium, hard
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final double? matchPercentage; // How well it matches available ingredients
  final NutritionInfo? nutrition;
  
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    this.tags = const [],
    this.matchPercentage,
    this.nutrition,
  });
  
  int get totalTime => prepTime + cookTime;
  
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      prepTime: json['prepTime'] as int,
      cookTime: json['cookTime'] as int,
      servings: json['servings'] as int,
      difficulty: json['difficulty'] as String,
      ingredients: (json['ingredients'] as List)
          .map((e) => RecipeIngredient.fromJson(e))
          .toList(),
      instructions: List<String>.from(json['instructions'] as List),
      tags: List<String>.from(json['tags'] ?? []),
      matchPercentage: json['matchPercentage'] as double?,
      nutrition: json['nutrition'] != null 
          ? NutritionInfo.fromJson(json['nutrition'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'instructions': instructions,
      'tags': tags,
      'matchPercentage': matchPercentage,
      'nutrition': nutrition?.toJson(),
    };
  }
}

class RecipeIngredient {
  final String name;
  final String quantity;
  final String unit;
  final bool isAvailable;
  
  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.isAvailable = false,
  });
  
  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: (json['ingredient_name'] ?? json['name']) as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
      isAvailable: json['isAvailable'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isAvailable': isAvailable,
    };
  }
}

class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  
  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
  });
  
  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }
}

// ==================== PANTRY ITEM MODEL ====================

class PantryItem {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? nutriScore; // A, B, C, D, E
  final NutritionInfo? nutrition;
  final List<String> allergens;
  final String? category;
  final int quantity;
  final String? packagingSize; // e.g. "500g", "1L", "6 Stueck"
  final DateTime? expiryDate; // Mindesthaltbarkeitsdatum
  final DateTime addedAt;

  const PantryItem({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutriScore,
    this.nutrition,
    this.allergens = const [],
    this.category,
    this.quantity = 1,
    this.packagingSize,
    this.expiryDate,
    required this.addedAt,
  });

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon => expiryDate != null && !isExpired &&
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 3)));

  PantryItem copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    String? nutriScore,
    NutritionInfo? nutrition,
    List<String>? allergens,
    String? category,
    int? quantity,
    String? packagingSize,
    DateTime? expiryDate,
    DateTime? addedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      nutriScore: nutriScore ?? this.nutriScore,
      nutrition: nutrition ?? this.nutrition,
      allergens: allergens ?? this.allergens,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      packagingSize: packagingSize ?? this.packagingSize,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  factory PantryItem.fromOpenFoodFacts(String barcode, Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    NutritionInfo? nutrition;
    if (nutriments.isNotEmpty) {
      nutrition = NutritionInfo(
        calories: (nutriments['energy-kcal_100g'] as num?)?.toInt() ?? 0,
        protein: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0,
        carbs: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
        fat: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0,
        fiber: (nutriments['fiber_100g'] as num?)?.toDouble(),
      );
    }

    final allergensTags = product['allergens_tags'] as List<dynamic>? ?? [];
    final allergens = allergensTags
        .map((a) => a.toString().replaceAll('en:', '').replaceAll('de:', ''))
        .toList();

    return PantryItem(
      id: '${barcode}_${DateTime.now().millisecondsSinceEpoch}',
      barcode: barcode,
      name: product['product_name'] as String? ?? 'Unbekanntes Produkt',
      brand: product['brands'] as String?,
      imageUrl: product['image_front_small_url'] as String? ?? product['image_url'] as String?,
      nutriScore: (product['nutriscore_grade'] as String?)?.toUpperCase(),
      nutrition: nutrition,
      allergens: allergens,
      category: _mapCategory(product['categories_tags'] as List<dynamic>?),
      quantity: 1,
      addedAt: DateTime.now(),
    );
  }

  static String _mapCategory(List<dynamic>? tags) {
    if (tags == null || tags.isEmpty) return 'Sonstiges';
    final cat = tags.first.toString().toLowerCase();
    if (cat.contains('dairy') || cat.contains('milch')) return 'Milchprodukte';
    if (cat.contains('meat') || cat.contains('fleisch')) return 'Fleisch';
    if (cat.contains('fish') || cat.contains('fisch')) return 'Fisch';
    if (cat.contains('vegetable') || cat.contains('gemüse')) return 'Gemüse';
    if (cat.contains('fruit') || cat.contains('obst')) return 'Obst';
    if (cat.contains('beverage') || cat.contains('getränk')) return 'Getränke';
    if (cat.contains('snack')) return 'Snacks';
    if (cat.contains('bread') || cat.contains('brot') || cat.contains('cereal')) return 'Getreide';
    if (cat.contains('frozen') || cat.contains('tiefkühl')) return 'Tiefkühl';
    return 'Sonstiges';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'nutriScore': nutriScore,
      'nutrition': nutrition?.toJson(),
      'allergens': allergens,
      'category': category,
      'quantity': quantity,
      'packagingSize': packagingSize,
      'expiryDate': expiryDate?.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      nutriScore: json['nutriScore'] as String?,
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'])
          : null,
      allergens: List<String>.from(json['allergens'] ?? []),
      category: json['category'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      packagingSize: json['packagingSize'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

// ==================== DEAL MODEL ====================

class Deal {
  final String id;
  final String productName;
  final String storeName;
  final String storeLogoUrl;
  final double originalPrice;
  final double discountPrice;
  final double discountPercentage;
  final String? imageUrl;
  final DateTime validFrom;
  final DateTime validUntil;
  final String? category;
  final String? description;

  const Deal({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.storeLogoUrl,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountPercentage,
    this.imageUrl,
    required this.validFrom,
    required this.validUntil,
    this.category,
    this.description,
  });
  
  double get savings => originalPrice - discountPrice;
  
  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(validFrom) && now.isBefore(validUntil);
  }
  
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      productName: json['productName'] as String,
      storeName: json['storeName'] as String,
      storeLogoUrl: json['storeLogoUrl'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Factory for parsing backend API response
  factory Deal.fromBackendJson(Map<String, dynamic> json) {
    // Backend uses snake_case, we need to convert to Deal model
    final storeName = json['store_name'] as String;

    // Find matching supermarket for logo
    final supermarket = Supermarket.all.firstWhere(
      (s) => s.name.toLowerCase() == storeName.toLowerCase(),
      orElse: () => Supermarket(
        id: storeName.toLowerCase(),
        name: storeName,
        logoUrl: '',
        brandColor: const Color(0xFF000000),
      ),
    );

    // Parse prices with null safety
    final discountPrice = (json['discount_price'] as num?)?.toDouble() ?? 0.0;
    final originalPriceRaw = json['original_price'] as num?;
    final discountPercentageRaw = json['discount_percentage'] as num?;

    // Calculate missing values
    double originalPrice;
    double discountPercentage;

    if (originalPriceRaw != null) {
      originalPrice = originalPriceRaw.toDouble();
      discountPercentage = discountPercentageRaw?.toDouble() ??
          ((originalPrice - discountPrice) / originalPrice * 100);
    } else if (discountPercentageRaw != null) {
      discountPercentage = discountPercentageRaw.toDouble();
      originalPrice = discountPrice / (1 - discountPercentage / 100);
    } else {
      // Estimate 30% discount if nothing is provided
      discountPercentage = 30.0;
      originalPrice = discountPrice / 0.7;
    }

    return Deal(
      id: json['id'] as String? ??
          '${json['product_name']}_${json['store_name']}_${DateTime.now().millisecondsSinceEpoch}',
      productName: json['product_name'] as String,
      storeName: storeName,
      storeLogoUrl: supermarket.logoUrl,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      discountPercentage: discountPercentage,
      imageUrl: (json['image_url'] as String?)?.isNotEmpty == true
          ? json['image_url'] as String
          : null,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'storeName': storeName,
      'storeLogoUrl': storeLogoUrl,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'discountPercentage': discountPercentage,
      'imageUrl': imageUrl,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'category': category,
    };
  }
}

// ==================== DEAL RECIPE MODEL ====================

class DealRecipe {
  final Recipe recipe;
  final List<DealIngredient> dealIngredients;
  final double totalSavings;
  final double totalCost;
  
  const DealRecipe({
    required this.recipe,
    required this.dealIngredients,
    required this.totalSavings,
    required this.totalCost,
  });
  
  double get savingsPercentage => 
      totalSavings / (totalCost + totalSavings) * 100;
}

class DealIngredient {
  final RecipeIngredient ingredient;
  final Deal? deal;
  final String storeName;
  final double price;
  final double? savings;
  
  const DealIngredient({
    required this.ingredient,
    this.deal,
    required this.storeName,
    required this.price,
    this.savings,
  });
}

// ==================== SUPERMARKET MODEL ====================

class Supermarket {
  final String id;
  final String name;
  final String logoUrl;
  final Color brandColor;
  
  const Supermarket({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.brandColor,
  });
  
  static List<Supermarket> get all => [
    Supermarket(
      id: 'lidl',
      name: 'Lidl',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Lidl-Logo.svg/1200px-Lidl-Logo.svg.png',
      brandColor: const Color(0xFF0050AA),
    ),
    Supermarket(
      id: 'aldi',
      name: 'ALDI',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/AldiSudLogo.svg/1200px-AldiSudLogo.svg.png',
      brandColor: const Color(0xFF00005F),
    ),
    Supermarket(
      id: 'rewe',
      name: 'REWE',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Rewe_Markt_Logo.svg/1200px-Rewe_Markt_Logo.svg.png',
      brandColor: const Color(0xFFCC071E),
    ),
    Supermarket(
      id: 'edeka',
      name: 'EDEKA',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Edeka_logo.svg/1200px-Edeka_logo.svg.png',
      brandColor: const Color(0xFFFFED00),
    ),
    Supermarket(
      id: 'kaufland',
      name: 'Kaufland',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Kaufland_201x_logo.svg/1200px-Kaufland_201x_logo.svg.png',
      brandColor: const Color(0xFFE10915),
    ),
    Supermarket(
      id: 'penny',
      name: 'Penny',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Penny-Logo.svg/1200px-Penny-Logo.svg.png',
      brandColor: const Color(0xFFCD1719),
    ),
  ];
}

// ==================== INGREDIENT CATEGORY ====================

enum IngredientCategory {
  dairy('Milchprodukte', '🥛'),
  meat('Fleisch', '🥩'),
  fish('Fisch', '🐟'),
  vegetables('Gemüse', '🥬'),
  fruits('Obst', '🍎'),
  grains('Getreide', '🌾'),
  spices('Gewürze', '🌶️'),
  beverages('Getränke', '🥤'),
  frozen('Tiefkühl', '🧊'),
  snacks('Snacks', '🍪'),
  other('Sonstiges', '📦');

  final String label;
  final String emoji;

  const IngredientCategory(this.label, this.emoji);
}

// ==================== MEAL PLAN MODELS ====================

enum MealType {
  breakfast('Frühstück', '🍳'),
  lunch('Mittagessen', '🍽️'),
  dinner('Abendessen', '🌙'),
  snack('Snack', '🍪');

  final String label;
  final String emoji;

  const MealType(this.label, this.emoji);
}

class PlannedMeal {
  final String id;
  final DealRecipe dealRecipe;
  final DateTime date;
  final MealType mealType;
  final int servings;
  final bool isCooked;

  const PlannedMeal({
    required this.id,
    required this.dealRecipe,
    required this.date,
    required this.mealType,
    required this.servings,
    this.isCooked = false,
  });

  PlannedMeal copyWith({
    String? id,
    DealRecipe? dealRecipe,
    DateTime? date,
    MealType? mealType,
    int? servings,
    bool? isCooked,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      dealRecipe: dealRecipe ?? this.dealRecipe,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      servings: servings ?? this.servings,
      isCooked: isCooked ?? this.isCooked,
    );
  }
}

class ShoppingListItem {
  final String id;
  final String ingredientName;
  final double totalQuantity;
  final String unit;
  final List<DealIngredient> sources; // Which recipes need this ingredient
  final bool isPurchased;
  final String? category;

  const ShoppingListItem({
    required this.id,
    required this.ingredientName,
    required this.totalQuantity,
    required this.unit,
    required this.sources,
    this.isPurchased = false,
    this.category,
  });

  double get totalPrice => sources.fold(0.0, (sum, source) => sum + source.price);
  double get totalSavings => sources.fold(0.0, (sum, source) => sum + (source.savings ?? 0.0));

  ShoppingListItem copyWith({
    String? id,
    String? ingredientName,
    double? totalQuantity,
    String? unit,
    List<DealIngredient>? sources,
    bool? isPurchased,
    String? category,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      ingredientName: ingredientName ?? this.ingredientName,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      unit: unit ?? this.unit,
      sources: sources ?? this.sources,
      isPurchased: isPurchased ?? this.isPurchased,
      category: category ?? this.category,
    );
  }
}

class MealPlan {
  final String id;
  final DateTime weekStart;
  final List<PlannedMeal> meals;

  const MealPlan({
    required this.id,
    required this.weekStart,
    required this.meals,
  });

  DateTime get weekEnd => weekStart.add(const Duration(days: 7));

  List<PlannedMeal> getMealsForDate(DateTime date) {
    return meals.where((meal) =>
      meal.date.year == date.year &&
      meal.date.month == date.month &&
      meal.date.day == date.day
    ).toList();
  }

  double get totalCost => meals.fold(0.0, (sum, meal) => sum + meal.dealRecipe.totalCost);
  double get totalSavings => meals.fold(0.0, (sum, meal) => sum + meal.dealRecipe.totalSavings);

  ShoppingList generateShoppingList() {
    final Map<String, ShoppingListItem> items = {};

    for (final meal in meals) {
      if (meal.isCooked) continue; // Skip already cooked meals

      final servingsMultiplier = meal.servings / meal.dealRecipe.recipe.servings;

      for (final dealIngredient in meal.dealRecipe.dealIngredients) {
        final key = '${dealIngredient.ingredient.name}_${dealIngredient.ingredient.unit}';

        final quantity = double.tryParse(dealIngredient.ingredient.quantity) ?? 1.0;
        final adjustedQuantity = quantity * servingsMultiplier;

        if (items.containsKey(key)) {
          // Add to existing item
          final existing = items[key]!;
          items[key] = existing.copyWith(
            totalQuantity: existing.totalQuantity + adjustedQuantity,
            sources: [...existing.sources, dealIngredient],
          );
        } else {
          // Create new item
          items[key] = ShoppingListItem(
            id: key,
            ingredientName: dealIngredient.ingredient.name,
            totalQuantity: adjustedQuantity,
            unit: dealIngredient.ingredient.unit,
            sources: [dealIngredient],
          );
        }
      }
    }

    return ShoppingList(
      id: 'shopping_list_$id',
      mealPlanId: id,
      items: items.values.toList(),
      createdAt: DateTime.now(),
    );
  }

  MealPlan copyWith({
    String? id,
    DateTime? weekStart,
    List<PlannedMeal>? meals,
  }) {
    return MealPlan(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      meals: meals ?? this.meals,
    );
  }
}

class ShoppingList {
  final String id;
  final String mealPlanId;
  final List<ShoppingListItem> items;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.mealPlanId,
    required this.items,
    required this.createdAt,
  });

  double get totalCost => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalSavings => items.fold(0.0, (sum, item) => sum + item.totalSavings);

  int get purchasedCount => items.where((item) => item.isPurchased).length;
  int get totalCount => items.length;

  double get progress => totalCount > 0 ? purchasedCount / totalCount : 0.0;

  Map<String, List<ShoppingListItem>> groupByStore() {
    final Map<String, List<ShoppingListItem>> grouped = {};

    for (final item in items) {
      for (final source in item.sources) {
        final storeName = source.storeName;
        if (!grouped.containsKey(storeName)) {
          grouped[storeName] = [];
        }
        if (!grouped[storeName]!.contains(item)) {
          grouped[storeName]!.add(item);
        }
      }
    }

    return grouped;
  }

  ShoppingList copyWith({
    String? id,
    String? mealPlanId,
    List<ShoppingListItem>? items,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      mealPlanId: mealPlanId ?? this.mealPlanId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
