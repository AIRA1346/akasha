import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

import 'steam_inventory_itemdefs.dart';
import 'steam_inventory_read_port.dart';
import 'steam_inventory_reward_port.dart';
import 'steam_inventory_transaction_port.dart';

/// Production adapter for Steam-backed balances, entitlements, localized
/// Astra pack prices, and guarded sandbox transactions.
///
/// Transaction completion is never trusted on its own. Every mutation ends in
/// a fresh inventory read and is confirmed only when the expected balance or
/// entitlement change is visible in that provider snapshot.
class SteamInventoryCommerceGateway
    implements CommerceGateway, CommercePlaytimeRewardGateway {
  SteamInventoryCommerceGateway({
    required SteamInventoryReadPort port,
    SteamInventoryTransactionPort? transactionPort,
    SteamInventoryRewardPort? rewardPort,
    bool transactionsEnabled = false,
    bool playtimeRewardsEnabled = false,
  }) : _port = port,
       _transactionPort = transactionPort,
       _rewardPort = rewardPort,
       _transactionsConfigured = transactionsEnabled,
       _playtimeRewardsConfigured = playtimeRewardsEnabled;

  final SteamInventoryReadPort _port;
  final SteamInventoryTransactionPort? _transactionPort;
  final SteamInventoryRewardPort? _rewardPort;
  final bool _transactionsConfigured;
  final bool _playtimeRewardsConfigured;
  CommerceAccountSnapshot _lastSnapshot = const CommerceAccountSnapshot(
    state: CommerceAuthorityState.unavailable,
    issueCode: 'steam_account_not_loaded',
  );
  List<SteamInventoryReadItem> _lastInventoryItems = const [];
  bool _mutationInFlight = false;
  bool _reconciliationRequired = false;

  bool get _transactionsAvailable =>
      _transactionsConfigured &&
      _transactionPort != null &&
      !_reconciliationRequired;

  bool get _playtimeRewardsAvailable =>
      _playtimeRewardsConfigured &&
      _rewardPort != null &&
      !_reconciliationRequired;

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
    _lastInventoryItems = List.unmodifiable(inventory.items);

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
      transactionsEnabled: _transactionsAvailable,
      playtimeRewardsEnabled: _playtimeRewardsAvailable,
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
        playtimeRewardsEnabled: false,
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
      playtimeRewardsEnabled: false,
    );
    return _lastSnapshot;
  }

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) async {
    final product = CommerceCatalog.byId(productId);
    final itemDefId = SteamInventoryItemDefs.pricedPackByProductId[productId];
    if (product == null ||
        !CommerceCatalog.isApprovedAstraPack(productId) ||
        itemDefId == null ||
        product.grantPremiumAmount == null) {
      return _rejected('steam_product_not_allowed');
    }
    final guard = _mutationGuard();
    if (guard != null) return guard;

    final before = _lastSnapshot.astraBalance!;
    _mutationInFlight = true;
    try {
      final transaction = await _transactionPort!.startPurchase(
        itemDefId: itemDefId,
      );
      return _reconcileMutation(
        transaction: transaction,
        outcomeObserved: (snapshot) =>
            (snapshot.astraBalance ?? -1) >=
            before + product.grantPremiumAmount!,
      );
    } catch (_) {
      _reconciliationRequired = true;
      return CommerceOperationResult(
        status: CommerceOperationStatus.indeterminate,
        snapshot: _withoutProviderMutations(_lastSnapshot),
        issueCode: 'steam_transaction_exception_after_start',
      );
    } finally {
      _mutationInFlight = false;
    }
  }

  @override
  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  }) async {
    final product = CommerceCatalog.byId(productId);
    final generateItemDefId =
        SteamInventoryItemDefs.exchangeByProductId[productId];
    final entitlementKey = product?.entitlementKey;
    final payment = product?.payment;
    final price = switch (payWith) {
      CurrencyKind.premium => payment?.premiumPrice,
      CurrencyKind.earned => payment?.earnedPrice,
    };
    if (product == null ||
        product.kind != ProductKind.themePackage ||
        generateItemDefId == null ||
        entitlementKey == null ||
        price == null ||
        price <= 0) {
      return _rejected('steam_product_not_allowed');
    }
    final guard = _mutationGuard();
    if (guard != null) return guard;
    if (_lastSnapshot.owns(entitlementKey)) {
      return _rejected('steam_theme_already_owned');
    }
    final balance = _lastSnapshot.balanceOf(payWith)!;
    if (balance < price) {
      return _rejected('steam_insufficient_currency');
    }

    final currencyItemDefId = switch (payWith) {
      CurrencyKind.premium => SteamInventoryItemDefs.astraUnit,
      CurrencyKind.earned => SteamInventoryItemDefs.echoUnit,
    };
    final destroyItems = _allocateDestroyItems(
      itemDefId: currencyItemDefId,
      quantity: price,
    );
    if (destroyItems == null) {
      return _rejected('steam_currency_instances_unavailable');
    }

    _mutationInFlight = true;
    try {
      final transaction = await _transactionPort!.exchangeItems(
        generateItemDefId: generateItemDefId,
        destroyItems: destroyItems,
      );
      return _reconcileMutation(
        transaction: transaction,
        outcomeObserved: (snapshot) => snapshot.owns(entitlementKey),
      );
    } catch (_) {
      _reconciliationRequired = true;
      return CommerceOperationResult(
        status: CommerceOperationStatus.indeterminate,
        snapshot: _withoutProviderMutations(_lastSnapshot),
        issueCode: 'steam_transaction_exception_after_start',
      );
    } finally {
      _mutationInFlight = false;
    }
  }

  @override
  Future<CommerceOperationResult> claimPlaytimeReward() async {
    final guard = _rewardGuard();
    if (guard != null) return guard;

    final before = _lastSnapshot.echoBalance!;
    _mutationInFlight = true;
    try {
      final reward = await _rewardPort!.triggerPlaytimeReward(
        generatorItemDefId: SteamInventoryItemDefs.echoPlaytimeReward,
        expectedItemDefId: SteamInventoryItemDefs.echoUnit,
      );
      final refreshed = await loadAccount();
      final observed =
          refreshed.state == CommerceAuthorityState.ready &&
          (refreshed.echoBalance ?? -1) >=
              before + SteamInventoryItemDefs.echoPlaytimeGrantAmount;
      if (observed) {
        _reconciliationRequired = false;
        return CommerceOperationResult(
          status: CommerceOperationStatus.confirmed,
          snapshot: refreshed,
          providerHandle: reward.providerHandle,
        );
      }
      if (reward.status == SteamInventoryRewardStatus.notEligible) {
        return CommerceOperationResult(
          status: CommerceOperationStatus.noChange,
          snapshot: refreshed,
          providerHandle: reward.providerHandle,
          issueCode: reward.issueCode,
        );
      }
      if (reward.status == SteamInventoryRewardStatus.granted ||
          reward.status == SteamInventoryRewardStatus.indeterminate) {
        _reconciliationRequired = true;
        final blocked = _withoutProviderMutations(refreshed);
        _lastSnapshot = blocked;
        return CommerceOperationResult(
          status: CommerceOperationStatus.indeterminate,
          snapshot: blocked,
          providerHandle: reward.providerHandle,
          issueCode: reward.issueCode ?? 'steam_reward_reconciliation_missing',
        );
      }
      return CommerceOperationResult(
        status: reward.status == SteamInventoryRewardStatus.rejected
            ? CommerceOperationStatus.rejected
            : CommerceOperationStatus.failed,
        snapshot: refreshed,
        providerHandle: reward.providerHandle,
        issueCode: reward.issueCode,
      );
    } catch (_) {
      _reconciliationRequired = true;
      final blocked = _withoutProviderMutations(_lastSnapshot);
      _lastSnapshot = blocked;
      return CommerceOperationResult(
        status: CommerceOperationStatus.indeterminate,
        snapshot: blocked,
        issueCode: 'steam_reward_exception_after_start',
      );
    } finally {
      _mutationInFlight = false;
    }
  }

  CommerceOperationResult? _mutationGuard() {
    if (!_transactionsConfigured || _transactionPort == null) {
      return _rejected('steam_commerce_read_only');
    }
    if (_mutationInFlight) return _rejected('steam_operation_in_progress');
    if (_reconciliationRequired) {
      return _rejected('steam_reconciliation_required');
    }
    if (!_lastSnapshot.canTransact || !_lastSnapshot.hasKnownBalances) {
      return _rejected('steam_account_not_ready');
    }
    return null;
  }

  CommerceOperationResult? _rewardGuard() {
    if (!_playtimeRewardsConfigured || _rewardPort == null) {
      return _rejected('steam_playtime_rewards_disabled');
    }
    if (_mutationInFlight) return _rejected('steam_operation_in_progress');
    if (_reconciliationRequired) {
      return _rejected('steam_reconciliation_required');
    }
    if (!_lastSnapshot.canClaimPlaytimeReward ||
        !_lastSnapshot.hasKnownBalances) {
      return _rejected('steam_account_not_ready');
    }
    return null;
  }

  CommerceOperationResult _rejected(String issueCode) =>
      CommerceOperationResult(
        status: CommerceOperationStatus.rejected,
        snapshot: _lastSnapshot,
        issueCode: issueCode,
      );

  Future<CommerceOperationResult> _reconcileMutation({
    required SteamInventoryTransactionResult transaction,
    required bool Function(CommerceAccountSnapshot snapshot) outcomeObserved,
  }) async {
    final refreshed = await loadAccount();
    final observed =
        refreshed.state == CommerceAuthorityState.ready &&
        outcomeObserved(refreshed);
    if (observed) {
      _reconciliationRequired = false;
      return CommerceOperationResult(
        status: CommerceOperationStatus.confirmed,
        snapshot: refreshed,
        providerHandle: transaction.providerHandle,
        providerOrderId: transaction.orderId,
        providerTransactionId: transaction.transactionId,
      );
    }

    if (transaction.status == SteamInventoryTransactionStatus.confirmed ||
        transaction.status == SteamInventoryTransactionStatus.indeterminate) {
      _reconciliationRequired = true;
      final blocked = _withoutProviderMutations(refreshed);
      _lastSnapshot = blocked;
      return CommerceOperationResult(
        status: CommerceOperationStatus.indeterminate,
        snapshot: blocked,
        providerHandle: transaction.providerHandle,
        providerOrderId: transaction.orderId,
        providerTransactionId: transaction.transactionId,
        issueCode:
            transaction.issueCode ?? 'steam_reconciliation_outcome_missing',
      );
    }

    return CommerceOperationResult(
      status: _commerceStatus(transaction.status),
      snapshot: refreshed,
      providerHandle: transaction.providerHandle,
      providerOrderId: transaction.orderId,
      providerTransactionId: transaction.transactionId,
      issueCode: transaction.issueCode,
    );
  }

  List<SteamInventoryDestroyItem>? _allocateDestroyItems({
    required int itemDefId,
    required int quantity,
  }) {
    var remaining = quantity;
    final allocated = <SteamInventoryDestroyItem>[];
    for (final item in _lastInventoryItems) {
      if (remaining <= 0) break;
      if (item.itemDefId != itemDefId ||
          item.instanceId.isEmpty ||
          item.quantity <= 0) {
        continue;
      }
      final take = item.quantity < remaining ? item.quantity : remaining;
      allocated.add(
        SteamInventoryDestroyItem(instanceId: item.instanceId, quantity: take),
      );
      remaining -= take;
    }
    return remaining == 0 ? List.unmodifiable(allocated) : null;
  }

  CommerceAccountSnapshot _withoutProviderMutations(
    CommerceAccountSnapshot snapshot,
  ) => CommerceAccountSnapshot(
    state: snapshot.state,
    astraBalance: snapshot.astraBalance,
    echoBalance: snapshot.echoBalance,
    entitlementKeys: snapshot.entitlementKeys,
    localizedPrices: snapshot.localizedPrices,
    transactionsEnabled: false,
    playtimeRewardsEnabled: false,
    observedAt: snapshot.observedAt,
    issueCode: snapshot.issueCode,
    priceIssueCode: snapshot.priceIssueCode,
  );

  static CommerceOperationStatus _commerceStatus(
    SteamInventoryTransactionStatus status,
  ) => switch (status) {
    SteamInventoryTransactionStatus.confirmed =>
      CommerceOperationStatus.confirmed,
    SteamInventoryTransactionStatus.cancelled =>
      CommerceOperationStatus.cancelled,
    SteamInventoryTransactionStatus.rejected =>
      CommerceOperationStatus.rejected,
    SteamInventoryTransactionStatus.failed => CommerceOperationStatus.failed,
    SteamInventoryTransactionStatus.pending ||
    SteamInventoryTransactionStatus.indeterminate =>
      CommerceOperationStatus.indeterminate,
  };
}
