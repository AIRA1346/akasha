enum SteamInventoryTransactionStatus {
  pending,
  confirmed,
  cancelled,
  rejected,
  failed,
  indeterminate,
}

class SteamInventoryTransactionResult {
  const SteamInventoryTransactionResult({
    required this.status,
    this.providerHandle,
    this.orderId,
    this.transactionId,
    this.phase,
    this.apiCallHandle,
    this.providerResultCode,
    this.providerResultName,
    this.detail,
    this.issueCode,
  });

  final SteamInventoryTransactionStatus status;
  final String? providerHandle;
  final String? orderId;
  final String? transactionId;
  final String? phase;
  final String? apiCallHandle;
  final int? providerResultCode;
  final String? providerResultName;
  final String? detail;
  final String? issueCode;

  bool get isTerminal => status != SteamInventoryTransactionStatus.pending;
}

class SteamInventoryDestroyItem {
  const SteamInventoryDestroyItem({
    required this.instanceId,
    required this.quantity,
  });

  final String instanceId;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SteamInventoryDestroyItem &&
          instanceId == other.instanceId &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(instanceId, quantity);
}

/// Mutating Steam Inventory capability kept separate from the read port.
///
/// Implementations return only after a terminal native result or a timeout.
/// A `confirmed` result still is not authority for balances or entitlements;
/// callers must reconcile it with a fresh `GetAllItems` snapshot.
abstract interface class SteamInventoryTransactionPort {
  Future<SteamInventoryTransactionResult> startPurchase({
    required int itemDefId,
    int quantity = 1,
  });

  Future<SteamInventoryTransactionResult> exchangeItems({
    required int generateItemDefId,
    required List<SteamInventoryDestroyItem> destroyItems,
  });
}
