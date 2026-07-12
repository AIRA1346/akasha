/// Snapshot of one Steam inventory item instance (POC).
class SteamInventoryItem {
  const SteamInventoryItem({
    required this.instanceId,
    required this.itemDefId,
    required this.quantity,
    this.flags = 0,
  });

  final String instanceId;
  final int itemDefId;
  final int quantity;
  final int flags;
}

enum SteamInventoryOpKind { load, prices, purchase, exchange, promo, playtimeDrop }

enum SteamInventoryOpStatus { idle, pending, ok, failed }

/// Non-authoritative UI/operation state — never a currency balance store.
class SteamInventoryOperation {
  const SteamInventoryOperation({
    required this.kind,
    required this.status,
    this.detail,
    this.resultHandle,
  });

  final SteamInventoryOpKind kind;
  final SteamInventoryOpStatus status;
  final String? detail;
  final String? resultHandle;
}

class SteamInventorySnapshot {
  const SteamInventorySnapshot({
    required this.items,
    required this.fetchedAt,
    this.loadFailed = false,
    this.loadError,
  });

  final List<SteamInventoryItem> items;
  final DateTime fetchedAt;
  final bool loadFailed;
  final String? loadError;

  static SteamInventorySnapshot emptyFailed(String error) => SteamInventorySnapshot(
        items: const [],
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        loadFailed: true,
        loadError: error,
      );

  int quantityOf(int itemDefId) {
    var total = 0;
    for (final item in items) {
      if (item.itemDefId == itemDefId) total += item.quantity;
    }
    return total;
  }

  bool ownsTheme(int themeDefId) => quantityOf(themeDefId) >= 1;

  List<SteamInventoryItem> instancesOf(int itemDefId) =>
      items.where((i) => i.itemDefId == itemDefId).toList(growable: false);
}

class SteamItemPrice {
  const SteamItemPrice({required this.itemDefId, required this.priceMicro});
  final int itemDefId;
  /// Steam price in micro-units of local currency when available.
  final int priceMicro;
}
