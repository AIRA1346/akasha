import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

/// Production Steam Inventory ItemDef registry.
///
/// Domain product ids never cross the native bridge as ItemDef ids. This is
/// the only adapter-level mapping approved to translate between the two.
abstract final class SteamInventoryItemDefs {
  static const int appId = 4677560;

  static const int astraUnit = 40001;
  static const int echoUnit = 40002;

  static const int astraPack500 = 40110;
  static const int astraPack1000 = 40111;
  static const int astraPack2500 = 40112;

  static const int echoPack10 = 40210;
  static const int echoPlaytimeReward = 40220;
  static const int echoPlaytimeGrantAmount = 10;

  static const int sakuraThemeEntitlement = 41001;
  static const int amethystThemeEntitlement = 41002;
  static const int nocturneThemeEntitlement = 41003;

  static const int sakuraThemeExchange = 41101;
  static const int amethystThemeExchange = 41102;
  static const int nocturneThemeExchange = 41103;

  static const Map<String, int> pricedPackByProductId = {
    CommerceCatalog.astraPack500ProductId: astraPack500,
    CommerceCatalog.astraPack1000ProductId: astraPack1000,
    CommerceCatalog.astraPack2500ProductId: astraPack2500,
  };

  static const Map<int, String> productIdByPricedPack = {
    astraPack500: CommerceCatalog.astraPack500ProductId,
    astraPack1000: CommerceCatalog.astraPack1000ProductId,
    astraPack2500: CommerceCatalog.astraPack2500ProductId,
  };

  static const Map<int, String> entitlementKeyByItemDef = {
    sakuraThemeEntitlement: CommerceCatalog.sakuraThemeEntitlementKey,
    amethystThemeEntitlement: CommerceCatalog.amethystThemeEntitlementKey,
    nocturneThemeEntitlement: CommerceCatalog.nocturneThemeEntitlementKey,
  };

  static const Map<String, int> exchangeByProductId = {
    CommerceCatalog.sakuraThemeProductId: sakuraThemeExchange,
    CommerceCatalog.amethystThemeProductId: amethystThemeExchange,
    CommerceCatalog.nocturneThemeProductId: nocturneThemeExchange,
  };

  /// Historical sandbox definitions are permanently ignored by production
  /// reads, even if a developer account still owns them.
  static const Set<int> retiredPocItemDefs = {
    10001,
    10002,
    10010,
    10020,
    10021,
    20001,
    20010,
    30001,
  };
}
