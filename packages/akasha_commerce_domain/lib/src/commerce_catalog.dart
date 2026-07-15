import 'commerce_models.dart';

/// Approved product policy (domain catalog — not Steam ItemDef registration).
abstract final class CommerceCatalog {
  /// Economy reference only. Local UI must display Steam's localized price,
  /// not derive a checkout price from this value.
  static const int astraUnitsPerReferenceUsd = 100;

  static const int launchThemeAstraPrice = 500;
  static const int launchThemeEchoPrice = 500;
  static const String sakuraThemeProductId = 'theme_package_sakura';
  static const String sakuraThemeEntitlementKey = 'theme:sakura';
  static const String amethystThemeProductId = 'theme_package_amethyst';
  static const String amethystThemeEntitlementKey = 'theme:amethyst';
  static const String nocturneThemeProductId = 'theme_package_nocturne';
  static const String nocturneThemeEntitlementKey = 'theme:nocturne';

  static const premiumPack100 = CommerceProduct(
    id: 'astra_pack_100',
    kind: ProductKind.premiumPack,
    grantPremiumAmount: 100,
    displayNameEn: '100 Astra',
    displayNameKo: '아스트라 100개',
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
    premiumPack100,
    sakuraThemePackage,
    amethystThemePackage,
    nocturneThemePackage,
  ];

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
