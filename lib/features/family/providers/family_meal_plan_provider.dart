import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/sync/sync_engine.dart';
import '../../../core/services/sync/sync_operation.dart';
import 'family_provider.dart';

enum FamilyMealType { breakfast, lunch, dinner, snack }

extension FamilyMealTypeX on FamilyMealType {
  String get dbValue => name;
  String get label {
    switch (this) {
      case FamilyMealType.breakfast:
        return 'Frühstück';
      case FamilyMealType.lunch:
        return 'Mittag';
      case FamilyMealType.dinner:
        return 'Abend';
      case FamilyMealType.snack:
        return 'Snack';
    }
  }
}

class FamilyPlannedMeal {
  final String id;
  final String mealPlanId;
  final DateTime date;
  final FamilyMealType mealType;
  final String? recipeName;      // stored in recipe_data
  final String? recipeImage;
  final int servings;
  final bool isCooked;
  final String? addedBy;

  FamilyPlannedMeal({
    required this.id,
    required this.mealPlanId,
    required this.date,
    required this.mealType,
    this.recipeName,
    this.recipeImage,
    this.servings = 2,
    this.isCooked = false,
    this.addedBy,
  });

  factory FamilyPlannedMeal.fromJson(Map<String, dynamic> j) {
    final data = j['recipe_data'];
    Map<String, dynamic> rd = {};
    if (data is Map) rd = Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        rd = Map<String, dynamic>.from(jsonDecode(data));
      } catch (_) {}
    }
    return FamilyPlannedMeal(
      id: j['id'] as String,
      mealPlanId: j['meal_plan_id'] as String,
      date: DateTime.parse(j['date'] as String),
      mealType: FamilyMealType.values
          .firstWhere((e) => e.name == j['meal_type'],
              orElse: () => FamilyMealType.dinner),
      recipeName: rd['name'] as String?,
      recipeImage: rd['image_url'] as String?,
      servings: (j['servings'] as int?) ?? 2,
      isCooked: (j['is_cooked'] as bool?) ?? false,
      addedBy: j['added_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'meal_plan_id': mealPlanId,
        'date': date.toIso8601String().substring(0, 10),
        'meal_type': mealType.name,
        'servings': servings,
        'is_cooked': isCooked,
        'added_by': addedBy,
        'recipe_data': jsonEncode({
          'name': recipeName,
          'image_url': recipeImage,
        }),
      };
}

class FamilyMealPlanState {
  final String? planId;
  final DateTime weekStart;
  final List<FamilyPlannedMeal> meals;
  final bool isLoading;
  final String? error;

  FamilyMealPlanState({
    this.planId,
    required this.weekStart,
    this.meals = const [],
    this.isLoading = false,
    this.error,
  });

  FamilyMealPlanState copyWith({
    String? planId,
    DateTime? weekStart,
    List<FamilyPlannedMeal>? meals,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      FamilyMealPlanState(
        planId: planId ?? this.planId,
        weekStart: weekStart ?? this.weekStart,
        meals: meals ?? this.meals,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

DateTime _startOfWeek(DateTime d) {
  final weekday = d.weekday; // 1..7 (Mon..Sun)
  return DateTime(d.year, d.month, d.day).subtract(Duration(days: weekday - 1));
}

class FamilyMealPlanNotifier extends StateNotifier<FamilyMealPlanState> {
  final Ref ref;
  final String familyId;
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();
  static const _cacheBox = 'family_cache';

  FamilyMealPlanNotifier(this.ref, this.familyId)
      : super(FamilyMealPlanState(weekStart: _startOfWeek(DateTime.now()))) {
    _loadCache();
    _fetch();
  }

  String _cacheKey(DateTime week) =>
      'meal_plan_${familyId}_${week.toIso8601String().substring(0, 10)}';

  void _loadCache() {
    try {
      final box = Hive.box(_cacheBox);
      final raw = box.get(_cacheKey(state.weekStart)) as String?;
      if (raw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        final planId = map['plan_id'] as String?;
        final meals = (map['meals'] as List?)
                ?.map((e) => FamilyPlannedMeal.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [];
        state = state.copyWith(planId: planId, meals: meals);
      }
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final box = Hive.box(_cacheBox);
      await box.put(
        _cacheKey(state.weekStart),
        jsonEncode({
          'plan_id': state.planId,
          'meals': state.meals.map((m) => m.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final weekIso = state.weekStart.toIso8601String().substring(0, 10);
      final uid = _client.auth.currentUser?.id;

      var planRes = await _client
          .from('meal_plans')
          .select('id')
          .eq('family_id', familyId)
          .eq('week_start', weekIso)
          .maybeSingle();

      String planId;
      if (planRes == null) {
        final created = await _client.from('meal_plans').insert({
          'user_id': uid,
          'family_id': familyId,
          'week_start': weekIso,
        }).select('id').single();
        planId = created['id'] as String;
      } else {
        planId = planRes['id'] as String;
      }

      final mealsRes = await _client
          .from('planned_meals')
          .select('*')
          .eq('meal_plan_id', planId)
          .order('date');

      final meals = (mealsRes as List)
          .map((e) => FamilyPlannedMeal.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(planId: planId, meals: meals, isLoading: false);
      await _saveCache();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> changeWeek(int deltaDays) async {
    state = FamilyMealPlanState(
      weekStart: state.weekStart.add(Duration(days: deltaDays)),
    );
    _loadCache();
    await _fetch();
  }

  Future<void> addMeal({
    required DateTime date,
    required FamilyMealType mealType,
    required String name,
    String? imageUrl,
    int servings = 2,
  }) async {
    final planId = state.planId;
    if (planId == null) return;
    final uid = _client.auth.currentUser?.id;

    final id = _uuid.v4();
    final meal = FamilyPlannedMeal(
      id: id,
      mealPlanId: planId,
      date: date,
      mealType: mealType,
      recipeName: name,
      recipeImage: imageUrl,
      servings: servings,
      addedBy: uid,
    );

    state = state.copyWith(meals: [...state.meals, meal]);
    await _saveCache();

    await ref.read(syncEngineProvider).enqueue(
          SyncOperation(
            id: _uuid.v4(),
            op: SyncOpType.insert,
            table: 'planned_meals',
            data: {
              'id': id,
              'meal_plan_id': planId,
              'date': date.toIso8601String().substring(0, 10),
              'meal_type': mealType.name,
              'servings': servings,
              'added_by': uid,
              'recipe_data': {
                'name': name,
                'image_url': imageUrl,
              },
            },
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await ref.read(syncEngineProvider).flush(isOnline: true);
  }

  Future<void> removeMeal(String mealId) async {
    state = state.copyWith(
      meals: state.meals.where((m) => m.id != mealId).toList(),
    );
    await _saveCache();
    await ref.read(syncEngineProvider).enqueue(
          SyncOperation(
            id: _uuid.v4(),
            op: SyncOpType.delete,
            table: 'planned_meals',
            rowId: mealId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await ref.read(syncEngineProvider).flush(isOnline: true);
  }

  Future<void> toggleCooked(String mealId) async {
    final idx = state.meals.indexWhere((m) => m.id == mealId);
    if (idx < 0) return;
    final m = state.meals[idx];
    final uid = _client.auth.currentUser?.id;
    final updated = FamilyPlannedMeal(
      id: m.id,
      mealPlanId: m.mealPlanId,
      date: m.date,
      mealType: m.mealType,
      recipeName: m.recipeName,
      recipeImage: m.recipeImage,
      servings: m.servings,
      isCooked: !m.isCooked,
      addedBy: m.addedBy,
    );
    final newList = [...state.meals];
    newList[idx] = updated;
    state = state.copyWith(meals: newList);
    await _saveCache();

    await ref.read(syncEngineProvider).enqueue(
          SyncOperation(
            id: _uuid.v4(),
            op: SyncOpType.update,
            table: 'planned_meals',
            rowId: mealId,
            data: {
              'is_cooked': updated.isCooked,
              'cooked_by': updated.isCooked ? uid : null,
            },
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await ref.read(syncEngineProvider).flush(isOnline: true);
  }
}

final familyMealPlanProvider = StateNotifierProvider.autoDispose<
    FamilyMealPlanNotifier, FamilyMealPlanState>((ref) {
  final fam = ref.watch(familyProvider).family;
  if (fam == null) {
    throw StateError('familyMealPlanProvider accessed without family');
  }
  return FamilyMealPlanNotifier(ref, fam.id);
});
