/// RevenueCat configuration.
///
/// Fill these in after creating a RevenueCat project:
///   1. https://app.revenuecat.com -> new project "SparKoch"
///   2. Apps -> Add app (Apple + Google), link to Bundle ID de.sparkoch.app
///   3. Connect App Store Connect: upload your App Store Connect API key
///   4. Import your IAPs (sparkoch_pro_monthly, sparkoch_pro_family_monthly)
///   5. Create ONE entitlement named "pro_family" (it is the highest tier).
///      - Attach BOTH products to the entitlement's "pro_family" access when
///        user is on Pro Familie.
///      - Create a SECOND entitlement "pro" with ONLY the Pro product.
///   6. Create Offering "default" with two packages:
///      - $rc_monthly  -> product sparkoch_pro_monthly
///      - custom id "family_monthly" -> product sparkoch_pro_family_monthly
///   7. Grab Public API keys from Project settings -> API keys.
class RevenueCatConfig {
  // iOS + Android public API keys (one per platform).
  // Real production keys start with "appl_" (iOS) or "goog_" (Android) and
  // live under RevenueCat Dashboard -> Project Settings -> API keys.
  // The "test_..." key temporarily placed here is a placeholder; if it
  // fails at runtime, replace it with the real Apple App Store SDK key.
  static const String iosApiKey = 'appl_SGYIgQmbgFYrKsGyCpaotYubMTz';
  static const String androidApiKey = 'goog_PUT_ANDROID_KEY_HERE';

  // Entitlement identifiers as configured in RevenueCat dashboard.
  static const String entitlementPro = 'pro';
  static const String entitlementProFamily = 'pro_family';

  // Product identifiers in App Store Connect / Google Play.
  static const String productProMonthly = 'sparkoch_pro_monthly';
  static const String productProFamilyMonthly = 'sparkoch_pro_family_monthly';

  // Offering id in RevenueCat (default if you named it "default").
  static const String defaultOffering = 'default';

  static bool get isConfigured =>
      !iosApiKey.contains('PUT_') || !androidApiKey.contains('PUT_');

  /// True once the real Apple App Store SDK key is installed ("appl_" prefix).
  static bool get hasProductionIosKey => iosApiKey.startsWith('appl_');
}
