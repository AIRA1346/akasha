/// Steam Inventory Minimal POC — IDs match docs/active/steam_inventory_poc/itemdefs_poc.json
library;

abstract final class SteamInventoryPocIds {
  static const int appId = 4677560;
  static const int astraUnit = 10001;
  static const int astraPack100 = 10010;
  static const int echoUnit = 10002;
  static const int echoPlaytimeGenerator = 10020;
  // `10002x5` is a generator weight, not a quantity. With one candidate the
  // published POC definition grants exactly one Echo per successful drop.
  static const int echoPlaytimeGrantAmount = 1;
  static const int echoStarterPromo = 10021;

  /// Final theme unlock item — ownership = inventory qty >= 1.
  static const int themeNocturne = 20001;

  /// Exchange bundle: consumes Astra×100, grants [themeNocturne].
  /// ExchangeItems generate target must be this def, not [themeNocturne].
  static const int themeNocturneExchange = 20010;

  static const int supportAkasha = 30001;

  /// Astra units consumed by [themeNocturneExchange] (`exchange: 10001x100`).
  static const int themeAstraCost = 100;
}
