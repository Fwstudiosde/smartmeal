import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/fridge_scanner/providers/pantry_provider.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredPantryProvider);
    final stats = ref.watch(pantryStatsProvider);
    final activeFilter = ref.watch(pantryFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: items.isEmpty && activeFilter == null
            ? _buildEmptyState(context)
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeader(context, stats),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategoryFilter(context, ref, activeFilter),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PantryItemCard(item: item),
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: (50 * index).ms,
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PantryStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: const Icon(Iconsax.arrow_left, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mein Vorrat',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${stats.totalProducts} Produkte, ${stats.totalItems} Artikel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        _buildStatsRow(context, stats),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, PantryStats stats) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Iconsax.box_1,
            value: '${stats.totalItems}',
            label: 'Artikel',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Iconsax.category,
            value: '${stats.categories}',
            label: 'Kategorien',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Iconsax.flash_1,
            value: stats.avgCaloriesPer100g > 0
                ? '${stats.avgCaloriesPer100g.toStringAsFixed(0)}'
                : '-',
            label: 'kcal/100g',
            color: AppColors.accent,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildCategoryFilter(BuildContext context, WidgetRef ref, String? active) {
    final items = ref.watch(pantryProvider);
    final categories = <String>{};
    for (final item in items) {
      if (item.category != null) categories.add(item.category!);
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Alle',
            isActive: active == null,
            onTap: () => ref.read(pantryFilterProvider.notifier).state = null,
          ),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _FilterChip(
              label: cat,
              isActive: active == cat,
              onTap: () => ref.read(pantryFilterProvider.notifier).state = cat,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Iconsax.box_1,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vorrat ist leer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Scanne Produkte mit dem Barcode-Scanner um deinen Vorrat zu fuellen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Barcode scannen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Private Widgets ===

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PantryItemCard extends ConsumerWidget {
  final PantryItem item;

  const _PantryItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.brand != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.brand!,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.nutriScore != null) _NutriScoreBadge(score: item.nutriScore!),
                    if (item.nutriScore != null) const SizedBox(width: 8),
                    if (item.nutrition != null)
                      Text(
                        '${item.nutrition!.calories} kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (item.category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category!,
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Quantity controls
          Column(
            children: [
              GestureDetector(
                onTap: () => ref.read(pantryProvider.notifier).increaseQuantity(item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.add, size: 16, color: AppColors.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(pantryProvider.notifier).decreaseQuantity(item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.minus, size: 16, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Iconsax.box_1, color: AppColors.textTertiary, size: 24),
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  final String score;

  const _NutriScoreBadge({required this.score});

  Color get _color {
    switch (score.toUpperCase()) {
      case 'A': return const Color(0xFF038141);
      case 'B': return const Color(0xFF85BB2F);
      case 'C': return const Color(0xFFFECB02);
      case 'D': return const Color(0xFFEE8100);
      case 'E': return const Color(0xFFE63E11);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        score.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
