import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/deals_service.dart';
import 'package:smartmeal/features/deals_scanner/providers/deals_providers.dart';

class DealsScannerScreen extends ConsumerStatefulWidget {
  const DealsScannerScreen({super.key});

  @override
  ConsumerState<DealsScannerScreen> createState() => _DealsScannerScreenState();
}

class _DealsScannerScreenState extends ConsumerState<DealsScannerScreen> {
  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsProvider);
    final selectedStores = ref.watch(selectedSupermarketsProvider);
    final supermarketsAsync = ref.watch(supermarketsProvider);

    final supermarkets = supermarketsAsync.when(
      data: (data) => data,
      loading: () => <Supermarket>[],
      error: (_, __) => <Supermarket>[],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Angebots-',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  Text(
                    'Finder',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  Text(
                    'Finde die besten Angebote und spare bei deinen Rezepten.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 24),
                  
                  // Store selector
                  _buildStoreSelector(supermarkets, selectedStores),
                ],
              ),
            ),
            
            // Deals list
            Expanded(
              child: dealsAsync.when(
                data: (deals) => deals.isEmpty
                    ? _buildEmptyState()
                    : _buildDealsList(deals),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error),
              ),
            ),
            
            // Generate recipes button
            _buildGenerateButton(dealsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSelector(List<Supermarket> supermarkets, Set<String> selectedStores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supermärkte auswählen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: supermarkets.length,
            itemBuilder: (context, index) {
              final store = supermarkets[index];
              final isSelected = selectedStores.isEmpty || selectedStores.contains(store.id);
              
              return Padding(
                padding: EdgeInsets.only(right: index < supermarkets.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedSupermarketsProvider.notifier).toggle(store.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? store.brandColor.withOpacity(0.15) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? store.brandColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Icon(
                            Iconsax.tick_circle5,
                            size: 18,
                            color: store.brandColor,
                          ),
                        if (isSelected) const SizedBox(width: 8),
                        Text(
                          store.name,
                          style: TextStyle(
                            color: isSelected ? store.brandColor : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 350 + (index * 50)))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Angebote werden geladen...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Iconsax.discount_shape,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Angebote gefunden',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Wähle andere Supermärkte aus oder versuche es später erneut.',
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

  Widget _buildErrorState(Object error) {
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(dealsProvider),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsList(List<Deal> deals) {
    // Group deals by store
    final Map<String, List<Deal>> groupedDeals = {};
    for (final deal in deals) {
      groupedDeals.putIfAbsent(deal.storeName, () => []).add(deal);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: groupedDeals.length,
      itemBuilder: (context, index) {
        final storeName = groupedDeals.keys.elementAt(index);
        final storeDeals = groupedDeals[storeName]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${storeDeals.length} Angebote',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            ...storeDeals.asMap().entries.map((entry) {
              final dealIndex = entry.key;
              final deal = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DealCard(deal: deal)
                  .animate(delay: Duration(milliseconds: 100 * index + 50 * dealIndex))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildGenerateButton(AsyncValue<List<Deal>> dealsAsync) {
    final isLoading = ref.watch(isGeneratingRecipesProvider);

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
          onTap: isLoading || !dealsAsync.hasValue || dealsAsync.value!.isEmpty
              ? null
              : () async {
                  await ref.read(generateDealRecipesProvider)();
                  if (mounted) {
                    context.push('/deal-recipes');
                  }
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: !isLoading && dealsAsync.hasValue && dealsAsync.value!.isNotEmpty
                  ? AppColors.accentGradient
                  : null,
              color: isLoading || !dealsAsync.hasValue || dealsAsync.value!.isEmpty
                  ? AppColors.surfaceVariant
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: !isLoading && dealsAsync.hasValue && dealsAsync.value!.isNotEmpty
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
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
                    'Spar-Rezepte werden erstellt...',
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
                    'Spar-Rezepte finden',
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
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms).slideY(begin: 0.2);
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;

  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            child: deal.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: deal.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 70,
                      height: 70,
                      color: AppColors.surfaceVariant,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 70,
                      height: 70,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Iconsax.image, color: AppColors.textTertiary),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Iconsax.image, color: AppColors.textTertiary),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${deal.discountPrice.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${deal.originalPrice.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Discount badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '-${deal.discountPercentage.round()}%',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
