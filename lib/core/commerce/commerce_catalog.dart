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

  /// Donation — Astra spend, no entitlement.
  static const donationTip = CommerceProduct(
    id: 'donation_tip_10',
    kind: ProductKind.donation,
    payment: PaymentOption(
      policy: PaymentPolicy.premiumOnly,
      premiumPrice: 10,
    ),
  );

  static const List<CommerceProduct> all = [
    premiumPack100,
    themeFlex,
    themePremiumOnly,
    donationTip,
  ];

  static CommerceProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
