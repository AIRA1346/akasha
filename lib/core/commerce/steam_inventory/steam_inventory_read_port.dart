enum SteamInventoryReadStatus { success, unavailable, offline, failed }

class SteamInventoryDiagnostic {
  const SteamInventoryDiagnostic({
    required this.status,
    this.appId,
    this.initialized = false,
    this.loggedOn = false,
    this.subscribedApp = false,
    this.overlayEnabled = false,
    this.overlayActive = false,
    this.restartRequested = false,
    this.buildMode,
    this.steamTimerTickCount,
    this.overlayNeedsPresentTrueCount,
    this.overlayForceRedrawCount,
    this.issueCode,
  });

  final SteamInventoryReadStatus status;
  final int? appId;
  final bool initialized;
  final bool loggedOn;
  final bool subscribedApp;
  final bool overlayEnabled;
  final bool overlayActive;
  final bool restartRequested;
  final String? buildMode;
  final int? steamTimerTickCount;
  final int? overlayNeedsPresentTrueCount;
  final int? overlayForceRedrawCount;
  final String? issueCode;

  bool get isAvailable => status != SteamInventoryReadStatus.unavailable;
  bool get isOnline => status == SteamInventoryReadStatus.success;

  String? get transactionCapabilityIssueCode {
    if (!initialized) return 'steam_not_initialized';
    if (!loggedOn) return 'steam_offline';
    if (!subscribedApp) return 'steam_app_subscription_missing';
    if (!overlayEnabled) return 'steam_overlay_unavailable';
    return null;
  }

  String? get inventoryMutationIssueCode {
    if (!initialized) return 'steam_not_initialized';
    if (!loggedOn) return 'steam_offline';
    if (!subscribedApp) return 'steam_app_subscription_missing';
    return null;
  }
}

class SteamInventoryReadItem {
  const SteamInventoryReadItem({
    required this.instanceId,
    required this.itemDefId,
    required this.quantity,
  });

  final String instanceId;
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
