import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/models.dart';

// Current Meal Plan Provider
final currentMealPlanProvider = StateNotifierProvider<MealPlanNotifier, MealPlan?>((ref) {
  return MealPlanNotifier();
});

class MealPlanNotifier extends StateNotifier<MealPlan?> {
  static const _boxName = 'recipes';
  static const _key = 'meal_plans';

  // Store all week plans
  final Map<String, MealPlan> _weekPlans = {};

  MealPlanNotifier() : super(null) {
    _loadFromHive();
    _initializeWeek();
  }

  void _loadFromHive() {
    try {
      final box = Hive.box(_boxName);
      final jsonMap = box.get(_key) as Map<dynamic, dynamic>?;
      if (jsonMap != null) {
        for (final entry in jsonMap.entries) {
          final plan = MealPlan.fromJson(
            Map<String, dynamic>.from(jsonDecode(entry.value as String)),
          );
          _weekPlans[entry.key as String] = plan;
        }
      }
    } catch (_) {
      // First launch or corrupted data
    }
  }

  void _saveToHive() {
    try {
      final box = Hive.box(_boxName);
      final jsonMap = <String, String>{};
      for (final entry in _weekPlans.entries) {
        jsonMap[entry.key] = jsonEncode(entry.value.toJson());
      }
      box.put(_key, jsonMap);
    } catch (_) {
      // Storage error
    }
  }

  void _initializeWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final normalizedWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final weekId = 'week_${normalizedWeekStart.millisecondsSinceEpoch}';

    if (_weekPlans.containsKey(weekId)) {
      state = _weekPlans[weekId];
    } else {
      state = MealPlan(
        id: weekId,
        weekStart: normalizedWeekStart,
        meals: [],
      );
      _weekPlans[weekId] = state!;
    }
  }

  void addMeal({
    required DealRecipe dealRecipe,
    required DateTime date,
    required MealType mealType,
    int servings = 2,
  }) {
    final mealWeekStart = date.subtract(Duration(days: date.weekday - 1));
    final normalizedMealWeekStart = DateTime(mealWeekStart.year, mealWeekStart.month, mealWeekStart.day);
    final weekId = 'week_${normalizedMealWeekStart.millisecondsSinceEpoch}';

    final newMeal = PlannedMeal(
      id: '${date.millisecondsSinceEpoch}_${mealType.name}',
      dealRecipe: dealRecipe,
      date: date,
      mealType: mealType,
      servings: servings,
    );

    MealPlan targetPlan;
    if (_weekPlans.containsKey(weekId)) {
      targetPlan = _weekPlans[weekId]!;
    } else {
      targetPlan = MealPlan(
        id: weekId,
        weekStart: normalizedMealWeekStart,
        meals: [],
      );
    }

    targetPlan = targetPlan.copyWith(
      meals: [...targetPlan.meals, newMeal],
    );

    _weekPlans[weekId] = targetPlan;
    state = targetPlan;
    _saveToHive();
  }

  void removeMeal(String mealId) {
    if (state == null) return;

    state = state!.copyWith(
      meals: state!.meals.where((meal) => meal.id != mealId).toList(),
    );
    _weekPlans[state!.id] = state!;
    _saveToHive();
  }

  void updateMealServings(String mealId, int newServings) {
    if (state == null) return;

    final meals = state!.meals.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(servings: newServings);
      }
      return meal;
    }).toList();

    state = state!.copyWith(meals: meals);
    _weekPlans[state!.id] = state!;
    _saveToHive();
  }

  void toggleMealCooked(String mealId) {
    if (state == null) return;

    final meals = state!.meals.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(isCooked: !meal.isCooked);
      }
      return meal;
    }).toList();

    state = state!.copyWith(meals: meals);
    _weekPlans[state!.id] = state!;
    _saveToHive();
  }

  void moveMeal(String mealId, DateTime newDate, MealType newMealType) {
    if (state == null) return;

    final meals = state!.meals.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(
          date: newDate,
          mealType: newMealType,
        );
      }
      return meal;
    }).toList();

    state = state!.copyWith(meals: meals);
    _weekPlans[state!.id] = state!;
    _saveToHive();
  }

  void clearWeek() {
    if (state == null) return;

    state = state!.copyWith(meals: []);
    _weekPlans[state!.id] = state!;
    _saveToHive();
  }

  void nextWeek() {
    if (state == null) return;

    final newWeekStart = state!.weekStart.add(const Duration(days: 7));
    final weekId = 'week_${newWeekStart.millisecondsSinceEpoch}';

    if (_weekPlans.containsKey(weekId)) {
      state = _weekPlans[weekId];
    } else {
      state = MealPlan(
        id: weekId,
        weekStart: newWeekStart,
        meals: [],
      );
      _weekPlans[weekId] = state!;
    }
  }

  void previousWeek() {
    if (state == null) return;

    final newWeekStart = state!.weekStart.subtract(const Duration(days: 7));
    final weekId = 'week_${newWeekStart.millisecondsSinceEpoch}';

    if (_weekPlans.containsKey(weekId)) {
      state = _weekPlans[weekId];
    } else {
      state = MealPlan(
        id: weekId,
        weekStart: newWeekStart,
        meals: [],
      );
      _weekPlans[weekId] = state!;
    }
  }
}

// Shopping List Provider
final shoppingListProvider = Provider<ShoppingList?>((ref) {
  final mealPlan = ref.watch(currentMealPlanProvider);

  if (mealPlan == null || mealPlan.meals.isEmpty) {
    return null;
  }

  return mealPlan.generateShoppingList();
});

// Shopping List Items State (for tracking purchased items)
final shoppingListItemsProvider = StateNotifierProvider<ShoppingListItemsNotifier, Map<String, bool>>((ref) {
  return ShoppingListItemsNotifier();
});

class ShoppingListItemsNotifier extends StateNotifier<Map<String, bool>> {
  static const _boxName = 'recipes';
  static const _key = 'shopping_list_checked';

  ShoppingListItemsNotifier() : super({}) {
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final box = Hive.box(_boxName);
      final saved = box.get(_key) as Map<dynamic, dynamic>?;
      if (saved != null) {
        state = Map<String, bool>.from(saved);
      }
    } catch (_) {}
  }

  void _saveToHive() {
    try {
      final box = Hive.box(_boxName);
      box.put(_key, state);
    } catch (_) {}
  }

  void togglePurchased(String itemId) {
    state = {
      ...state,
      itemId: !(state[itemId] ?? false),
    };
    _saveToHive();
  }

  void clearAll() {
    state = {};
    _saveToHive();
  }

  bool isPurchased(String itemId) {
    return state[itemId] ?? false;
  }
}

// Custom Shopping List Items Provider (for manually added items)
final customShoppingListItemsProvider = StateNotifierProvider<CustomShoppingListItemsNotifier, List<ShoppingListItem>>((ref) {
  return CustomShoppingListItemsNotifier();
});

class CustomShoppingListItemsNotifier extends StateNotifier<List<ShoppingListItem>> {
  static const _boxName = 'recipes';
  static const _key = 'custom_shopping_items';

  CustomShoppingListItemsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final box = Hive.box(_boxName);
      final jsonList = box.get(_key) as List<dynamic>?;
      if (jsonList != null) {
        state = jsonList.map((e) {
          final map = Map<String, dynamic>.from(jsonDecode(e as String));
          return ShoppingListItem(
            id: map['id'] as String,
            ingredientName: map['ingredientName'] as String,
            totalQuantity: (map['totalQuantity'] as num).toDouble(),
            unit: map['unit'] as String,
            sources: [],
            category: map['category'] as String?,
          );
        }).toList();
      }
    } catch (_) {}
  }

  void _saveToHive() {
    try {
      final box = Hive.box(_boxName);
      final jsonList = state.map((item) => jsonEncode({
        'id': item.id,
        'ingredientName': item.ingredientName,
        'totalQuantity': item.totalQuantity,
        'unit': item.unit,
        'category': item.category,
      })).toList();
      box.put(_key, jsonList);
    } catch (_) {}
  }

  void addItem(String name, {double quantity = 1.0, String unit = 'Stück'}) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = ShoppingListItem(
      id: id,
      ingredientName: name,
      totalQuantity: quantity,
      unit: unit,
      sources: [],
      category: 'Manuell hinzugefügt',
    );

    state = [...state, newItem];
    _saveToHive();
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
    _saveToHive();
  }

  void clearAll() {
    state = [];
    _saveToHive();
  }
}

// Filtered Shopping List by Store
final shoppingListByStoreProvider = Provider<Map<String, List<ShoppingListItem>>>((ref) {
  final shoppingList = ref.watch(shoppingListProvider);

  if (shoppingList == null) {
    return {};
  }

  return shoppingList.groupByStore();
});

// Week Days Provider
final weekDaysProvider = Provider<List<DateTime>>((ref) {
  final mealPlan = ref.watch(currentMealPlanProvider);

  if (mealPlan == null) {
    return [];
  }

  return List.generate(7, (index) {
    return mealPlan.weekStart.add(Duration(days: index));
  });
});

// Meals for specific date provider
final mealsForDateProvider = Provider.family<List<PlannedMeal>, DateTime>((ref, date) {
  final mealPlan = ref.watch(currentMealPlanProvider);

  if (mealPlan == null) {
    return [];
  }

  return mealPlan.getMealsForDate(date);
});
