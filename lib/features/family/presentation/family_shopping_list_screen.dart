import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/sync/sync_engine.dart';
import '../providers/family_provider.dart';
import '../providers/family_shopping_list_provider.dart';
import 'plan_context_bar.dart';

class FamilyShoppingListScreen extends ConsumerStatefulWidget {
  const FamilyShoppingListScreen({super.key});

  @override
  ConsumerState<FamilyShoppingListScreen> createState() =>
      _FamilyShoppingListScreenState();
}

class _FamilyShoppingListScreenState
    extends ConsumerState<FamilyShoppingListScreen> {
  final _addCtrl = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _adding = true);
    try {
      await ref.read(familyShoppingListProvider.notifier).addItem(text);
      _addCtrl.clear();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);

    if (!familyState.hasFamily) {
      return Scaffold(
        appBar: AppBar(title: const Text('Haushalt-Einkaufsliste')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Kein Haushalt',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erstelle einen Haushalt, um Einkaufslisten mit deiner Familie zu teilen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/household'),
                  child: const Text('Zum Haushalt'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listState = ref.watch(familyShoppingListProvider);
    final pending =
        ref.watch(pendingOpsCountProvider).maybeWhen(data: (v) => v, orElse: () => 0);
    final items = listState.items;
    final openItems = items.where((i) => !i.isPurchased).toList();
    final doneItems = items.where((i) => i.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(familyState.family!.name),
        actions: [
          if (doneItems.isNotEmpty)
            IconButton(
              tooltip: 'Erledigte löschen',
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: () => ref
                  .read(familyShoppingListProvider.notifier)
                  .clearPurchased(),
            ),
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(familyShoppingListProvider.notifier).refresh(),
          ),
        ],
        bottom: pending > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Container(
                  width: double.infinity,
                  color: Colors.amber[100],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Text(
                    '$pending ausstehende Änderungen werden synchronisiert…',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          const PlanContextBar(
            current: PlanContext.household,
            householdRoute: '/household/shopping',
            personalRoute: '/cart',
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                      hintText: 'Neuen Artikel hinzufügen…',
                      prefixIcon: const Icon(Icons.add_shopping_cart),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _adding ? null : _add,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  child: _adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: listState.isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Liste ist leer',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(familyShoppingListProvider.notifier)
                            .refresh(),
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 20),
                          children: [
                            if (openItems.isNotEmpty) ...[
                              _header('Offen', openItems.length),
                              ...openItems.map(_tile),
                            ],
                            if (doneItems.isNotEmpty) ...[
                              _header('Erledigt', doneItems.length,
                                  muted: true),
                              ...doneItems.map(_tile),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text, int count, {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: muted ? Colors.grey[600] : Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(item) {
    final notifier = ref.read(familyShoppingListProvider.notifier);
    return Dismissible(
      key: ValueKey('item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red[400],
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => notifier.removeItem(item.id),
      child: CheckboxListTile(
        value: item.isPurchased,
        onChanged: (_) => notifier.togglePurchased(item.id),
        title: Text(
          item.ingredientName,
          style: TextStyle(
            decoration: item.isPurchased
                ? TextDecoration.lineThrough
                : null,
            color: item.isPurchased ? Colors.grey[600] : null,
          ),
        ),
        subtitle: (item.quantity > 1 || item.unit != 'Stueck')
            ? Text(
                '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                style: const TextStyle(fontSize: 11),
              )
            : null,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
