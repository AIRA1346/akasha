enum SteamInventoryReadStatus { success, unavailable, offline, failed }

class SteamInventoryDiagnostic {
  const SteamInventoryDiagnostic({
    required this.status,
    this.appId,
    this.issueCode,
  });

  final SteamInventoryReadStatus status;
  final int? appId;
  final String? issueCode;

  bool get isAvailable => status != SteamInventoryReadStatus.unavailable;
  bool get isOnline => status == SteamInventoryReadStatus.success;
}

class SteamInventoryReadItem {
  const SteamInventoryReadItem({
    required this.itemDefId,
    required this.quantity,
  });

  final int itemDefId;
  final int quantity;
}

class SteamInventoryItemsResult {
  const SteamInventoryItemsResult({
    required this.status,
    this.items = const [],
    this.observedAt,
    this.issueCode,
  });

  final SteamInventoryReadStatus status;
  final List<SteamInventoryReadItem> items;
  final DateTime? observedAt;
  final String? issueCode;
}

class SteamInventoryPriceRow {
  const SteamInventoryPriceRow({
    required this.itemDefId,
    required this.currentAmount,
    this.baseAmount,
  });

  final int itemDefId;
  final int currentAmount;
  final int? baseAmount;
}

class SteamInventoryPricesResult {
  const SteamInventoryPricesResult({
    required this.status,
    this.currencyCode,
    this.prices = const [],
    this.issueCode,
  });

  final SteamInventoryReadStatus status;
  final String? currencyCode;
  final List<SteamInventoryPriceRow> prices;
  final String? issueCode;
}

/// Read-only Steam bridge used before purchase/exchange activation.
abstract interface class SteamInventoryReadPort {
  Future<SteamInventoryDiagnostic> diagnostic();
  Future<SteamInventoryItemsResult> getAllItems();
  Future<SteamInventoryPricesResult> requestPrices();
}
