import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/features/cart/providers/meal_plan_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 32),
                
                // Main Feature Cards
                _buildFeatureCards(context),
                const SizedBox(height: 32),
                
                // Quick Stats
                _buildQuickStats(context, ref),
                const SizedBox(height: 32),
                
                // Tips Section
                _buildTipsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour < 12) {
      greeting = 'Guten Morgen';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Guten Tag';
      emoji = '👋';
    } else {
      greeting = 'Guten Abend';
      emoji = '🌙';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$greeting $emoji',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 8),
        Text(
          'Was kochst du heute?',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.primary,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        // Fridge Scanner Card
        _FeatureCard(
          title: 'Kühlschrank Scanner',
          subtitle: 'Fotografiere deinen Kühlschrank und erhalte passende Rezepte',
          icon: Iconsax.scan,
          gradient: AppColors.primaryGradient,
          onTap: () => context.go('/fridge'),
          imagePath: 'assets/images/fridge.png',
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 16),
        
        // Deals Scanner Card
        _FeatureCard(
          title: 'Angebots-Finder',
          subtitle: 'Finde günstige Rezepte aus aktuellen Supermarkt-Angeboten',
          icon: Iconsax.discount_shape,
          gradient: AppColors.accentGradient,
          onTap: () => context.go('/deals'),
          imagePath: 'assets/images/deals.png',
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(currentMealPlanProvider);
    final mealCount = mealPlan?.meals.length ?? 0;
    final cookedCount = mealPlan?.meals.where((m) => m.isCooked).length ?? 0;
    final totalSavings = mealPlan?.totalSavings ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diese Woche',
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Iconsax.book_saved,
                value: '$mealCount',
                label: mealCount == 1 ? 'Rezept geplant' : 'Rezepte geplant',
                color: AppColors.primary,
              ).animate().fadeIn(duration: 400.ms, delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Iconsax.wallet_money,
                value: '€${totalSavings.toStringAsFixed(0)}',
                label: 'gespart',
                color: AppColors.accent,
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
            ),
          ],
        ),
        if (cookedCount > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Iconsax.tick_circle,
                  value: '$cookedCount',
                  label: cookedCount == 1 ? 'Gericht gekocht' : 'Gerichte gekocht',
                  color: Colors.green,
                ).animate().fadeIn(duration: 400.ms, delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
              const SizedBox(width: 12),
              Expanded(child: const SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipps & Tricks',
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
        const SizedBox(height: 16),
        _TipCard(
          emoji: '💡',
          title: 'Besser Scannen',
          description: 'Fotografiere deinen Kühlschrank bei gutem Licht für beste Ergebnisse.',
        ).animate().fadeIn(duration: 400.ms, delay: 800.ms).slideX(begin: 0.1),
        const SizedBox(height: 12),
        _TipCard(
          emoji: '🛒',
          title: 'Clever Einkaufen',
          description: 'Checke die Angebote bevor du einkaufen gehst und plane deine Mahlzeiten.',
        ).animate().fadeIn(duration: 400.ms, delay: 900.ms).slideX(begin: 0.1),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final String? imagePath;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Starten',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Iconsax.arrow_right_3,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _TipCard({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
