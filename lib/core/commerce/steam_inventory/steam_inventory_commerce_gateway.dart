import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

import '../commerce_support_gateway.dart';
import 'steam_inventory_itemdefs.dart';
import 'steam_inventory_read_port.dart';
import 'steam_inventory_reward_port.dart';
import 'steam_inventory_transaction_port.dart';
import 'steam_runtime_environment.dart';

/// Production adapter for Steam-backed balances, entitlements, localized
/// Astra pack prices, and guarded sandbox transactions.
///
/// Transaction completion is never trusted on its own. Every mutation ends in
/// a fresh inventory read and is confirmed only when the expected balance or
/// entitlement change is visible in that provider snapshot.
class SteamInventoryCommerceGateway
    implements
        CommerceGateway,
        CommercePlaytimeRewardGateway,
        CommerceSupportGateway {
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
  SteamInventoryDiagnostic? _lastDiagnostic;
  SteamInventoryPricesResult? _lastPricesResult;
  SteamInventoryTransactionResult? _lastTransaction;
  String? _lastOperation;
  String? _lastProductId;
  int? _lastItemDefId;
  bool _mutationInFlight = false;
  bool _reconciliationRequired = false;

  bool get _transactionsConfiguredAvailable =>
      _transactionsConfigured &&
      _transactionPort != null &&
      !_reconciliationRequired;

  bool get _playtimeRewardsConfiguredAvailable =>
      _playtimeRewardsConfigured &&
      _rewardPort != null &&
      !_reconciliationRequired;

  @override
  Future<CommerceAccountSnapshot> loadAccount() async {
    final diagnostic = await _port.diagnostic();
    _lastDiagnostic = diagnostic;
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
    _lastPricesResult = pricesResult;
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
    final hasEveryApprovedPrice = SteamInventoryItemDefs
        .pricedPackByProductId
        .keys
        .every(localizedPrices.containsKey);
    if (!hasEveryApprovedPrice) {
      priceIssueCode ??= 'steam_purchase_prices_incomplete';
    }

    final transactionIssueCode = _transactionsConfigured
        ? diagnostic.transactionCapabilityIssueCode ??
              (hasEveryApprovedPrice
                  ? null
                  : 'steam_purchase_prices_incomplete')
        : null;
    final transactionsEnabled =
        _transactionsConfiguredAvailable && transactionIssueCode == null;
    final playtimeRewardsEnabled =
        _playtimeRewardsConfiguredAvailable &&
        diagnostic.inventoryMutationIssueCode == null;

    _lastSnapshot = CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: totals[SteamInventoryItemDefs.astraUnit] ?? 0,
      echoBalance: totals[SteamInventoryItemDefs.echoUnit] ?? 0,
      entitlementKeys: Set.unmodifiable(entitlements),
      localizedPrices: Map.unmodifiable(localizedPrices),
      transactionsEnabled: transactionsEnabled,
      playtimeRewardsEnabled: playtimeRewardsEnabled,
      observedAt: inventory.observedAt ?? DateTime.now().toUtc(),
      issueCode: transactionIssueCode,
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
    _rememberOperation(
      operation: 'purchase',
      productId: productId,
      itemDefId: itemDefId,
    );
    _mutationInFlight = true;
    try {
      final transaction = await _transactionPort!.startPurchase(
        itemDefId: itemDefId,
      );
      _lastTransaction = transaction;
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
    _rememberOperation(
      operation: 'exchange',
      productId: productId,
      itemDefId: generateItemDefId,
    );
    try {
      final transaction = await _transactionPort!.exchangeItems(
        generateItemDefId: generateItemDefId,
        destroyItems: destroyItems,
      );
      _lastTransaction = transaction;
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

  void _rememberOperation({
    required String operation,
    required String productId,
    required int itemDefId,
  }) {
    _lastOperation = operation;
    _lastProductId = productId;
    _lastItemDefId = itemDefId;
    _lastTransaction = null;
  }

  @override
  String buildSupportReport() {
    final diagnostic = _lastDiagnostic;
    final prices = _lastPricesResult;
    final transaction = _lastTransaction;
    final approvedPriceCount =
        prices?.prices
            .where(
              (row) => SteamInventoryItemDefs.approvedPurchaseItemDefs.contains(
                row.itemDefId,
              ),
            )
            .length ??
        0;
    final lines = <String>[
      'AKASHA Steam Commerce Diagnostics',
      'generatedAt=${DateTime.now().toUtc().toIso8601String()}',
      'appId=${diagnostic?.appId ?? SteamInventoryItemDefs.appId}',
      'readStatus=${diagnostic?.status.name ?? 'not_loaded'}',
      'initialized=${diagnostic?.initialized ?? false}',
      'loggedOn=${diagnostic?.loggedOn ?? false}',
      'subscribedApp=${diagnostic?.subscribedApp ?? false}',
      'overlayEnabled=${diagnostic?.overlayEnabled ?? false}',
      'overlayActive=${diagnostic?.overlayActive ?? false}',
      'processUptimeMs=${diagnostic?.processUptimeMs ?? -1}',
      'overlayFirstSampleEnabled=${diagnostic?.overlayFirstSampleEnabled ?? false}',
      'overlayFirstSampleElapsedMs=${diagnostic?.overlayFirstSampleElapsedMs ?? -1}',
      'overlayFirstTrueElapsedMs=${diagnostic?.overlayFirstTrueElapsedMs ?? -1}',
      'overlayEnabledSampleCount=${diagnostic?.overlayEnabledSampleCount ?? 0}',
      'overlayEnabledTransitionCount=${diagnostic?.overlayEnabledTransitionCount ?? 0}',
      'overlayActivatedCallbackCount=${diagnostic?.overlayActivatedCallbackCount ?? 0}',
      'overlayDeactivatedCallbackCount=${diagnostic?.overlayDeactivatedCallbackCount ?? 0}',
      'overlayLastCallbackElapsedMs=${diagnostic?.overlayLastCallbackElapsedMs ?? -1}',
      'initializationAttempted=${diagnostic?.initializationAttempted ?? false}',
      'restartRequested=${diagnostic?.restartRequested ?? false}',
      'buildMode=${diagnostic?.buildMode ?? 'unknown'}',
      'executionEnvironment=${diagnostic?.executionEnvironment.name ?? 'unknown'}',
      'executablePath=${sanitizeSteamRuntimePath(diagnostic?.executablePath)}',
      'currentWorkingDirectory=${sanitizeSteamRuntimePath(diagnostic?.currentWorkingDirectory)}',
      'steamTimerTickCount=${diagnostic?.steamTimerTickCount ?? 0}',
      'overlayNeedsPresentTrueCount=${diagnostic?.overlayNeedsPresentTrueCount ?? 0}',
      'overlayForceRedrawCount=${diagnostic?.overlayForceRedrawCount ?? 0}',
      'accountState=${_lastSnapshot.state.name}',
      'inventoryAuthority=${_lastSnapshot.state.name}',
      'accountIssue=${_lastSnapshot.issueCode ?? 'none'}',
      'priceStatus=${prices?.status.name ?? 'not_loaded'}',
      'priceCurrency=${prices?.currencyCode ?? 'unknown'}',
      'approvedPriceCount=$approvedPriceCount/${SteamInventoryItemDefs.approvedPurchaseItemDefs.length}',
      'priceIssue=${_lastSnapshot.priceIssueCode ?? 'none'}',
      'transactionsConfigured=$_transactionsConfigured',
      'transactionsEnabled=${_lastSnapshot.transactionsEnabled}',
      'playtimeRewardsConfigured=$_playtimeRewardsConfigured',
      'playtimeRewardsEnabled=${_lastSnapshot.playtimeRewardsEnabled}',
      'reconciliationRequired=$_reconciliationRequired',
      'lastOperation=${_lastOperation ?? 'none'}',
      'lastProductId=${_lastProductId ?? 'none'}',
      'lastItemDefId=${_lastItemDefId ?? 0}',
      'transactionStatus=${transaction?.status.name ?? 'none'}',
      'transactionIssue=${transaction?.issueCode ?? 'none'}',
      'transactionPhase=${transaction?.phase ?? 'none'}',
      'steamResultCode=${transaction?.providerResultCode ?? 0}',
      'steamResultName=${transaction?.providerResultName ?? 'none'}',
      'apiCallHandle=${transaction?.apiCallHandle ?? 'none'}',
      'providerHandle=${transaction?.providerHandle ?? 'none'}',
      'orderId=${transaction?.orderId ?? 'none'}',
      'transactionId=${transaction?.transactionId ?? 'none'}',
      'detail=${_sanitizeSupportValue(transaction?.detail)}',
    ];
    return lines.join('\n');
  }

  static String _sanitizeSupportValue(String? value) {
    final compact = (value ?? 'none')
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .trim();
    if (compact.isEmpty) return 'none';
    return compact.length <= 240 ? compact : compact.substring(0, 240);
  }

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
