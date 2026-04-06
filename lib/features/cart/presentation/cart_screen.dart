import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/cart/providers/meal_plan_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealPlan = ref.watch(currentMealPlanProvider);
    final isEmpty = mealPlan == null || mealPlan.meals.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Wochenplan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (!isEmpty) ...[
                        IconButton(
                          onPressed: () {
                            ref.read(currentMealPlanProvider.notifier).clearWeek();
                          },
                          icon: const Icon(Iconsax.trash, color: AppColors.textSecondary),
                          tooltip: 'Woche leeren',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ref.read(currentMealPlanProvider.notifier).previousWeek();
                        },
                        icon: const Icon(Iconsax.arrow_left_2, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mealPlan != null ? _getWeekRangeText(mealPlan.weekStart) : '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(currentMealPlanProvider.notifier).nextWeek();
                        },
                        icon: const Icon(Iconsax.arrow_right_3, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Wochenübersicht'),
                  Tab(text: 'Einkaufsliste'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWeekView(),
                  _buildShoppingListView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.calendar_1,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dein Wochenplan ist leer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Füge Rezepte aus den Angeboten hinzu, um deinen Wochenplan zu erstellen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/deals');
              },
              icon: const Icon(Iconsax.discount_shape),
              label: const Text('Angebote entdecken'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final weekDays = ref.watch(weekDaysProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final date = weekDays[index];
        return _buildDayCard(date);
      },
    );
  }

  Widget _buildDayCard(DateTime date) {
    final meals = ref.watch(mealsForDateProvider(date));
    final isToday = _isToday(date);
    final dayName = DateFormat('EEEE').format(date);
    final dayDate = DateFormat('d. MMM').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      dayDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Heute',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Meals
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Keine Mahlzeiten geplant',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...meals.map((meal) => _buildMealCard(meal)),
        ],
      ),
    );
  }

  Widget _buildMealCard(PlannedMeal meal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.background, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Recipe Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: meal.dealRecipe.recipe.imageUrl != null
                ? Image.network(
                    meal.dealRecipe.recipe.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.background,
                        child: const Icon(Iconsax.gallery, color: AppColors.textSecondary),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.background,
                    child: const Icon(Iconsax.gallery, color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),

          // Meal Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${meal.mealType.emoji} ${meal.mealType.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Recipe Name
                Text(
                  meal.dealRecipe.recipe.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Servings with +/- controls
                Row(
                  children: [
                    const Icon(Iconsax.user, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),

                    // Decrease button
                    GestureDetector(
                      onTap: meal.servings > 1
                          ? () => ref.read(currentMealPlanProvider.notifier)
                              .updateMealServings(meal.id, meal.servings - 1)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: meal.servings > 1
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.textTertiary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Iconsax.minus,
                          size: 12,
                          color: meal.servings > 1
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Servings count
                    Text(
                      '${meal.servings}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Increase button
                    GestureDetector(
                      onTap: () => ref.read(currentMealPlanProvider.notifier)
                          .updateMealServings(meal.id, meal.servings + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Iconsax.add,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    Text(
                      'Portionen',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(currentMealPlanProvider.notifier).toggleMealCooked(meal.id);
                },
                icon: Icon(
                  meal.isCooked ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                  color: meal.isCooked ? AppColors.success : AppColors.textTertiary,
                ),
                iconSize: 24,
              ),
              IconButton(
                onPressed: () {
                  ref.read(currentMealPlanProvider.notifier).removeMeal(meal.id);
                },
                icon: const Icon(Iconsax.trash, color: AppColors.error),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListView() {
    final shoppingList = ref.watch(shoppingListProvider);
    final shoppingListByStore = ref.watch(shoppingListByStoreProvider);

    if (shoppingList == null) {
      return const Center(
        child: Text('Keine Einkaufsliste verfügbar'),
      );
    }

    return CustomScrollView(
      slivers: [
        // Summary
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gesamtkosten',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${shoppingList.totalCost.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Ersparnis',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${shoppingList.totalSavings.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: shoppingList.progress,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${shoppingList.purchasedCount} von ${shoppingList.totalCount} Artikel gekauft',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add Custom Item Input Field
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customItemController,
                    decoration: const InputDecoration(
                      hintText: 'Eigenes Produkt hinzufügen...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        ref.read(customShoppingListItemsProvider.notifier).addItem(value.trim());
                        _customItemController.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
                  onPressed: () {
                    final value = _customItemController.text;
                    if (value.trim().isNotEmpty) {
                      ref.read(customShoppingListItemsProvider.notifier).addItem(value.trim());
                      _customItemController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Shopping List by Store
        ...shoppingListByStore.entries.map((entry) {
          final storeName = entry.key;
          final items = entry.value;

          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.shop,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${items.length} Artikel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Items
                  ...items.map((item) => _buildShoppingListItem(item)),
                ],
              ),
            ),
          );
        }),

        // Custom Items Section
        Builder(
          builder: (context) {
            final customItems = ref.watch(customShoppingListItemsProvider);
            if (customItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

            return SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.edit,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Manuell hinzugefügt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${customItems.length} Artikel',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Items
                    ...customItems.map((item) => _buildCustomShoppingListItem(item)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShoppingListItem(ShoppingListItem item) {
    final shoppingListItems = ref.watch(shoppingListItemsProvider);
    final isPurchased = shoppingListItems[item.id] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.background, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              ref.read(shoppingListItemsProvider.notifier).togglePurchased(item.id);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isPurchased ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isPurchased ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isPurchased
                  ? const Icon(
                      Iconsax.tick_circle5,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ingredientName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPurchased ? AppColors.textTertiary : AppColors.textPrimary,
                    decoration: isPurchased ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.totalQuantity.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalPrice.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isPurchased ? AppColors.textTertiary : AppColors.textPrimary,
                ),
              ),
              if (item.totalSavings > 0)
                Text(
                  '-${item.totalSavings.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomShoppingListItem(ShoppingListItem item) {
    final shoppingListItems = ref.watch(shoppingListItemsProvider);
    final isPurchased = shoppingListItems[item.id] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.background, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              ref.read(shoppingListItemsProvider.notifier).togglePurchased(item.id);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isPurchased ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isPurchased ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isPurchased
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Item Name
          Expanded(
            child: Text(
              item.ingredientName,
              style: TextStyle(
                fontSize: 14,
                color: isPurchased ? AppColors.textTertiary : AppColors.textPrimary,
                decoration: isPurchased ? TextDecoration.lineThrough : null,
              ),
            ),
          ),

          // Delete Button
          IconButton(
            icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
            onPressed: () {
              ref.read(customShoppingListItemsProvider.notifier).removeItem(item.id);
            },
          ),
        ],
      ),
    );
  }

  String _getWeekRangeText(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFormat = DateFormat('d. MMM').format(weekStart);
    final endFormat = DateFormat('d. MMM yyyy').format(weekEnd);
    return '$startFormat - $endFormat';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
