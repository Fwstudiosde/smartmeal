import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../config/revenuecat_config.dart';
import '../models/subscription_tier.dart';
import '../providers/subscription_provider.dart';
import 'paywall_screen.dart';

/// Open the paywall. Returns true if the user purchased (or restored to a
/// paid entitlement).
///
/// Always uses the in-app [PaywallScreen] so we own the UX end-to-end
/// (consistent German copy, App Store screenshots, graceful fallback prices
/// in iOS Simulator). The RevenueCat native paywall can be re-enabled later
/// by wrapping this call path once a paywall is published on the RC dashboard.
Future<bool> showPaywall(
  BuildContext context, {
  String? reason,
  SubscriptionTier recommended = SubscriptionTier.pro,
}) async {
  final res = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(
        reason: reason,
        recommended: recommended,
      ),
    ),
  );
  return res == true;
}

/// Guard: returns immediately if the user is already on the required tier.
/// Otherwise presents the paywall and resolves to the outcome.
Future<bool> requireProOrPaywall(
  WidgetRef ref,
  BuildContext context, {
  String? reason,
  bool requireFamily = false,
}) async {
  final tier = ref.read(subscriptionProvider);
  if (requireFamily) {
    if (tier == SubscriptionTier.proFamily) return true;
  } else {
    if (tier.isPaid) return true;
  }
  return showPaywall(
    context,
    reason: reason,
    recommended: requireFamily
        ? SubscriptionTier.proFamily
        : SubscriptionTier.pro,
  );
}

/// Opens the RevenueCat Customer Center for active subscribers: manage
/// subscription, restore, contact support, billing history. No-op on
/// unsupported platforms.
Future<void> showCustomerCenter(BuildContext context) async {
  if (kIsWeb || !RevenueCatConfig.isConfigured) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abo-Verwaltung nur auf iOS/Android'),
        ),
      );
    }
    return;
  }
  try {
    await RevenueCatUI.presentCustomerCenter();
  } catch (e) {
    debugPrint('Customer Center error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }
}

/// Visual "Pro" badge for use in list tiles / buttons.
class ProBadge extends StatelessWidget {
  final bool small;
  const ProBadge({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 8 : 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
