import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

import 'steam_inventory_itemdefs.dart';
import 'steam_inventory_read_port.dart';

/// Read-only production adapter for Steam-backed balances, entitlements, and
/// localized Astra pack prices.
///
/// Mutating methods deliberately reject until transaction reconciliation has
/// passed the Steam sandbox gate.
class SteamInventoryCommerceGateway implements CommerceGateway {
  SteamInventoryCommerceGateway({required SteamInventoryReadPort port})
    : _port = port;

  final SteamInventoryReadPort _port;
  CommerceAccountSnapshot _lastSnapshot = const CommerceAccountSnapshot(
    state: CommerceAuthorityState.unavailable,
    issueCode: 'steam_account_not_loaded',
  );

  @override
  Future<CommerceAccountSnapshot> loadAccount() async {
    final diagnostic = await _port.diagnostic();
    if (!diagnostic.isAvailable) {
      return _rememberUnavailable(diagnostic.issueCode ?? 'steam_unavailable');
    }
    if (!diagnostic.isOnline) {
      return _rememberUnavailable(diagnostic.issueCode ?? 'steam_offline');
    }
    if (diagnostic.appId != SteamInventoryItemDefs.appId) {
      return _rememberUnavailable('steam_app_id_mismatch');
    }

    final inventory = await _port.getAllItems();
    if (inventory.status != SteamInventoryReadStatus.success) {
      return _rememberUnavailable(
        inventory.issueCode ?? 'steam_inventory_read_failed',
      );
    }

    final totals = <int, int>{};
    for (final item in inventory.items) {
      if (SteamInventoryItemDefs.retiredPocItemDefs.contains(item.itemDefId)) {
        continue;
      }
      totals.update(
        item.itemDefId,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    final entitlements = <String>{};
    for (final entry
        in SteamInventoryItemDefs.entitlementKeyByItemDef.entries) {
      if ((totals[entry.key] ?? 0) >= 1) entitlements.add(entry.value);
    }

    final pricesResult = await _port.requestPrices();
    final localizedPrices = <String, CommerceLocalizedPrice>{};
    String? priceIssueCode;
    final currencyCode = pricesResult.currencyCode;
    if (pricesResult.status == SteamInventoryReadStatus.success &&
        currencyCode != null) {
      for (final row in pricesResult.prices) {
        final productId =
            SteamInventoryItemDefs.productIdByPricedPack[row.itemDefId];
        if (productId == null) continue;
        localizedPrices[productId] = CommerceLocalizedPrice(
          productId: productId,
          currencyCode: currencyCode,
          currentAmount: row.currentAmount,
          baseAmount: row.baseAmount,
        );
      }
    } else {
      priceIssueCode =
          pricesResult.issueCode ?? 'steam_localized_prices_unavailable';
    }

    _lastSnapshot = CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: totals[SteamInventoryItemDefs.astraUnit] ?? 0,
      echoBalance: totals[SteamInventoryItemDefs.echoUnit] ?? 0,
      entitlementKeys: Set.unmodifiable(entitlements),
      localizedPrices: Map.unmodifiable(localizedPrices),
      transactionsEnabled: false,
      observedAt: inventory.observedAt ?? DateTime.now().toUtc(),
      priceIssueCode: priceIssueCode,
    );
    return _lastSnapshot;
  }

  CommerceAccountSnapshot _rememberUnavailable(String issueCode) {
    final previous = _lastSnapshot;
    if ((previous.state == CommerceAuthorityState.ready ||
            previous.state == CommerceAuthorityState.offlineCache) &&
        previous.hasKnownBalances) {
      _lastSnapshot = CommerceAccountSnapshot(
        state: CommerceAuthorityState.offlineCache,
        astraBalance: previous.astraBalance,
        echoBalance: previous.echoBalance,
        entitlementKeys: previous.entitlementKeys,
        localizedPrices: previous.localizedPrices,
        transactionsEnabled: false,
        observedAt: previous.observedAt,
        issueCode: issueCode,
        priceIssueCode: previous.priceIssueCode,
      );
      return _lastSnapshot;
    }
    _lastSnapshot = CommerceAccountSnapshot(
      state: CommerceAuthorityState.unavailable,
      issueCode: issueCode,
      transactionsEnabled: false,
    );
    return _lastSnapshot;
  }

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) async => CommerceOperationResult(
    status: CommerceOperationStatus.rejected,
    snapshot: _lastSnapshot,
    issueCode: 'steam_commerce_read_only',
  );

  @override
  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  }) async => CommerceOperationResult(
    status: CommerceOperationStatus.rejected,
    snapshot: _lastSnapshot,
    issueCode: 'steam_commerce_read_only',
  );
}
