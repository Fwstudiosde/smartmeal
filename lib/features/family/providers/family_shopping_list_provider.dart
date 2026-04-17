import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/sync/sync_engine.dart';
import '../../../core/services/sync/sync_operation.dart';
import 'family_provider.dart';

class FamilyShoppingItem {
  final String id;
  final String ingredientName;
  final double quantity;
  final String unit;
  final String? category;
  final String? storeName;
  final bool isPurchased;
  final String? addedBy;
  final String? purchasedBy;

  FamilyShoppingItem({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.category,
    this.storeName,
    this.isPurchased = false,
    this.addedBy,
    this.purchasedBy,
  });

  factory FamilyShoppingItem.fromJson(Map<String, dynamic> j) =>
      FamilyShoppingItem(
        id: j['id'] as String,
        ingredientName: (j['ingredient_name'] ?? '') as String,
        quantity: (j['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: (j['unit'] ?? 'Stueck') as String,
        category: j['category'] as String?,
        storeName: j['store_name'] as String?,
        isPurchased: (j['is_purchased'] as bool?) ?? false,
        addedBy: j['added_by'] as String?,
        purchasedBy: j['purchased_by'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredient_name': ingredientName,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'store_name': storeName,
        'is_purchased': isPurchased,
        'added_by': addedBy,
        'purchased_by': purchasedBy,
      };
}

class FamilyShoppingListState {
  final String? listId;
  final List<FamilyShoppingItem> items;
  final bool isLoading;
  final String? error;

  const FamilyShoppingListState({
    this.listId,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  FamilyShoppingListState copyWith({
    String? listId,
    List<FamilyShoppingItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      FamilyShoppingListState(
        listId: listId ?? this.listId,
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class FamilyShoppingListNotifier
    extends StateNotifier<FamilyShoppingListState> {
  final Ref ref;
  final String familyId;
  final SupabaseClient _client = Supabase.instance.client;
  static const _cacheBox = 'family_cache';
  final _uuid = const Uuid();

  FamilyShoppingListNotifier(this.ref, this.familyId)
      : super(const FamilyShoppingListState()) {
    _loadFromCache();
    _fetch();
  }

  String get _listCacheKey => 'shopping_list_$familyId';
  String get _itemsCacheKey => 'shopping_items_$familyId';

  void _loadFromCache() {
    try {
      final box = Hive.box(_cacheBox);
      final listId = box.get(_listCacheKey) as String?;
      final itemsRaw = box.get(_itemsCacheKey) as List?;
      final items = itemsRaw
              ?.map((e) => FamilyShoppingItem.fromJson(
                  Map<String, dynamic>.from(jsonDecode(e as String))))
              .toList() ??
          [];
      state = state.copyWith(listId: listId, items: items);
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final box = Hive.box(_cacheBox);
      await box.put(_listCacheKey, state.listId);
      await box.put(
        _itemsCacheKey,
        state.items.map((i) => jsonEncode(i.toJson())).toList(),
      );
    } catch (_) {}
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var listRes = await _client
          .from('shopping_lists')
          .select('id')
          .eq('family_id', familyId)
          .maybeSingle();

      String listId;
      if (listRes == null) {
        // Create the family shopping list if it doesn't exist yet
        final uid = _client.auth.currentUser?.id;
        final created = await _client.from('shopping_lists').insert({
          'user_id': uid,
          'family_id': familyId,
          'name': 'Familien-Einkaufsliste',
        }).select('id').single();
        listId = created['id'] as String;
      } else {
        listId = listRes['id'] as String;
      }

      final itemsRes = await _client
          .from('shopping_list_items')
          .select('*')
          .eq('shopping_list_id', listId)
          .order('created_at', ascending: true);

      final items = (itemsRes as List)
          .map((e) =>
              FamilyShoppingItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      state = FamilyShoppingListState(
        listId: listId,
        items: items,
        isLoading: false,
      );
      await _saveCache();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> addItem(String name,
      {double quantity = 1.0, String unit = 'Stueck'}) async {
    final listId = state.listId;
    if (listId == null) return;

    final uid = _client.auth.currentUser?.id;
    final id = _uuid.v4();
    final item = FamilyShoppingItem(
      id: id,
      ingredientName: name.trim(),
      quantity: quantity,
      unit: unit,
      category: 'Manuell',
      addedBy: uid,
    );

    // Optimistic UI update
    state = state.copyWith(items: [...state.items, item]);
    await _saveCache();

    await ref.read(syncEngineProvider).enqueue(
          SyncOperation(
            id: _uuid.v4(),
            op: SyncOpType.insert,
            table: 'shopping_list_items',
            data: {
              'id': id,
              'shopping_list_id': listId,
              'ingredient_name': item.ingredientName,
              'quantity': item.quantity,
              'unit': item.unit,
              'category': item.category,
              'is_purchased': false,
              'added_by': uid,
            },
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await ref
        .read(syncEngineProvider)
        .flush(isOnline: true);
  }

  Future<void> togglePurchased(String itemId) async {
    final idx = state.items.indexWhere((i) => i.id == itemId);
    if (idx < 0) return;
    final uid = _client.auth.currentUser?.id;
    final current = state.items[idx];
    final updated = FamilyShoppingItem(
      id: current.id,
      ingredientName: current.ingredientName,
      quantity: current.quantity,
      unit: current.unit,
      category: current.category,
      storeName: current.storeName,
      isPurchased: !current.isPurchased,
      addedBy: current.addedBy,
      purchasedBy: !current.isPurchased ? uid : null,
    );
    final newItems = [...state.items];
    newItems[idx] = updated;
    state = state.copyWith(items: newItems);
    await _saveCache();

    await ref.read(syncEngineProvider).enqueue(
          SyncOperation(
            id: _uuid.v4(),
            op: SyncOpType.update,
            table: 'shopping_list_items',
            rowId: itemId,
            data: {
              'is_purchased': updated.isPurchased,
              'purchased_by': updated.purchasedBy,
            },
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await ref.read(syncEngineProvider).flush(isOnline: true);
  }

  Future<void> removeItem(String itemId) async {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
    await _saveCache();

    await ref.read(syncEngineProvider).enqueue(
          SyncOperation(
            id: _uuid.v4(),
            op: SyncOpType.delete,
            table: 'shopping_list_items',
            rowId: itemId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await ref.read(syncEngineProvider).flush(isOnline: true);
  }

  Future<void> clearPurchased() async {
    final toDelete = state.items.where((i) => i.isPurchased).toList();
    state = state.copyWith(
      items: state.items.where((i) => !i.isPurchased).toList(),
    );
    await _saveCache();
    for (final item in toDelete) {
      await ref.read(syncEngineProvider).enqueue(
            SyncOperation(
              id: _uuid.v4(),
              op: SyncOpType.delete,
              table: 'shopping_list_items',
              rowId: item.id,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }
    await ref.read(syncEngineProvider).flush(isOnline: true);
  }
}

final familyShoppingListProvider = StateNotifierProvider.autoDispose<
    FamilyShoppingListNotifier, FamilyShoppingListState>((ref) {
  final fam = ref.watch(familyProvider).family;
  if (fam == null) {
    throw StateError('familyShoppingListProvider accessed without family');
  }
  return FamilyShoppingListNotifier(ref, fam.id);
});
