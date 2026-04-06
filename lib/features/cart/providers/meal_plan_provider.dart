import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';

// Current Meal Plan Provider
final currentMealPlanProvider = StateNotifierProvider<MealPlanNotifier, MealPlan?>((ref) {
  return MealPlanNotifier();
});

class MealPlanNotifier extends StateNotifier<MealPlan?> {
  // Store all week plans in memory
  final Map<String, MealPlan> _weekPlans = {};

  MealPlanNotifier() : super(null) {
    _initializeWeek();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final normalizedWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final weekId = 'week_${normalizedWeekStart.millisecondsSinceEpoch}';

    // Check if we already have a plan for this week
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
    // Calculate which week this date belongs to
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

    // Get or create the plan for the correct week
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

    // Add meal to the target week
    targetPlan = targetPlan.copyWith(
      meals: [...targetPlan.meals, newMeal],
    );

    // Update the map
    _weekPlans[weekId] = targetPlan;

    // Navigate to the week where the meal was added
    state = targetPlan;
  }

  void removeMeal(String mealId) {
    if (state == null) return;

    state = state!.copyWith(
      meals: state!.meals.where((meal) => meal.id != mealId).toList(),
    );
    _weekPlans[state!.id] = state!;
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
  }

  void clearWeek() {
    if (state == null) return;

    state = state!.copyWith(meals: []);
    _weekPlans[state!.id] = state!;
  }

  void nextWeek() {
    if (state == null) return;

    final newWeekStart = state!.weekStart.add(const Duration(days: 7));
    final weekId = 'week_${newWeekStart.millisecondsSinceEpoch}';

    // Check if we already have a plan for this week
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

    // Check if we already have a plan for this week
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
  ShoppingListItemsNotifier() : super({});

  void togglePurchased(String itemId) {
    state = {
      ...state,
      itemId: !(state[itemId] ?? false),
    };
  }

  void clearAll() {
    state = {};
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
  CustomShoppingListItemsNotifier() : super([]);

  void addItem(String name, {double quantity = 1.0, String unit = 'Stück'}) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = ShoppingListItem(
      id: id,
      ingredientName: name,
      totalQuantity: quantity,
      unit: unit,
      sources: [], // Custom items have no deal sources
      category: 'Manuell hinzugefügt',
    );

    state = [...state, newItem];
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  void clearAll() {
    state = [];
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
