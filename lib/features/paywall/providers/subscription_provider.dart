import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/auth/providers/auth_provider.dart';
import '../config/revenuecat_config.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';

/// Which UI tier to show.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionTier>((ref) {
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  return SubscriptionNotifier(uid);
});

/// Current offerings (Pro + Family packages) — for paywall UI.
final offeringsProvider =
    FutureProvider<({Package? pro, Package? family})>((ref) {
  // Re-fetch when subscription changes so UI updates.
  ref.watch(subscriptionProvider);
  return SubscriptionService.instance.getPackages();
});

class SubscriptionNotifier extends StateNotifier<SubscriptionTier> {
  static const _cacheKey = 'subscription_tier';
  final String? _uid;

  SubscriptionNotifier(this._uid) : super(SubscriptionTier.free) {
    _loadFromCache();
    if (_uid != null) _bootstrap();
  }

  void _loadFromCache() {
    try {
      final box = Hive.box('settings');
      final stored = box.get(_cacheKey) as String?;
      if (stored != null) {
        state = SubscriptionTier.values.firstWhere(
          (t) => t.name == stored,
          orElse: () => SubscriptionTier.free,
        );
      }
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    if (!SubscriptionService.instance.isAvailable) return;
    if (!RevenueCatConfig.isConfigured) return;
    try {
      await SubscriptionService.instance.initialize(appUserId: _uid!);
      await refresh();
      // Listen for live updates (purchases, expirations).
      Purchases.addCustomerInfoUpdateListener((info) {
        if (info.entitlements.active
            .containsKey(RevenueCatConfig.entitlementProFamily)) {
          _set(SubscriptionTier.proFamily);
        } else if (info.entitlements.active
            .containsKey(RevenueCatConfig.entitlementPro)) {
          _set(SubscriptionTier.pro);
        } else {
          _set(SubscriptionTier.free);
        }
      });
    } catch (e) {
      debugPrint('Subscription bootstrap error: $e');
    }
  }

  Future<void> refresh() async {
    final tier = await SubscriptionService.instance.currentTier();
    _set(tier);
  }

  Future<SubscriptionTier> purchase(Package package) async {
    final tier = await SubscriptionService.instance.purchase(package);
    _set(tier);
    return tier;
  }

  Future<SubscriptionTier> restore() async {
    final tier = await SubscriptionService.instance.restore();
    _set(tier);
    return tier;
  }

  void _set(SubscriptionTier t) {
    if (state == t) return;
    state = t;
    try {
      Hive.box('settings').put(_cacheKey, t.name);
    } catch (_) {}
  }
}

/// Convenience readers
final isProProvider = Provider<bool>(
    (ref) => ref.watch(subscriptionProvider).isPaid);

final isProFamilyProvider = Provider<bool>(
    (ref) => ref.watch(subscriptionProvider).isFamily);
