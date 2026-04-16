import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';
import 'package:smartmeal/features/community/providers/follow_provider.dart';
import 'package:smartmeal/features/community/providers/user_profile_provider.dart';
import 'package:smartmeal/features/deals_scanner/providers/custom_recipes_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final recipesAsync = ref.watch(userPublicRecipesProvider(userId));
    final followState = ref.watch(followProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwnProfile = currentUserId == userId;
    final isFollowing = followState.followingIds.contains(userId);
    final followerCount = ref.watch(followerCountProvider(userId));
    final followingCount = ref.watch(followingCountProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: AppTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left),
              onPressed: () => context.pop(),
            ),
            pinned: true,
            title: profileAsync.when(
              data: (profile) => Text(profile?.communityName ?? 'Profil'),
              loading: () => const Text('Profil'),
              error: (_, __) => const Text('Profil'),
            ),
          ),

          // Profile Header
          SliverToBoxAdapter(
            child: profileAsync.when(
              data: (profile) => _buildProfileHeader(
                context, ref, profile, isOwnProfile, isFollowing,
                followerCount, followingCount,
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              ),
              error: (_, __) => const SizedBox(
                height: 100,
                child: Center(child: Text('Profil konnte nicht geladen werden')),
              ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Rezepte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // Recipes
          recipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.book, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'Noch keine Rezepte',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = recipes[index];
                      return _ProfileRecipeCard(recipe: recipe)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * index))
                          .slideY(begin: 0.1, end: 0);
                    },
                    childCount: recipes.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            ),
            error: (_, __) => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Fehler beim Laden')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    bool isOwnProfile,
    bool isFollowing,
    AsyncValue<int> followerCount,
    AsyncValue<int> followingCount,
  ) {
    final name = profile?.communityName ?? 'Anonym';
    final avatarUrl = profile?.avatarUrl;
    final recipesAsync = ref.watch(userPublicRecipesProvider(userId));
    final recipeCount = recipesAsync.valueOrNull?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Rezepte', recipeCount),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              _buildStat(
                'Follower',
                followerCount.when(
                  data: (c) => c,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              _buildStat(
                'Folgt',
                followingCount.when(
                  data: (c) => c,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Follow button — always show for other users
          if (!isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(followProvider.notifier).toggleFollow(userId);
                  ref.invalidate(followerCountProvider(userId));
                },
                icon: Icon(
                  isFollowing ? Iconsax.user_minus : Iconsax.user_add,
                  size: 18,
                ),
                label: Text(isFollowing ? 'Entfolgen' : 'Folgen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey[200] : AppTheme.primaryColor,
                  foregroundColor: isFollowing ? AppTheme.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isFollowing ? 0 : 2,
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _ProfileRecipeCard extends StatelessWidget {
  final CustomRecipe recipe;

  const _ProfileRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    final colors = [
      const Color(0xFF2E7D32), const Color(0xFF1565C0),
      const Color(0xFFE65100), const Color(0xFF6A1B9A),
      const Color(0xFF00838F), const Color(0xFFC62828),
    ];
    final color = colors[recipe.name.length % colors.length];

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
        onTap: () => context.push('/recipe/${recipe.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: hasImage
                  ? Image.network(
                      recipe.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                          ),
                        ),
                        child: Center(
                          child: Icon(Iconsax.reserve, size: 36, color: Colors.white.withOpacity(0.6)),
                        ),
                      ),
                    )
                  : Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                        ),
                      ),
                      child: Center(
                        child: Icon(Iconsax.reserve, size: 36, color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Iconsax.timer_1, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.prepTime + recipe.cookTime} Min',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Icon(Iconsax.chart_21, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        recipe.difficulty,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      if (recipe.likeCount > 0) ...[
                        Icon(Iconsax.heart5, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.likeCount}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
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
}
