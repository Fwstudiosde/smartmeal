/// What the user is currently entitled to.
/// ProFamily is a superset of Pro — if the user has pro_family, they have all
/// Pro features too.
enum SubscriptionTier {
  free,
  pro,
  proFamily,
}

extension SubscriptionTierX on SubscriptionTier {
  bool get isPaid =>
      this == SubscriptionTier.pro || this == SubscriptionTier.proFamily;
  bool get isFamily => this == SubscriptionTier.proFamily;

  String get label {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.proFamily:
        return 'Pro Familie';
    }
  }

  /// Household member limit by tier.
  int get maxHouseholdMembers {
    switch (this) {
      case SubscriptionTier.free:
        return 1; // solo — no real sharing
      case SubscriptionTier.pro:
        return 2; // couples
      case SubscriptionTier.proFamily:
        return 6;
    }
  }

  /// Pantry item cap. null = unlimited.
  int? get maxPantryItems {
    switch (this) {
      case SubscriptionTier.free:
        return 20;
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return null;
    }
  }

  /// Custom recipe cap. null = unlimited.
  int? get maxCustomRecipes {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return null;
    }
  }

  /// Saved/bookmarked recipes cap. null = unlimited.
  int? get maxBookmarks {
    switch (this) {
      case SubscriptionTier.free:
        return 10;
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return null;
    }
  }

  /// Weeks user can navigate in meal plan. null = unlimited.
  int? get mealPlanWeeksAhead {
    switch (this) {
      case SubscriptionTier.free:
        return 0; // only current week
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return null;
    }
  }

  /// Fridge scanner is Pro-only (AI cost). No free scans.
  bool get hasFridgeScanner {
    return this != SubscriptionTier.free;
  }

  /// Push deal-alerts for favorite products/categories.
  bool get hasDealAlerts {
    return this != SubscriptionTier.free;
  }

  /// Savings report (weekly/monthly).
  bool get hasSavingsReport {
    return this != SubscriptionTier.free;
  }

  /// Ad-free experience (in case we add ads later for free tier).
  bool get isAdFree {
    return this != SubscriptionTier.free;
  }
}
