import 'commerce_models.dart';

/// First-ship product seed (domain catalog — not Steam SKU registration).
abstract final class CommerceCatalog {
  static const premiumPack100 = CommerceProduct(
    id: 'astra_pack_100',
    kind: ProductKind.premiumPack,
    payment: PaymentOption(policy: PaymentPolicy.premiumOnly),
    grantPremiumAmount: 100,
  );

  /// Theme unlockable with Astra or Echo (buyer chooses one).
  static const themeFlex = CommerceProduct(
    id: 'theme_unlock_flex',
    kind: ProductKind.themeUnlock,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: 50,
      earnedPrice: 80,
    ),
    entitlementKey: 'theme:flex_demo',
  );

  /// Astra-only theme.
  static const themePremiumOnly = CommerceProduct(
    id: 'theme_unlock_astra_only',
    kind: ProductKind.themeUnlock,
    payment: PaymentOption(
      policy: PaymentPolicy.premiumOnly,
      premiumPrice: 60,
    ),
    entitlementKey: 'theme:astra_only_demo',
  );

  /// Second choose-one theme (for multi-unlock tests).
  static const themeFlexB = CommerceProduct(
    id: 'theme_unlock_flex_b',
    kind: ProductKind.themeUnlock,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: 50,
      earnedPrice: 40,
    ),
    entitlementKey: 'theme:flex_b_demo',
  );

  /// Developer support — Astra spend, no entitlement (not a charity donation).
  static const supportAkasha = CommerceProduct(
    id: 'support_akasha_10',
    kind: ProductKind.support,
    payment: PaymentOption(
      policy: PaymentPolicy.premiumOnly,
      premiumPrice: 10,
    ),
    displayNameEn: 'Support AKASHA',
    displayNameKo: 'AKASHA 후원',
  );

  static const List<CommerceProduct> all = [
    premiumPack100,
    themeFlex,
    themeFlexB,
    themePremiumOnly,
    supportAkasha,
  ];

  static CommerceProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
