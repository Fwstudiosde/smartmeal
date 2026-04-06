import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/api/open_food_facts_client.dart';

// OpenFoodFacts client provider
final openFoodFactsProvider = Provider<OpenFoodFactsClient>((ref) {
  return OpenFoodFactsClient();
});

// Pantry items provider
final pantryProvider = StateNotifierProvider<PantryNotifier, List<PantryItem>>((ref) {
  return PantryNotifier();
});

class PantryNotifier extends StateNotifier<List<PantryItem>> {
  PantryNotifier() : super([]);

  void addItem(PantryItem item) {
    // Check if barcode already exists, increase quantity
    final existingIndex = state.indexWhere((i) => i.barcode == item.barcode);
    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + 1);
      state = [...state]..[existingIndex] = updated;
    } else {
      state = [item, ...state];
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void decreaseQuantity(String id) {
    final index = state.indexWhere((i) => i.id == id);
    if (index < 0) return;

    final item = state[index];
    if (item.quantity <= 1) {
      removeItem(id);
    } else {
      state = [...state]..[index] = item.copyWith(quantity: item.quantity - 1);
    }
  }

  void increaseQuantity(String id) {
    final index = state.indexWhere((i) => i.id == id);
    if (index < 0) return;

    state = [...state]..[index] = state[index].copyWith(
      quantity: state[index].quantity + 1,
    );
  }

  void clear() {
    state = [];
  }
}

// Filtered pantry by category
final pantryFilterProvider = StateProvider<String?>((ref) => null);

final filteredPantryProvider = Provider<List<PantryItem>>((ref) {
  final items = ref.watch(pantryProvider);
  final filter = ref.watch(pantryFilterProvider);

  if (filter == null) return items;
  return items.where((i) => i.category == filter).toList();
});

// Pantry stats
final pantryStatsProvider = Provider<PantryStats>((ref) {
  final items = ref.watch(pantryProvider);

  final totalItems = items.fold<int>(0, (sum, i) => sum + i.quantity);
  final categories = <String>{};
  for (final item in items) {
    if (item.category != null) categories.add(item.category!);
  }

  double avgCalories = 0;
  int itemsWithNutrition = 0;
  for (final item in items) {
    if (item.nutrition != null) {
      avgCalories += item.nutrition!.calories * item.quantity;
      itemsWithNutrition += item.quantity;
    }
  }
  if (itemsWithNutrition > 0) {
    avgCalories = avgCalories / itemsWithNutrition;
  }

  return PantryStats(
    totalProducts: items.length,
    totalItems: totalItems,
    categories: categories.length,
    avgCaloriesPer100g: avgCalories,
  );
});

class PantryStats {
  final int totalProducts;
  final int totalItems;
  final int categories;
  final double avgCaloriesPer100g;

  const PantryStats({
    required this.totalProducts,
    required this.totalItems,
    required this.categories,
    required this.avgCaloriesPer100g,
  });
}
