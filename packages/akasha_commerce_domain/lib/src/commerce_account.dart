import 'commerce_catalog.dart';
import 'currency_kind.dart';

/// Read state for the external commerce authority.
enum CommerceAuthorityState {
  disabled,
  loading,
  ready,
  offlineCache,
  unavailable,
}

/// Provider-derived wallet and entitlement view.
///
/// Balances remain nullable until the authority has returned a real snapshot;
/// UI must not turn an unknown balance into a fake zero.
class CommerceAccountSnapshot {
  const CommerceAccountSnapshot({
    required this.state,
    this.astraBalance,
    this.echoBalance,
    this.entitlementKeys = const {},
    this.localizedPrices = const {},
    this.transactionsEnabled = false,
    this.observedAt,
    this.issueCode,
    this.priceIssueCode,
  });

  const CommerceAccountSnapshot.disabled()
    : state = CommerceAuthorityState.disabled,
      astraBalance = null,
      echoBalance = null,
      entitlementKeys = const {},
      localizedPrices = const {},
      transactionsEnabled = false,
      observedAt = null,
      issueCode = null,
      priceIssueCode = null;

  final CommerceAuthorityState state;
  final int? astraBalance;
  final int? echoBalance;
  final Set<String> entitlementKeys;
  final Map<String, CommerceLocalizedPrice> localizedPrices;
  final bool transactionsEnabled;
  final DateTime? observedAt;
  final String? issueCode;
  final String? priceIssueCode;

  bool get hasKnownBalances => astraBalance != null && echoBalance != null;
  bool get canTransact =>
      state == CommerceAuthorityState.ready && transactionsEnabled;
  bool owns(String entitlementKey) => entitlementKeys.contains(entitlementKey);
  CommerceLocalizedPrice? priceOf(String productId) =>
      localizedPrices[productId];

  int? balanceOf(CurrencyKind currency) => switch (currency) {
    CurrencyKind.premium => astraBalance,
    CurrencyKind.earned => echoBalance,
  };
}

/// Opaque price values returned by the commerce provider for one approved
/// product. Formatting remains provider/platform-specific; the client must not
/// infer a checkout price from the economy reference in [CommerceCatalog].
class CommerceLocalizedPrice {
  const CommerceLocalizedPrice({
    required this.productId,
    required this.currencyCode,
    required this.currentAmount,
    this.baseAmount,
  });

  final String productId;
  final String currencyCode;
  final int currentAmount;
  final int? baseAmount;
}

enum CommerceOperationStatus {
  confirmed,
  cancelled,
  rejected,
  failed,
  indeterminate,
}

/// Every mutating provider operation ends by refreshing inventory. An
/// indeterminate result must be reconciled before retrying.
class CommerceOperationResult {
  const CommerceOperationResult({
    required this.status,
    required this.snapshot,
    this.providerHandle,
    this.providerOrderId,
    this.providerTransactionId,
    this.issueCode,
  });

  final CommerceOperationStatus status;
  final CommerceAccountSnapshot snapshot;
  final String? providerHandle;
  final String? providerOrderId;
  final String? providerTransactionId;
  final String? issueCode;
}

/// Provider-neutral boundary for the production Steam Inventory adapter and
/// future trusted services. Vault and SharedPreferences must never implement
/// this authority.
abstract interface class CommerceGateway {
  Future<CommerceAccountSnapshot> loadAccount();

  /// Accepts only domain product ids approved by
  /// [CommerceCatalog.isApprovedAstraPack]. A provider adapter must never pass
  /// through a raw ItemDef supplied by UI or external input.
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  });

  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  });
}
