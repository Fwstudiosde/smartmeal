import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/fridge_scanner/providers/fridge_providers.dart';

class RecipeResultsScreen extends ConsumerWidget {
  const RecipeResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(filteredRecipesProvider);
    final filter = ref.watch(recipeFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Iconsax.arrow_left,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rezept-Vorschläge',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            recipesAsync.when(
                              data: (recipes) => Text(
                                '${recipes.length} Rezepte gefunden',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),
                  
                  // Filter chips
                  _buildFilterChips(ref, filter),
                ],
              ),
            ),
            
            // Recipe list
            Expanded(
              child: recipesAsync.when(
                data: (recipes) => recipes.isEmpty
                    ? _buildEmptyState(context)
                    : _buildRecipeList(context, ref, recipes),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(context, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, RecipeFilter currentFilter) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Alle',
            icon: Iconsax.category,
            isSelected: currentFilter == RecipeFilter.all,
            onTap: () => ref.read(recipeFilterProvider.notifier).state = RecipeFilter.all,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Schnell',
            icon: Iconsax.timer_1,
            isSelected: currentFilter == RecipeFilter.quick,
            onTap: () => ref.read(recipeFilterProvider.notifier).state = RecipeFilter.quick,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Einfach',
            icon: Iconsax.star,
            isSelected: currentFilter == RecipeFilter.easy,
            onTap: () => ref.read(recipeFilterProvider.notifier).state = RecipeFilter.easy,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Beste Übereinstimmung',
            icon: Iconsax.tick_circle,
            isSelected: currentFilter == RecipeFilter.highMatch,
            onTap: () => ref.read(recipeFilterProvider.notifier).state = RecipeFilter.highMatch,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rezepte werden geladen...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Iconsax.book,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Rezepte gefunden',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Versuche einen anderen Filter oder füge mehr Zutaten hinzu.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList(BuildContext context, WidgetRef ref, List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeCard(
          recipe: recipe,
          onTap: () {
            ref.read(selectedRecipeProvider.notifier).state = recipe;
            context.push('/recipe/${recipe.id}', extra: recipe);
          },
        ).animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1);
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Einfach';
      case 'medium':
        return 'Mittel';
      case 'hard':
        return 'Schwer';
      default:
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Iconsax.gallery,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(
                              Iconsax.gallery,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                ),
                
                // Match percentage badge
                if (recipe.matchPercentage != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: recipe.matchPercentage! >= 80
                            ? AppColors.success
                            : recipe.matchPercentage! >= 50
                                ? AppColors.warning
                                : AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.matchPercentage!.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Meta info
                  Row(
                    children: [
                      _MetaChip(
                        icon: Iconsax.timer_1,
                        label: '${recipe.totalTime} Min',
                      ),
                      const SizedBox(width: 12),
                      _MetaChip(
                        icon: Iconsax.profile_2user,
                        label: '${recipe.servings} Port.',
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDifficultyLabel(recipe.difficulty),
                          style: TextStyle(
                            color: _getDifficultyColor(recipe.difficulty),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
