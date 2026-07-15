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
  bool _disposed = false;

  bool get enabled => _enabled;
  CommerceAccountSnapshot get snapshot => _snapshot;

  /// Refreshes once even when several surfaces request data concurrently.
  Future<void> refresh() {
    if (_disposed || !_enabled) return Future<void>.value();
    final active = _activeRefresh;
    if (active != null) return active;

    final refresh = _loadAccount();
    _activeRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_activeRefresh, refresh)) _activeRefresh = null;
    });
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
