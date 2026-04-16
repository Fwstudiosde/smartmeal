import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';
import 'package:smartmeal/core/auth/providers/community_profile_provider.dart';
import 'package:smartmeal/features/deals_scanner/providers/custom_recipes_provider.dart';
import 'package:smartmeal/features/community/providers/follow_provider.dart';
import 'package:smartmeal/features/community/providers/user_profile_provider.dart';

final communitySearchProvider = StateProvider<String>((ref) => '');

final filteredCommunityRecipesProvider = Provider<List<CustomRecipe>>((ref) {
  final recipes = ref.watch(communityRecipesProvider);
  final search = ref.watch(communitySearchProvider).toLowerCase();
  if (search.isEmpty) return recipes;
  return recipes.where((r) => r.name.toLowerCase().contains(search)).toList();
});

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesState = ref.watch(customRecipesProvider);
    final filteredRecipes = ref.watch(filteredCommunityRecipesProvider);
    final isLoading = recipesState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (value) => ref.read(communitySearchProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Rezepte suchen...',
                prefixIcon: const Icon(Iconsax.search_normal_1, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Following Story Circles
          _FollowingStories(),

          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : filteredRecipes.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(customRecipesProvider.notifier).loadRecipes();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = filteredRecipes[index];
                            return _CommunityRecipeCard(recipe: recipe)
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 50 * index))
                                .slideY(begin: 0.1, end: 0);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.people, size: 80, color: AppTheme.primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Community-Rezepte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Sei der Erste, der ein Rezept teilt!',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CommunityRecipeCard extends ConsumerWidget {
  final CustomRecipe recipe;

  const _CommunityRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;

    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showRecipeDetail(context, recipe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image or gradient header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: hasImage
                  ? Image.network(
                      recipe.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderHeader(recipe),
                    )
                  : _buildPlaceholderHeader(recipe),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Title + Like
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      _LikeButton(recipe: recipe),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (recipe.description.isNotEmpty)
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  const SizedBox(height: 12),

                  // Meta row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaChip(icon: Iconsax.timer_1, label: '${recipe.prepTime + recipe.cookTime} Min'),
                      _MetaChip(icon: Iconsax.chart_21, label: recipe.difficulty),
                      _MetaChip(icon: Iconsax.profile_2user, label: '${recipe.servings} Portionen'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Author + ingredients count
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${recipe.userId}'),
                        child: _AuthorChip(userId: recipe.userId, authorName: recipe.authorName),
                      ),
                      const Spacer(),
                      Text(
                        '${recipe.ingredients.length} Zutaten',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderHeader(CustomRecipe recipe) {
    // Consistent color from recipe name
    final colors = [
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
      const Color(0xFFE65100),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFFC62828),
    ];
    final color = colors[recipe.name.length % colors.length];

    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.reserve,
          size: 40,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }

  void _showRecipeDetail(BuildContext context, CustomRecipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recipe image
              if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    recipe.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                const SizedBox(height: 16),

              // Title
              Text(
                recipe.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Author
              if (recipe.authorName != null)
                Row(
                  children: [
                    const Icon(Iconsax.user, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text('Geteilt von ${recipe.authorName}',
                        style: const TextStyle(color: AppTheme.primaryColor)),
                  ],
                ),
              const SizedBox(height: 16),

              // Description
              if (recipe.description.isNotEmpty) ...[
                Text(recipe.description, style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
              ],

              // Meta info
              Row(
                children: [
                  _DetailChip(icon: Iconsax.timer_1, label: '${recipe.prepTime} Min Vorbereitung'),
                  const SizedBox(width: 8),
                  _DetailChip(icon: Iconsax.timer, label: '${recipe.cookTime} Min Kochen'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _DetailChip(icon: Iconsax.chart_21, label: recipe.difficulty),
                  const SizedBox(width: 8),
                  _DetailChip(icon: Iconsax.profile_2user, label: '${recipe.servings} Portionen'),
                ],
              ),
              const SizedBox(height: 24),

              // Ingredients
              const Text('Zutaten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...recipe.ingredients.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${i['quantity'] ?? ''} ${i['unit'] ?? ''} ${i['name'] ?? ''}'.trim(),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),

              // Instructions
              const Text('Zubereitung', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...recipe.instructions.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value, style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  final CustomRecipe recipe;

  const _LikeButton({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ref.read(customRecipesProvider.notifier).toggleLike(recipe.id),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recipe.isLikedByMe ? Iconsax.heart5 : Iconsax.heart,
              size: 20,
              color: recipe.isLikedByMe ? Colors.red : AppTheme.textSecondary,
            ),
            if (recipe.likeCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${recipe.likeCount}',
                style: TextStyle(
                  fontSize: 13,
                  color: recipe.isLikedByMe ? Colors.red : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FollowingStories extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followState = ref.watch(followProvider);
    final profilesAsync = ref.watch(followedUsersProfilesProvider);

    return profilesAsync.when(
      data: (profiles) {
        if (profiles.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Gefolgt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final name = profile.communityName ?? 'Anonym';
                  return GestureDetector(
                    onTap: () => context.push('/profile/${profile.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 64,
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey[200]),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AuthorChip extends ConsumerWidget {
  final String userId;
  final String? authorName;

  const _AuthorChip({required this.userId, this.authorName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;

    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(Iconsax.user, size: 10, color: AppTheme.primaryColor)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          authorName ?? 'Anonym',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
