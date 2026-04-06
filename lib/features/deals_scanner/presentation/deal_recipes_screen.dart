import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/deals_providers.dart';
import '../providers/custom_recipes_provider.dart';
import '../../../core/auth/providers/auth_provider.dart';
import '../../../core/auth/providers/community_profile_provider.dart';
import '../../fridge_scanner/providers/fridge_providers.dart';

// Selected Category Filter Provider
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

class DealRecipesScreen extends ConsumerWidget {
  const DealRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use combined provider that supports both savings mode and all recipes mode
    final dealRecipesAsync = ref.watch(combinedRecipesProvider);
    final savingsMode = ref.watch(savingsModeProvider);
    final showSearchBar = ref.watch(showSearchBarProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(savingsMode ? 'Spar-Rezepte' : 'Alle Rezepte'),
        automaticallyImplyLeading: false,
        actions: [
          // Fridge scanner button
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Iconsax.camera,
                size: 18,
              ),
            ),
            tooltip: 'Kühlschrank scannen',
            onPressed: () {
              context.push('/fridge-scan');
            },
          ),
          // Search button
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Iconsax.search_normal_1,
                size: 20,
              ),
            ),
            tooltip: 'Rezepte suchen',
            onPressed: () {
              ref.read(showSearchBarProvider.notifier).state = !showSearchBar;
              if (showSearchBar) {
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
          const SizedBox(width: 8),
          // Add recipe button
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            tooltip: 'Eigenes Rezept hinzufügen',
            onPressed: () {
              context.push('/create-custom-recipe');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Savings Mode Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  savingsMode ? Iconsax.wallet_money : Iconsax.book,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savingsMode ? 'Spar-Modus' : 'Alle Rezepte',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        savingsMode
                            ? 'Nur Rezepte mit Angeboten'
                            : 'Alle Rezepte aus der Datenbank',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: savingsMode,
                  onChanged: (value) {
                    ref.read(savingsModeProvider.notifier).state = value;
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
          // Search Bar
          if (showSearchBar)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.surfaceColor,
                    width: 1,
                  ),
                ),
              ),
              child: TextField(
                autofocus: true,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Rezepte suchen...',
                  prefixIcon: const Icon(Iconsax.search_normal_1),
                  suffixIcon: IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.surfaceColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.surfaceColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1),
          // Recipe List
          Expanded(
            child: dealRecipesAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
              data: (dealRecipes) {
                if (dealRecipes.isEmpty) {
                  return _buildEmptyState(context, savingsMode);
                }
                return _buildContent(context, ref, dealRecipes);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          const Text(
            'Finde günstige Rezepte...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Analysiere Angebote für beste Ersparnisse',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fehler beim Laden',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool savingsMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Iconsax.receipt_search,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 24),
            Text(
              savingsMode ? 'Keine Spar-Rezepte gefunden' : 'Keine Rezepte gefunden',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              savingsMode
                  ? 'Wähle mehr Supermärkte aus, um passende Rezepte zu finden'
                  : 'Keine Rezepte in der Datenbank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            if (savingsMode)
              ElevatedButton.icon(
                onPressed: () => context.go('/deals'),
                icon: const Icon(Iconsax.scan),
                label: const Text('Angebote scannen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  List<DealRecipe> _customToDeals(List<CustomRecipe> customs, String tag, Map<String, CustomRecipe> customMap) {
    return customs.map((c) {
      customMap[c.id] = c;
      final recipe = Recipe(
        id: c.id,
        name: c.name,
        description: c.description,
        prepTime: c.prepTime,
        cookTime: c.cookTime,
        servings: c.servings,
        difficulty: c.difficulty,
        ingredients: c.ingredients.map((i) => RecipeIngredient(
          name: i['name']?.toString() ?? '',
          quantity: i['quantity']?.toString() ?? '',
          unit: i['unit']?.toString() ?? '',
          isAvailable: true,
        )).toList(),
        instructions: c.instructions,
        tags: [tag, if (c.authorName != null) c.authorName!],
      );
      return DealRecipe(
        recipe: recipe,
        dealIngredients: [],
        totalSavings: 0,
        totalCost: 0,
      );
    }).toList();
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<DealRecipe> dealRecipes,
  ) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final ownRecipes = ref.watch(ownRecipesProvider);
    final communityRecipes = ref.watch(communityRecipesProvider);

    final customMap = <String, CustomRecipe>{};
    final userId = ref.watch(authProvider).user?.id;

    // Build filtered list based on selected category
    List<DealRecipe> filteredRecipes;

    if (selectedCategory == 'custom') {
      // "Eigene" - all own recipes (private + public)
      filteredRecipes = _customToDeals(ownRecipes, 'custom', customMap);
    } else if (selectedCategory == 'community') {
      // "Community" - all public recipes (including own)
      filteredRecipes = _customToDeals(communityRecipes, 'community', customMap);
    } else {
      // "Alle" or other category filters - merge deal recipes + custom
      List<DealRecipe> allRecipes = [...dealRecipes];
      allRecipes.addAll(_customToDeals(ownRecipes, 'custom', customMap));

      // Add community recipes not already in own
      final ownIds = ownRecipes.map((r) => r.id).toSet();
      final communityOnly = communityRecipes.where((r) => !ownIds.contains(r.id)).toList();
      allRecipes.addAll(_customToDeals(communityOnly, 'community', customMap));

      if (selectedCategory == null) {
        filteredRecipes = allRecipes;
      } else {
        filteredRecipes = allRecipes.where((dr) {
          if (dr.recipe.tags.isEmpty) return false;
          return dr.recipe.tags.first == selectedCategory;
        }).toList();
      }
    }

    // Build allRecipes just for filter chip display
    final allForChips = <DealRecipe>[...dealRecipes];
    allForChips.addAll(_customToDeals(ownRecipes, 'custom', customMap));
    final ownIds2 = ownRecipes.map((r) => r.id).toSet();
    allForChips.addAll(_customToDeals(
      communityRecipes.where((r) => !ownIds2.contains(r.id)).toList(),
      'community', customMap,
    ));

    return Column(
      children: [
        _buildCategoryFilters(ref, allForChips),
        Expanded(
          child: filteredRecipes.isEmpty
              ? _buildEmptyFilterState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final dealRecipe = filteredRecipes[index];
                    return _buildDealRecipeCard(context, dealRecipe, index, ref, customMap);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(WidgetRef ref, List<DealRecipe> dealRecipes) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    // Define categories
    final categories = [
      {'name': 'Alle', 'value': null, 'icon': Iconsax.category},
      {'name': 'Community', 'value': 'community', 'icon': Iconsax.people},
      {'name': 'Eigene', 'value': 'custom', 'icon': Iconsax.edit},
      {'name': 'Frühstück', 'value': 'breakfast', 'icon': Iconsax.coffee},
      {'name': 'Fitness', 'value': 'fitness', 'icon': Iconsax.heart},
      {'name': 'Schnell', 'value': 'quick', 'icon': Iconsax.flash_1},
      {'name': 'Deutsch', 'value': 'german', 'icon': Iconsax.medal},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.surfaceColor,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category['value'];

            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(category['name'] as String),
                ],
              ),
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  width: 1.5,
                ),
              ),
              onSelected: (selected) {
                ref.read(selectedCategoryFilterProvider.notifier).state =
                    category['value'] as String?;
              },
            );
          },
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Iconsax.receipt_search,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 24),
            const Text(
              'Keine Rezepte gefunden',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              'Versuche einen anderen Filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildDealRecipeCard(
    BuildContext context,
    DealRecipe dealRecipe,
    int index,
    [WidgetRef? ref, Map<String, CustomRecipe>? customMap]
  ) {
    final customRecipe = customMap?[dealRecipe.recipe.id];
    final isCustom = customRecipe != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  dealRecipe.recipe.imageUrl ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AppTheme.primaryLight,
                    child: const Icon(
                      Iconsax.gallery,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.discount_shape,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '-${dealRecipe.totalSavings.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Recipe Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        dealRecipe.recipe.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isCustom && ref != null)
                      GestureDetector(
                        onTap: () => ref.read(customRecipesProvider.notifier).toggleLike(customRecipe!.id),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              customRecipe!.isLikedByMe ? Iconsax.heart5 : Iconsax.heart,
                              color: customRecipe.isLikedByMe ? Colors.red : AppTheme.textSecondary,
                              size: 22,
                            ),
                            if (customRecipe.likeCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${customRecipe.likeCount}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: customRecipe.isLikedByMe ? Colors.red : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                // Author info for community recipes
                if (isCustom && customRecipe!.authorName != null && customRecipe.isPublic) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.user, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        customRecipe.authorName!,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
                // Public toggle for own recipes
                if (isCustom && ref != null && customRecipe!.userId == ref.read(authProvider).user?.id) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: customRecipe.isPublic
                          ? const Color(0xFF2E7D32).withOpacity(0.06)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: customRecipe.isPublic
                            ? const Color(0xFF2E7D32).withOpacity(0.2)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          customRecipe.isPublic ? Iconsax.global : Iconsax.lock,
                          size: 16,
                          color: customRecipe.isPublic ? const Color(0xFF2E7D32) : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          customRecipe.isPublic ? 'Online' : 'Privat',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: customRecipe.isPublic ? const Color(0xFF2E7D32) : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 28,
                          child: Switch(
                            value: customRecipe.isPublic,
                            onChanged: (val) async {
                              if (val && !ref.read(hasDisplayNameProvider)) {
                                // Need display name first
                                final nameCtrl = TextEditingController();
                                final name = await showDialog<String>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Anzeigename waehlen'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Dein Name wird bei Community-Rezepten angezeigt.',
                                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: nameCtrl,
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            hintText: 'z.B. KochProfi92',
                                            prefixIcon: const Icon(Iconsax.user),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
                                      ElevatedButton(
                                        onPressed: () {
                                          final n = nameCtrl.text.trim();
                                          if (n.isNotEmpty) Navigator.pop(ctx, n);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2E7D32),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Bestaetigen'),
                                      ),
                                    ],
                                  ),
                                );
                                if (name == null) return;
                                ref.read(displayNameProvider.notifier).setName(name);
                                ref.read(customRecipesProvider.notifier).togglePublic(
                                  customRecipe.id, authorName: name,
                                );
                              } else {
                                ref.read(customRecipesProvider.notifier).togglePublic(
                                  customRecipe.id,
                                  authorName: ref.read(displayNameProvider),
                                );
                              }
                            },
                            activeColor: const Color(0xFF2E7D32),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  dealRecipe.recipe.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                // Quick Info Row
                Row(
                  children: [
                    _buildQuickInfoChip(
                      Iconsax.clock,
                      '${dealRecipe.recipe.prepTime + dealRecipe.recipe.cookTime} Min',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickInfoChip(
                      Iconsax.profile_2user,
                      '${dealRecipe.recipe.servings} Port.',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickInfoChip(
                      Iconsax.chart,
                      dealRecipe.recipe.difficulty,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                // Deal Ingredients
                const Text(
                  'Angebote genutzt:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...dealRecipe.dealIngredients.take(3).map((deal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.tag,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deal.ingredient.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          deal.storeName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${deal.price.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (dealRecipe.dealIngredients.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${dealRecipe.dealIngredients.length - 3} weitere Angebote',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Price Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gesamtkosten',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dealRecipe.totalCost.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/recipe/${dealRecipe.recipe.id}',
                              extra: dealRecipe);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Rezept ansehen'),
                            SizedBox(width: 8),
                            Icon(Iconsax.arrow_right_3, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
