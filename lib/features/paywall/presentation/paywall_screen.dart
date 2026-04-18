import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/subscription_tier.dart';
import '../providers/subscription_provider.dart';

/// Full-screen paywall. Optional [reason] shows a context headline
/// (e.g. "Um den Kühlschrank-Scanner zu nutzen…").
class PaywallScreen extends ConsumerStatefulWidget {
  final String? reason;
  final SubscriptionTier recommended;

  const PaywallScreen({
    super.key,
    this.reason,
    this.recommended = SubscriptionTier.pro,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late SubscriptionTier _selected;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.recommended;
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isBuying = true);
    try {
      final tier = await ref
          .read(subscriptionProvider.notifier)
          .purchase(package);
      if (!mounted) return;
      if (tier.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Willkommen bei SparKoch Pro!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (!msg.contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kauf fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isBuying = true);
    try {
      final tier = await ref.read(subscriptionProvider.notifier).restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tier.isPaid
              ? 'Abo wiederhergestellt: ${tier.label}'
              : 'Kein aktives Abo gefunden'),
          backgroundColor: tier.isPaid ? AppColors.success : Colors.grey,
        ),
      );
      if (tier.isPaid) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wiederherstellung fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.crown_1,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SparKoch Pro',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.reason ??
                        'Mehr sparen. Mehr kochen. Weniger Grenzen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Feature grid
                  _FeatureTile(
                    icon: Iconsax.camera,
                    title: 'Kühlschrank-Scanner',
                    desc: 'Fotografiere deinen Kühlschrank, KI erkennt '
                        'alle Zutaten und schlägt Rezepte vor.',
                    onlyPro: true,
                  ),
                  _FeatureTile(
                    icon: Iconsax.calendar,
                    title: '4 Wochen Essensplanung',
                    desc: 'Plane mehrere Wochen im Voraus mit Vorlagen '
                        'und automatischer Einkaufsliste.',
                  ),
                  _FeatureTile(
                    icon: Iconsax.notification,
                    title: 'Deal-Alerts',
                    desc: 'Push-Benachrichtigung wenn deine Lieblings'
                        'produkte im Angebot sind.',
                  ),
                  _FeatureTile(
                    icon: Iconsax.chart_2,
                    title: 'Ersparnis-Report',
                    desc: 'Wochen- und Monatsauswertung, wie viel du '
                        'durch Spar-Rezepte gespart hast.',
                  ),
                  _FeatureTile(
                    icon: Iconsax.box,
                    title: 'Unbegrenzte Speisekammer',
                    desc: 'Barcode-Scan ohne Limit.',
                  ),
                  _FeatureTile(
                    icon: Iconsax.document_download,
                    title: 'Einkaufsliste als PDF',
                    desc: 'Liste teilen oder ausdrucken.',
                  ),
                  _FeatureTile(
                    icon: Iconsax.shield_tick,
                    title: 'Werbefrei',
                    desc: 'Volle Konzentration aufs Kochen.',
                  ),

                  const SizedBox(height: 8),

                  // Plan cards
                  offeringsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Abos konnten nicht geladen werden: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (pkgs) {
                      return Column(
                        children: [
                          if (pkgs.pro != null)
                            _PlanCard(
                              title: 'Pro',
                              price: pkgs.pro!.storeProduct.priceString,
                              period: 'pro Monat',
                              features: const [
                                'Kühlschrank-Scanner unbegrenzt',
                                'Alle Premium-Features',
                                'Für dich alleine',
                              ],
                              selected: _selected == SubscriptionTier.pro,
                              onTap: () => setState(
                                  () => _selected = SubscriptionTier.pro),
                            ),
                          if (pkgs.family != null) ...[
                            const SizedBox(height: 12),
                            _PlanCard(
                              title: 'Pro Familie',
                              price: pkgs.family!.storeProduct.priceString,
                              period: 'pro Monat',
                              badge: 'Beliebt',
                              features: const [
                                'Alles aus Pro',
                                'Haushalt mit bis zu 6 Personen',
                                'Geteilter Wochenplan + Einkaufsliste',
                              ],
                              selected:
                                  _selected == SubscriptionTier.proFamily,
                              onTap: () => setState(() =>
                                  _selected = SubscriptionTier.proFamily),
                            ),
                          ],
                          if (pkgs.pro == null && pkgs.family == null)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Abos sind gerade nicht verfügbar. '
                                'Bitte später nochmal probieren.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Purchase button
                  offeringsAsync.maybeWhen(
                    data: (pkgs) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isBuying
                            ? null
                            : () {
                                final pkg = _selected ==
                                        SubscriptionTier.proFamily
                                    ? pkgs.family
                                    : pkgs.pro;
                                if (pkg != null) _purchase(pkg);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isBuying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Jetzt starten',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isBuying ? null : _restore,
                    child: const Text('Käufe wiederherstellen'),
                  ),

                  const SizedBox(height: 8),
                  const _LegalBlock(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool onlyPro;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
    this.onlyPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (onlyPro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final List<String> features;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.features,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalBlock extends StatelessWidget {
  const _LegalBlock();

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      fontSize: 10,
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    );
    return Column(
      children: [
        Text(
          'Das Abo verlängert sich automatisch zum oben genannten Preis, '
          'solange es nicht mindestens 24 Stunden vor Ablauf gekündigt wird. '
          'Verwaltung und Kündigung in den Einstellungen deiner Apple-ID.',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://sparkoch.de/agb'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text('AGB', style: linkStyle),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://sparkoch.de/datenschutz'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text('Datenschutz', style: linkStyle),
            ),
          ],
        ),
      ],
    );
  }
}
