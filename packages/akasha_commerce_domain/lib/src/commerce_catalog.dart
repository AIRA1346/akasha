import 'commerce_models.dart';

/// Approved product policy (domain catalog — not Steam ItemDef registration).
abstract final class CommerceCatalog {
  /// Economy reference only. Local UI must display Steam's localized price,
  /// not derive a checkout price from this value.
  static const int astraUnitsPerReferenceUsd = 100;

  static const int launchThemeAstraPrice = 500;
  static const int launchThemeEchoPrice = 500;
  static const String astraPack500ProductId = 'astra_pack_500';
  static const String astraPack1000ProductId = 'astra_pack_1000';
  static const String astraPack2500ProductId = 'astra_pack_2500';
  static const String sakuraThemeProductId = 'theme_package_sakura';
  static const String sakuraThemeEntitlementKey = 'theme:sakura';
  static const String amethystThemeProductId = 'theme_package_amethyst';
  static const String amethystThemeEntitlementKey = 'theme:amethyst';
  static const String nocturneThemeProductId = 'theme_package_nocturne';
  static const String nocturneThemeEntitlementKey = 'theme:nocturne';

  static const astraPack500 = CommerceProduct(
    id: astraPack500ProductId,
    kind: ProductKind.premiumPack,
    grantPremiumAmount: 500,
    displayNameEn: '500 Astra',
    displayNameKo: '아스트라 500개',
  );

  static const astraPack1000 = CommerceProduct(
    id: astraPack1000ProductId,
    kind: ProductKind.premiumPack,
    grantPremiumAmount: 1000,
    displayNameEn: '1,000 Astra',
    displayNameKo: '아스트라 1,000개',
  );

  static const astraPack2500 = CommerceProduct(
    id: astraPack2500ProductId,
    kind: ProductKind.premiumPack,
    grantPremiumAmount: 2500,
    displayNameEn: '2,500 Astra',
    displayNameKo: '아스트라 2,500개',
  );

  static const sakuraThemePackage = CommerceProduct(
    id: sakuraThemeProductId,
    kind: ProductKind.themePackage,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: launchThemeAstraPrice,
      earnedPrice: launchThemeEchoPrice,
    ),
    entitlementKey: sakuraThemeEntitlementKey,
    displayNameEn: 'Sakura Theme Package',
    displayNameKo: '벚꽃 테마 패키지',
  );

  static const amethystThemePackage = CommerceProduct(
    id: amethystThemeProductId,
    kind: ProductKind.themePackage,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: launchThemeAstraPrice,
      earnedPrice: launchThemeEchoPrice,
    ),
    entitlementKey: amethystThemeEntitlementKey,
    displayNameEn: 'Amethyst Theme Package',
    displayNameKo: '자수정 테마 패키지',
  );

  static const nocturneThemePackage = CommerceProduct(
    id: nocturneThemeProductId,
    kind: ProductKind.themePackage,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: launchThemeAstraPrice,
      earnedPrice: launchThemeEchoPrice,
    ),
    entitlementKey: nocturneThemeEntitlementKey,
    displayNameEn: 'Nocturne Theme Package',
    displayNameKo: '녹턴 테마 패키지',
  );

  static const List<CommerceProduct> all = [
    ...astraPacks,
    sakuraThemePackage,
    amethystThemePackage,
    nocturneThemePackage,
  ];

  /// The only domain product IDs that a production adapter may map to priced
  /// Steam ItemDefs. Raw currency ItemDefs are never accepted for purchase.
  static const List<CommerceProduct> astraPacks = [
    astraPack500,
    astraPack1000,
    astraPack2500,
  ];

  static bool isApprovedAstraPack(String productId) =>
      astraPacks.any((product) => product.id == productId);

  static const List<CommerceProduct> launchThemePackages = [
    sakuraThemePackage,
    amethystThemePackage,
    nocturneThemePackage,
  ];

  static CommerceProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static CommerceProduct? byEntitlementKey(String entitlementKey) {
    for (final product in all) {
      if (product.entitlementKey == entitlementKey) return product;
    }
    return null;
  }
}
