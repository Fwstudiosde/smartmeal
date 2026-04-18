import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_tier.dart';
import '../providers/subscription_provider.dart';
import 'paywall_screen.dart';

/// Opens the paywall modally. Returns true if the user purchased.
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

/// Guard helper: if the user is not Pro, opens the paywall and returns false.
/// If user is Pro (or higher), returns true immediately.
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
  return await showPaywall(
    context,
    reason: reason,
    recommended: requireFamily
        ? SubscriptionTier.proFamily
        : SubscriptionTier.pro,
  );
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
