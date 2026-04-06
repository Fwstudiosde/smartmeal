import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/fridge_scanner/providers/fridge_providers.dart';
import 'package:uuid/uuid.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
  final _uuid = const Uuid();
  bool _isGenerating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final name = _addController.text.trim();
    if (name.isEmpty) return;

    final ingredient = Ingredient(
      id: _uuid.v4(),
      name: name,
      category: 'other',
    );

    ref.read(ingredientsProvider.notifier).addIngredient(ingredient);
    _addController.clear();
  }

  Future<void> _generateRecipes() async {
    final ingredients = ref.read(ingredientsProvider);
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füge mindestens eine Zutat hinzu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    
    await ref.read(recipesProvider.notifier).generateRecipes();
    
    setState(() => _isGenerating = false);
    
    if (mounted) {
      context.push('/recipe-results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

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
                              'Deine Zutaten',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              '${ingredients.length} Zutaten erkannt',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 24),
                  
                  // Add ingredient input
                  _buildAddInput(),
                  const SizedBox(height: 16),
                  
                  // Category filter
                  _buildCategoryFilter(selectedCategory),
                ],
              ),
            ),
            
            // Ingredients list
            Expanded(
              child: ingredients.isEmpty
                  ? _buildEmptyState()
                  : _buildIngredientsList(ingredients),
            ),
            
            // Generate button
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addController,
              decoration: const InputDecoration(
                hintText: 'Zutat hinzufügen...',
                border: InputBorder.none,
                prefixIcon: Icon(Iconsax.add, color: AppColors.textTertiary),
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
          ),
          GestureDetector(
            onTap: _addIngredient,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildCategoryFilter(IngredientCategory? selectedCategory) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Alle',
            isSelected: selectedCategory == null,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
          ),
          ...IngredientCategory.values.map((category) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _FilterChip(
              label: '${category.emoji} ${category.label}',
              isSelected: selectedCategory == category,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = category,
            ),
          )),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildEmptyState() {
    return Center(
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
              Iconsax.box_1,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keine Zutaten',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Zutaten hinzu oder scanne deinen Kühlschrank',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildIngredientsList(List<Ingredient> ingredients) {
    final filteredIngredients = ref.watch(filteredIngredientsProvider);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = filteredIngredients[index];
        return _IngredientCard(
          ingredient: ingredient,
          onDelete: () {
            ref.read(ingredientsProvider.notifier).removeIngredient(ingredient.id);
          },
        ).animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.1);
      },
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _isGenerating ? null : _generateRecipes,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: _isGenerating ? null : AppColors.primaryGradient,
              color: _isGenerating ? AppColors.surfaceVariant : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isGenerating ? null : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGenerating) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rezepte werden generiert...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Iconsax.magic_star,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Rezepte generieren',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.2);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onDelete;

  const _IngredientCard({
    required this.ingredient,
    required this.onDelete,
  });

  String _getCategoryEmoji(String? category) {
    if (category == null) return '📦';
    
    try {
      final cat = IngredientCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == category.toLowerCase(),
      );
      return cat.emoji;
    } catch (_) {
      return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Text(
            _getCategoryEmoji(ingredient.category),
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (ingredient.quantity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ingredient.quantity!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.trash,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
