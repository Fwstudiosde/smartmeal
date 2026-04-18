import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/sync/sync_engine.dart';
import '../providers/family_provider.dart';
import '../providers/family_meal_plan_provider.dart';
import 'plan_context_bar.dart';

class FamilyMealPlanScreen extends ConsumerWidget {
  const FamilyMealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fam = ref.watch(familyProvider);

    if (!fam.hasFamily) {
      return Scaffold(
        appBar: AppBar(title: const Text('Haushalt-Wochenplan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Kein Haushalt',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erstelle einen Haushalt, um deinen Wochenplan zu teilen.',
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

    final state = ref.watch(familyMealPlanProvider);
    final notifier = ref.read(familyMealPlanProvider.notifier);
    final pending = ref
        .watch(pendingOpsCountProvider)
        .maybeWhen(data: (v) => v, orElse: () => 0);

    final days = List.generate(
      7,
      (i) => state.weekStart.add(Duration(days: i)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${fam.family!.name} — Wochenplan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
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
                    style:
                        TextStyle(fontSize: 11, color: Colors.amber[900]),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          const PlanContextBar(
            current: PlanContext.household,
            householdRoute: '/household/meal-plan',
            personalRoute: '/cart',
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => notifier.changeWeek(-7),
                ),
                Expanded(
                  child: Text(
                    _weekLabel(state.weekStart),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => notifier.changeWeek(7),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.meals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: notifier.refresh,
                    child: ListView.builder(
                      itemCount: days.length,
                      itemBuilder: (context, i) {
                        final day = days[i];
                        final dayMeals = state.meals
                            .where((m) =>
                                m.date.year == day.year &&
                                m.date.month == day.month &&
                                m.date.day == day.day)
                            .toList();
                        return _DayCard(
                          day: day,
                          meals: dayMeals,
                          onAdd: () => _showAddSheet(context, ref, day),
                          onToggle: notifier.toggleCooked,
                          onRemove: notifier.removeMeal,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, DateTime day) {
    final nameCtrl = TextEditingController();
    FamilyMealType selected = FamilyMealType.dinner;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gericht hinzufügen — ${_dayLabel(day)}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Gericht',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: FamilyMealType.values.map((t) {
                  final on = selected == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: on,
                    onSelected: (_) => setSt(() => selected = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  await ref.read(familyMealPlanProvider.notifier).addMeal(
                        date: day,
                        mealType: selected,
                        name: name,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${_short(start)} – ${_short(end)}';
  }

  static String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';

  static String _dayLabel(DateTime d) {
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return '${days[d.weekday - 1]} ${_short(d)}';
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<FamilyPlannedMeal> meals;
  final VoidCallback onAdd;
  final Future<void> Function(String) onToggle;
  final Future<void> Function(String) onRemove;

  const _DayCard({
    required this.day,
    required this.meals,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(day, DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _FamilyMealPlanScreenInternals._dayLabel(day),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isToday ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAdd,
                  tooltip: 'Gericht hinzufügen',
                ),
              ],
            ),
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Noch nichts geplant',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              )
            else
              ...meals.map((m) => _mealTile(context, m)),
          ],
        ),
      ),
    );
  }

  Widget _mealTile(BuildContext context, FamilyPlannedMeal m) {
    return Dismissible(
      key: ValueKey('meal_${m.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red[400],
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(m.id),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: _thumb(m.recipeImage),
        title: Text(
          m.recipeName ?? 'Unbekannt',
          style: TextStyle(
            decoration:
                m.isCooked ? TextDecoration.lineThrough : null,
            color: m.isCooked ? Colors.grey[600] : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${m.mealType.label} • ${m.servings} Portionen',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: Icon(
            m.isCooked
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: m.isCooked ? Colors.green : Colors.grey,
          ),
          onPressed: () => onToggle(m.id),
        ),
      ),
    );
  }

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.restaurant, size: 16),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.restaurant, size: 16),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _FamilyMealPlanScreenInternals {
  static String _dayLabel(DateTime d) {
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return '${days[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }
}
