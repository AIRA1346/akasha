import 'steam_inventory_models.dart';

/// Port to Steam Inventory (native) or in-process fake (tests / offline harness).
///
/// Implementations must **not** persist balances to SharedPreferences or Vault.
abstract class SteamInventoryClient {
  Future<bool> get isAvailable;

  /// Online enough for purchase/exchange. Fake may toggle this.
  Future<bool> get isOnline;

  Future<void> initialize();

  Future<SteamInventorySnapshot> getAllItems();

  Future<List<SteamItemPrice>> requestPrices();

  /// Returns a result handle / correlation id; completion via [poll] or callback path.
  Future<String> startPurchase({
    required List<int> itemDefIds,
    required List<int> quantities,
  });

  Future<String> exchangeItems({
    required int generateItemDefId,
    required int generateQuantity,
    required List<String> destroyInstanceIds,
    required List<int> destroyQuantities,
  });

  /// POC-only: consume one stack quantity from a real item instance ID.
  Future<String> consumeItem({
    required String instanceId,
    required int quantity,
  });

  Future<String> addPromoItem(int itemDefId);

  Future<String> triggerItemDrop(int playtimeGeneratorDefId);

  /// Pump callbacks / resolve pending handles. Returns completed ops.
  Future<List<SteamInventoryOperation>> poll();

  Future<void> destroyResult(String resultHandle);

  Future<void> dispose();
}
