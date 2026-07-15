import 'dart:async';

import 'package:akasha/core/commerce/commerce.dart';
import 'package:akasha/services/commerce_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled controller never calls the external authority', () async {
    final gateway = _TestCommerceGateway();
    final controller = CommerceController(gateway: gateway, enabled: false);
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(gateway.loadCalls, 0);
    expect(controller.snapshot.state, CommerceAuthorityState.disabled);
    expect(controller.snapshot.astraBalance, isNull);
    expect(controller.snapshot.echoBalance, isNull);
  });

  test('refresh exposes one provider snapshot and coalesces callers', () async {
    final completion = Completer<CommerceAccountSnapshot>();
    final gateway = _TestCommerceGateway(loadResult: completion.future);
    final controller = CommerceController(gateway: gateway, enabled: true);
    addTearDown(controller.dispose);

    final first = controller.refresh();
    final second = controller.refresh();
    expect(gateway.loadCalls, 1);
    expect(controller.snapshot.state, CommerceAuthorityState.loading);

    completion.complete(
      CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 700,
        echoBalance: 125,
        entitlementKeys: const {'theme:nocturne'},
        observedAt: DateTime.utc(2026, 7, 15),
      ),
    );
    await Future.wait([first, second]);

    expect(controller.snapshot.state, CommerceAuthorityState.ready);
    expect(controller.snapshot.astraBalance, 700);
    expect(controller.snapshot.echoBalance, 125);
    expect(controller.snapshot.owns('theme:nocturne'), isTrue);
  });

  test('gateway exception becomes unavailable without fake balances', () async {
    final gateway = _TestCommerceGateway(error: StateError('offline'));
    final controller = CommerceController(gateway: gateway, enabled: true);
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(controller.snapshot.state, CommerceAuthorityState.unavailable);
    expect(controller.snapshot.astraBalance, isNull);
    expect(controller.snapshot.echoBalance, isNull);
    expect(controller.snapshot.issueCode, 'commerce_gateway_error');
  });

  test('late provider completion is ignored after disposal', () async {
    final completion = Completer<CommerceAccountSnapshot>();
    final controller = CommerceController(
      gateway: _TestCommerceGateway(loadResult: completion.future),
      enabled: true,
    );

    final refresh = controller.refresh();
    controller.dispose();
    completion.complete(
      const CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 999,
        echoBalance: 999,
      ),
    );

    await expectLater(refresh, completes);
    expect(controller.snapshot.state, CommerceAuthorityState.loading);
  });
}

class _TestCommerceGateway implements CommerceGateway {
  _TestCommerceGateway({this.loadResult, this.error});

  final Future<CommerceAccountSnapshot>? loadResult;
  final Object? error;
  int loadCalls = 0;

  @override
  Future<CommerceAccountSnapshot> loadAccount() {
    loadCalls += 1;
    if (error case final error?) return Future.error(error);
    return loadResult ??
        Future.value(
          const CommerceAccountSnapshot(state: CommerceAuthorityState.ready),
        );
  }

  @override
  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  }) => throw UnimplementedError();

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) => throw UnimplementedError();
}
