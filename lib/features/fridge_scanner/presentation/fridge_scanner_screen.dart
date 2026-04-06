import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/fridge_scanner/providers/pantry_provider.dart';

const _uuid = Uuid();

class FridgeScannerScreen extends ConsumerStatefulWidget {
  const FridgeScannerScreen({super.key});

  @override
  ConsumerState<FridgeScannerScreen> createState() => _FridgeScannerScreenState();
}

class _FridgeScannerScreenState extends ConsumerState<FridgeScannerScreen> {
  bool _isScannerOpen = false;
  bool _isLoadingProduct = false;

  Future<void> _onBarcodeDetected(String barcode) async {
    if (_isLoadingProduct) return;
    setState(() {
      _isScannerOpen = false;
      _isLoadingProduct = true;
    });
    try {
      final client = ref.read(openFoodFactsProvider);
      final product = await client.getProductByBarcode(barcode);
      if (product != null) {
        final item = PantryItem.fromOpenFoodFacts(barcode, product);
        ref.read(pantryProvider.notifier).addItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${item.name} hinzugefuegt', maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Produkt nicht gefunden'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoadingProduct = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryItems = ref.watch(filteredPantryProvider);
    final allItems = ref.watch(pantryProvider);
    final stats = ref.watch(pantryStatsProvider);
    final activeFilter = ref.watch(pantryFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildHeader(context, stats)),
            ),

            // Action row (scan buttons)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildActionRow(context)),
            ),

            // Scanner view
            if (_isScannerOpen)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverToBoxAdapter(child: _buildScannerView()),
              ),

            // Category filter
            if (allItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildCategoryFilter(context, activeFilter),
                ),
              ),

            // Pantry list or empty state
            if (allItems.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                sliver: SliverToBoxAdapter(child: _buildEmptyState(context)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = pantryItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PantryItemCard(item: item),
                      ).animate().fadeIn(duration: 250.ms, delay: (40 * index).ms);
                    },
                    childCount: pantryItems.length,
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
        Text(
          'Meine',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Speisekammer',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        // Stats row
        if (stats.totalItems > 0)
          Row(
            children: [
              Expanded(child: _MiniStat(icon: Iconsax.box_1, value: '${stats.totalItems}', label: 'Artikel', color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(icon: Iconsax.category, value: '${stats.categories}', label: 'Kategorien', color: const Color(0xFF6366F1))),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(
                icon: Iconsax.flash_1,
                value: stats.avgCaloriesPer100g > 0 ? '${stats.avgCaloriesPer100g.toStringAsFixed(0)}' : '-',
                label: 'kcal/100g',
                color: AppColors.accent,
              )),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showManualAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final packagingSizeCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final brandCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    DateTime? expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Produkt hinzufuegen', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('* Pflichtfelder', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(height: 20),

                // === Pflichtfelder ===
                _buildLabel('Produktname *'),
                const SizedBox(height: 6),
                _buildTextField(nameCtrl, 'z.B. Vollmilch', Iconsax.box_1, autofocus: true),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Packungsgroesse *'),
                          const SizedBox(height: 6),
                          _buildTextField(packagingSizeCtrl, 'z.B. 1L, 500g', Iconsax.weight),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Menge *'),
                          const SizedBox(height: 6),
                          _buildTextField(quantityCtrl, '1', Iconsax.hashtag, keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildDivider('Optional'),
                const SizedBox(height: 16),

                // === Optionale Felder ===
                _buildLabel('Marke'),
                const SizedBox(height: 6),
                _buildTextField(brandCtrl, 'z.B. Weihenstephan', Iconsax.tag),
                const SizedBox(height: 14),

                _buildLabel('Kategorie'),
                const SizedBox(height: 6),
                _buildCategorySelector(categoryCtrl, setSheetState),
                const SizedBox(height: 14),

                // MHD
                _buildLabel('Mindesthaltbar bis'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      locale: const Locale('de'),
                    );
                    if (picked != null) {
                      setSheetState(() => expiryDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.calendar_1, size: 20, color: AppColors.textTertiary),
                        const SizedBox(width: 12),
                        Text(
                          expiryDate != null
                              ? '${expiryDate!.day.toString().padLeft(2, '0')}.${expiryDate!.month.toString().padLeft(2, '0')}.${expiryDate!.year}'
                              : 'Datum waehlen',
                          style: TextStyle(
                            fontSize: 15,
                            color: expiryDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        if (expiryDate != null)
                          GestureDetector(
                            onTap: () => setSheetState(() => expiryDate = null),
                            child: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildDivider('Naehrwerte pro 100g'),
                const SizedBox(height: 16),

                // Nährwerte 2x2 Grid
                Row(
                  children: [
                    Expanded(child: _buildNutritionField(caloriesCtrl, 'Kalorien', 'kcal')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNutritionField(proteinCtrl, 'Eiweiss', 'g')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNutritionField(carbsCtrl, 'Kohlenhydrate', 'g')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNutritionField(fatCtrl, 'Fett', 'g')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNutritionField(fiberCtrl, 'Ballaststoffe', 'g')),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 28),

                // Submit
                GestureDetector(
                  onTap: () {
                    final name = nameCtrl.text.trim();
                    final packaging = packagingSizeCtrl.text.trim();
                    final qty = int.tryParse(quantityCtrl.text.trim()) ?? 1;
                    if (name.isEmpty || packaging.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Bitte Name, Packungsgroesse und Menge ausfuellen'),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    NutritionInfo? nutrition;
                    final cal = int.tryParse(caloriesCtrl.text.trim());
                    if (cal != null) {
                      nutrition = NutritionInfo(
                        calories: cal,
                        protein: double.tryParse(proteinCtrl.text.trim()) ?? 0,
                        carbs: double.tryParse(carbsCtrl.text.trim()) ?? 0,
                        fat: double.tryParse(fatCtrl.text.trim()) ?? 0,
                        fiber: double.tryParse(fiberCtrl.text.trim()),
                      );
                    }

                    final item = PantryItem(
                      id: _uuid.v4(),
                      barcode: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : null,
                      category: categoryCtrl.text.isNotEmpty ? categoryCtrl.text : 'Sonstiges',
                      quantity: qty,
                      packagingSize: packaging,
                      expiryDate: expiryDate,
                      nutrition: nutrition,
                      addedAt: DateTime.now(),
                    );
                    ref.read(pantryProvider.notifier).addItem(item);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name hinzugefuegt'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Hinzufuegen', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool autofocus = false, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildNutritionField(TextEditingController ctrl, String label, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: unit,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        Container(width: 30, height: 1, color: AppColors.surfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppColors.surfaceVariant)),
      ],
    );
  }

  Widget _buildCategorySelector(TextEditingController ctrl, StateSetter setSheetState) {
    const categories = ['Milchprodukte', 'Fleisch', 'Fisch', 'Gemuese', 'Obst', 'Getreide', 'Getraenke', 'Snacks', 'Tiefkuehl', 'Sonstiges'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final isSelected = ctrl.text == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setSheetState(() => ctrl.text = isSelected ? '' : cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isScannerOpen = !_isScannerOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isScannerOpen ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isScannerOpen ? AppColors.accent : AppColors.surfaceVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingProduct)
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _isScannerOpen ? Colors.white : AppColors.accent,
                      ),
                    )
                  else
                    Icon(
                      _isScannerOpen ? Iconsax.close_circle : Iconsax.scan_barcode,
                      size: 18,
                      color: _isScannerOpen ? Colors.white : AppColors.accent,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isScannerOpen ? 'Schliessen' : 'Scannen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isScannerOpen ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _showManualAddDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.add_circle, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Manuell',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildScannerView() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _onBarcodeDetected(barcodes.first.rawValue!);
              }
            },
          ),
          Center(
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Barcode in den Rahmen halten',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _isScannerOpen = false),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.03);
  }

  Widget _buildCategoryFilter(BuildContext context, String? active) {
    final allItems = ref.watch(pantryProvider);
    final categories = <String>{};
    for (final item in allItems) {
      if (item.category != null) categories.add(item.category!);
    }

    return SizedBox(
      height: 36,
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
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Iconsax.box_1, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Deine Speisekammer ist leer',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Scanne einen Barcode oder mache ein Foto\num Produkte hinzuzufuegen.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

// === Small Widgets ===

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.surfaceVariant),
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
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(pantryProvider.notifier).removeItem(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Iconsax.trash, color: AppColors.error, size: 20),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 50, height: 50, fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (item.brand != null) ...[
                        Text(item.brand!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                      ],
                      if (item.packagingSize != null)
                        Text(item.packagingSize!, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      if (item.packagingSize != null && item.nutrition != null)
                        Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      if (item.nutrition != null)
                        Text('${item.nutrition!.calories} kcal', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                  if (item.expiryDate != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 12,
                          color: item.isExpired ? AppColors.error : item.isExpiringSoon ? AppColors.warning : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MHD ${item.expiryDate!.day.toString().padLeft(2, '0')}.${item.expiryDate!.month.toString().padLeft(2, '0')}.${item.expiryDate!.year}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.isExpired ? AppColors.error : item.isExpiringSoon ? AppColors.warning : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Nutri-Score
            if (item.nutriScore != null) ...[
              _NutriScoreBadge(score: item.nutriScore!),
              const SizedBox(width: 10),
            ],
            // Quantity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => ref.read(pantryProvider.notifier).decreaseQuantity(item.id),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.remove, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(pantryProvider.notifier).increaseQuantity(item.id),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Iconsax.box_1, size: 20, color: AppColors.textTertiary),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        score.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
