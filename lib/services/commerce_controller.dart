import 'package:flutter/widgets.dart';

import '../core/commerce/commerce.dart';

/// App-root read state for the external commerce authority.
///
/// The controller never persists balances or entitlements. It only keeps the
/// latest provider-derived snapshot in memory so Store, Inventory, and theme
/// access observe one source of truth.
class CommerceController extends ChangeNotifier {
  CommerceController({required CommerceGateway gateway, required bool enabled})
    : _gateway = gateway,
      _enabled = enabled,
      _snapshot = enabled
          ? const CommerceAccountSnapshot(state: CommerceAuthorityState.loading)
          : const CommerceAccountSnapshot.disabled();

  factory CommerceController.disabled() => CommerceController(
    gateway: const UnavailableCommerceGateway(),
    enabled: false,
  );

  final CommerceGateway _gateway;
  final bool _enabled;
  CommerceAccountSnapshot _snapshot;
  Future<void>? _activeRefresh;
  Future<CommerceOperationResult>? _activeOperation;
  CommerceOperationResult? _lastOperation;
  String? _activeProductId;
  CurrencyKind? _activeCurrency;
  bool _disposed = false;

  bool get enabled => _enabled;
  CommerceAccountSnapshot get snapshot => _snapshot;
  bool get operationInFlight => _activeOperation != null;
  CommerceOperationResult? get lastOperation => _lastOperation;
  String? get activeProductId => _activeProductId;
  CurrencyKind? get activeCurrency => _activeCurrency;

  /// Refreshes once even when several surfaces request data concurrently.
  Future<void> refresh() {
    if (_disposed || !_enabled) return Future<void>.value();
    if (_activeOperation != null) return Future<void>.value();
    final active = _activeRefresh;
    if (active != null) return active;

    final refresh = _loadAccount();
    _activeRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_activeRefresh, refresh)) _activeRefresh = null;
    });
  }

  Future<CommerceOperationResult> purchaseAstraPack(String productId) =>
      _runOperation(
        productId: productId,
        operation: () => _gateway.purchaseAstraPack(productId: productId),
      );

  Future<CommerceOperationResult> exchangeTheme({
    required String productId,
    required CurrencyKind payWith,
  }) => _runOperation(
    productId: productId,
    currency: payWith,
    operation: () =>
        _gateway.exchangeProduct(productId: productId, payWith: payWith),
  );

  Future<CommerceOperationResult> _runOperation({
    required String productId,
    required Future<CommerceOperationResult> Function() operation,
    CurrencyKind? currency,
  }) {
    if (_disposed || !_enabled) {
      return Future.value(
        CommerceOperationResult(
          status: CommerceOperationStatus.rejected,
          snapshot: _snapshot,
          issueCode: 'commerce_disabled',
        ),
      );
    }
    if (_activeOperation != null) {
      return Future.value(
        CommerceOperationResult(
          status: CommerceOperationStatus.rejected,
          snapshot: _snapshot,
          issueCode: 'commerce_operation_in_progress',
        ),
      );
    }
    if (!_snapshot.canTransact) {
      return Future.value(
        CommerceOperationResult(
          status: CommerceOperationStatus.rejected,
          snapshot: _snapshot,
          issueCode: 'commerce_account_not_ready',
        ),
      );
    }

    _activeProductId = productId;
    _activeCurrency = currency;
    final future = _executeOperation(operation);
    _activeOperation = future;
    notifyListeners();
    return future.whenComplete(() {
      if (identical(_activeOperation, future)) {
        _activeOperation = null;
        _activeProductId = null;
        _activeCurrency = null;
        if (!_disposed) notifyListeners();
      }
    });
  }

  Future<CommerceOperationResult> _executeOperation(
    Future<CommerceOperationResult> Function() operation,
  ) async {
    CommerceOperationResult result;
    try {
      result = await operation();
    } catch (_) {
      result = CommerceOperationResult(
        status: CommerceOperationStatus.indeterminate,
        snapshot: _snapshot,
        issueCode: 'commerce_operation_exception',
      );
    }
    if (!_disposed) {
      _lastOperation = result;
      _setSnapshot(result.snapshot);
    }
    return result;
  }

  Future<void> _loadAccount() async {
    final previous = _snapshot;
    _setSnapshot(
      CommerceAccountSnapshot(
        state: CommerceAuthorityState.loading,
        astraBalance: previous.astraBalance,
        echoBalance: previous.echoBalance,
        entitlementKeys: previous.entitlementKeys,
        localizedPrices: previous.localizedPrices,
        transactionsEnabled: previous.transactionsEnabled,
        observedAt: previous.observedAt,
        priceIssueCode: previous.priceIssueCode,
      ),
    );

    try {
      _setSnapshot(await _gateway.loadAccount());
    } catch (_) {
      final hasCache = previous.hasKnownBalances;
      _setSnapshot(
        CommerceAccountSnapshot(
          state: hasCache
              ? CommerceAuthorityState.offlineCache
              : CommerceAuthorityState.unavailable,
          astraBalance: previous.astraBalance,
          echoBalance: previous.echoBalance,
          entitlementKeys: previous.entitlementKeys,
          localizedPrices: previous.localizedPrices,
          transactionsEnabled: false,
          observedAt: previous.observedAt,
          issueCode: 'commerce_gateway_error',
          priceIssueCode: previous.priceIssueCode,
        ),
      );
    }
  }

  void _setSnapshot(CommerceAccountSnapshot next) {
    if (_disposed) return;
    _snapshot = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Safe placeholder until the production Steam Inventory adapter is wired.
///
/// Enabling the feature flag without replacing this gateway exposes an
/// unavailable state; it can never create a fake balance or entitlement.
class UnavailableCommerceGateway implements CommerceGateway {
  const UnavailableCommerceGateway();

  static const _snapshot = CommerceAccountSnapshot(
    state: CommerceAuthorityState.unavailable,
    issueCode: 'commerce_gateway_unavailable',
  );

  @override
  Future<CommerceAccountSnapshot> loadAccount() async => _snapshot;

  @override
  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  }) async => const CommerceOperationResult(
    status: CommerceOperationStatus.rejected,
    snapshot: _snapshot,
    issueCode: 'commerce_gateway_unavailable',
  );

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) async => const CommerceOperationResult(
    status: CommerceOperationStatus.rejected,
    snapshot: _snapshot,
    issueCode: 'commerce_gateway_unavailable',
  );
}

class CommerceScope extends InheritedNotifier<CommerceController> {
  const CommerceScope({
    super.key,
    required CommerceController controller,
    required super.child,
  }) : super(notifier: controller);

  static CommerceController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'CommerceScope is missing above this context.');
    return controller!;
  }

  static CommerceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommerceScope>()?.notifier;
}
