import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/revenuecat_config.dart';
import '../models/subscription_tier.dart';

/// Thin RevenueCat wrapper. Call `initialize()` once at app start.
/// Exposes streams/poll functions to read the current tier.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  bool _initialized = false;
  Offerings? _offerings;

  bool get isAvailable =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> initialize({required String appUserId}) async {
    if (!isAvailable) return;
    if (!RevenueCatConfig.isConfigured) return;

    if (_initialized) {
      // Already configured for a previous user — just rebind to the new uid.
      await identify(appUserId);
      return;
    }

    final key = Platform.isIOS
        ? RevenueCatConfig.iosApiKey
        : RevenueCatConfig.androidApiKey;
    if (key.contains('PUT_')) return;

    await Purchases.setLogLevel(LogLevel.warn);
    final config = PurchasesConfiguration(key)..appUserID = appUserId;
    await Purchases.configure(config);

    try {
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RC getOfferings error: $e');
    }

    _initialized = true;
  }

  /// Bind RC to a new auth user (call when the app user logs in / switches).
  Future<void> identify(String appUserId) async {
    if (!isAvailable || !RevenueCatConfig.isConfigured) return;
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      debugPrint('RC logIn error: $e');
    }
  }

  Future<void> logout() async {
    if (!isAvailable || !RevenueCatConfig.isConfigured) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  /// Resolve current tier from the active entitlements.
  Future<SubscriptionTier> currentTier() async {
    if (!isAvailable || !RevenueCatConfig.isConfigured) {
      return SubscriptionTier.free;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active
          .containsKey(RevenueCatConfig.entitlementProFamily)) {
        return SubscriptionTier.proFamily;
      }
      if (info.entitlements.active
          .containsKey(RevenueCatConfig.entitlementPro)) {
        return SubscriptionTier.pro;
      }
    } catch (e) {
      debugPrint('RC currentTier error: $e');
    }
    return SubscriptionTier.free;
  }

  Stream<CustomerInfo> get customerInfoStream {
    if (!isAvailable || !RevenueCatConfig.isConfigured) {
      return const Stream.empty();
    }
    final controller = Purchases.addCustomerInfoUpdateListener;
    return _customerInfoBroadcaster(controller);
  }

  Stream<CustomerInfo> _customerInfoBroadcaster(
      void Function(Function(CustomerInfo)) register) async* {
    final subs = <Function(CustomerInfo)>[];
    register((info) {
      for (final s in List.of(subs)) {
        s(info);
      }
    });
    final controller = Stream<CustomerInfo>.multi((c) {
      void onInfo(CustomerInfo i) => c.add(i);
      subs.add(onInfo);
      c.onCancel = () => subs.remove(onInfo);
    });
    yield* controller;
  }

  /// Returns the RC Offering's packages.
  Future<({Package? pro, Package? family})> getPackages() async {
    if (!isAvailable || !RevenueCatConfig.isConfigured) {
      return (pro: null, family: null);
    }
    try {
      _offerings ??= await Purchases.getOfferings();
      final offering =
          _offerings?.getOffering(RevenueCatConfig.defaultOffering) ??
              _offerings?.current;
      if (offering == null) return (pro: null, family: null);

      Package? pro;
      Package? family;
      for (final pkg in offering.availablePackages) {
        final id = pkg.storeProduct.identifier;
        if (id == RevenueCatConfig.productProMonthly) pro = pkg;
        if (id == RevenueCatConfig.productProFamilyMonthly) family = pkg;
      }
      return (pro: pro, family: family);
    } catch (e) {
      debugPrint('RC getPackages error: $e');
      return (pro: null, family: null);
    }
  }

  /// Attempt purchase. Returns the new tier on success, or throws on failure.
  Future<SubscriptionTier> purchase(Package package) async {
    final info = await Purchases.purchasePackage(package);
    if (info.entitlements.active
        .containsKey(RevenueCatConfig.entitlementProFamily)) {
      return SubscriptionTier.proFamily;
    }
    if (info.entitlements.active
        .containsKey(RevenueCatConfig.entitlementPro)) {
      return SubscriptionTier.pro;
    }
    return SubscriptionTier.free;
  }

  Future<SubscriptionTier> restore() async {
    if (!isAvailable || !RevenueCatConfig.isConfigured) {
      return SubscriptionTier.free;
    }
    final info = await Purchases.restorePurchases();
    if (info.entitlements.active
        .containsKey(RevenueCatConfig.entitlementProFamily)) {
      return SubscriptionTier.proFamily;
    }
    if (info.entitlements.active
        .containsKey(RevenueCatConfig.entitlementPro)) {
      return SubscriptionTier.pro;
    }
    return SubscriptionTier.free;
  }
}
