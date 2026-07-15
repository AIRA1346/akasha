import 'dart:async';

import 'package:akasha/core/commerce/commerce.dart';
import 'package:akasha/services/commerce_controller.dart';
import 'package:akasha/services/commerce_playtime_reward_scheduler.dart';
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
        localizedPrices: const {
          CommerceCatalog.astraPack500ProductId: CommerceLocalizedPrice(
            productId: CommerceCatalog.astraPack500ProductId,
            currencyCode: 'KRW',
            currentAmount: 5500,
          ),
        },
        observedAt: DateTime.utc(2026, 7, 15),
      ),
    );
    await Future.wait([first, second]);

    expect(controller.snapshot.state, CommerceAuthorityState.ready);
    expect(controller.snapshot.astraBalance, 700);
    expect(controller.snapshot.echoBalance, 125);
    expect(controller.snapshot.owns('theme:nocturne'), isTrue);
    expect(
      controller.snapshot
          .priceOf(CommerceCatalog.astraPack500ProductId)
          ?.currencyCode,
      'KRW',
    );
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

  test(
    'gateway exception preserves a previous snapshot as offline cache',
    () async {
      final gateway = _TestCommerceGateway(
        loadResult: Future.value(
          CommerceAccountSnapshot(
            state: CommerceAuthorityState.ready,
            astraBalance: 10,
            echoBalance: 20,
            entitlementKeys: const {'theme:sakura'},
            observedAt: DateTime.utc(2026, 7, 15),
          ),
        ),
      );
      final controller = CommerceController(gateway: gateway, enabled: true);
      addTearDown(controller.dispose);
      await controller.refresh();
      gateway.error = StateError('offline');

      await controller.refresh();

      expect(controller.snapshot.state, CommerceAuthorityState.offlineCache);
      expect(controller.snapshot.astraBalance, 10);
      expect(controller.snapshot.echoBalance, 20);
      expect(controller.snapshot.owns('theme:sakura'), isTrue);
      expect(controller.snapshot.canTransact, isFalse);
      expect(controller.snapshot.issueCode, 'commerce_gateway_error');
    },
  );

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

  test(
    'transaction guard refuses a snapshot without provider capability',
    () async {
      final gateway = _TestCommerceGateway(
        loadResult: Future.value(
          const CommerceAccountSnapshot(
            state: CommerceAuthorityState.ready,
            astraBalance: 500,
            echoBalance: 500,
            transactionsEnabled: false,
          ),
        ),
      );
      final controller = CommerceController(gateway: gateway, enabled: true);
      addTearDown(controller.dispose);
      await controller.refresh();

      final result = await controller.purchaseAstraPack(
        CommerceCatalog.astraPack500ProductId,
      );

      expect(result.status, CommerceOperationStatus.rejected);
      expect(result.issueCode, 'commerce_account_not_ready');
      expect(gateway.purchaseCalls, 0);
    },
  );

  test(
    'one pending operation blocks duplicates and publishes reconciliation',
    () async {
      final completion = Completer<CommerceOperationResult>();
      const initial = CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 500,
        echoBalance: 500,
        transactionsEnabled: true,
      );
      const refreshed = CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 1000,
        echoBalance: 500,
        transactionsEnabled: true,
      );
      final gateway = _TestCommerceGateway(
        loadResult: Future.value(initial),
        purchaseResult: completion.future,
      );
      final controller = CommerceController(gateway: gateway, enabled: true);
      addTearDown(controller.dispose);
      await controller.refresh();

      final pending = controller.purchaseAstraPack(
        CommerceCatalog.astraPack500ProductId,
      );
      expect(controller.operationInFlight, isTrue);
      expect(controller.activeProductId, CommerceCatalog.astraPack500ProductId);
      final duplicate = await controller.purchaseAstraPack(
        CommerceCatalog.astraPack500ProductId,
      );
      expect(duplicate.status, CommerceOperationStatus.rejected);
      expect(duplicate.issueCode, 'commerce_operation_in_progress');

      completion.complete(
        const CommerceOperationResult(
          status: CommerceOperationStatus.confirmed,
          snapshot: refreshed,
          providerHandle: 'purchase_1',
        ),
      );
      final result = await pending;

      expect(result.status, CommerceOperationStatus.confirmed);
      expect(controller.snapshot.astraBalance, 1000);
      expect(controller.lastOperation, same(result));
      expect(controller.operationInFlight, isFalse);
      expect(controller.activeProductId, isNull);
      expect(gateway.purchaseCalls, 1);
    },
  );

  test(
    'theme exchange publishes the reconciled entitlement snapshot',
    () async {
      const initial = CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 700,
        echoBalance: 500,
        transactionsEnabled: true,
      );
      const owned = CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 200,
        echoBalance: 500,
        entitlementKeys: {CommerceCatalog.sakuraThemeEntitlementKey},
        transactionsEnabled: true,
      );
      final gateway = _TestCommerceGateway(
        loadResult: Future.value(initial),
        exchangeResult: Future.value(
          const CommerceOperationResult(
            status: CommerceOperationStatus.confirmed,
            snapshot: owned,
            providerHandle: 'exchange_1',
          ),
        ),
      );
      final controller = CommerceController(gateway: gateway, enabled: true);
      addTearDown(controller.dispose);
      await controller.refresh();

      final result = await controller.exchangeTheme(
        productId: CommerceCatalog.sakuraThemeProductId,
        payWith: CurrencyKind.premium,
      );

      expect(result.status, CommerceOperationStatus.confirmed);
      expect(
        controller.snapshot.owns(CommerceCatalog.sakuraThemeEntitlementKey),
        isTrue,
      );
      expect(gateway.exchangeCalls, 1);
    },
  );

  test('playtime reward uses its independent provider capability', () async {
    const initial = CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: 0,
      echoBalance: 40,
      playtimeRewardsEnabled: true,
    );
    const rewarded = CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: 0,
      echoBalance: 50,
      playtimeRewardsEnabled: true,
    );
    final gateway = _TestRewardCommerceGateway(
      loadResult: Future.value(initial),
      rewardResult: Future.value(
        const CommerceOperationResult(
          status: CommerceOperationStatus.confirmed,
          snapshot: rewarded,
          providerHandle: 'drop_1',
        ),
      ),
    );
    final controller = CommerceController(gateway: gateway, enabled: true);
    addTearDown(controller.dispose);
    await controller.refresh();

    final result = await controller.claimEchoPlaytimeReward();

    expect(result.status, CommerceOperationStatus.confirmed);
    expect(controller.snapshot.echoBalance, 50);
    expect(gateway.rewardCalls, 1);
  });

  test('playtime scheduler coalesces overlapping checks', () async {
    final completion = Completer<CommerceOperationResult>();
    final gateway = _TestRewardCommerceGateway(
      loadResult: Future.value(
        const CommerceAccountSnapshot(
          state: CommerceAuthorityState.ready,
          astraBalance: 0,
          echoBalance: 40,
          playtimeRewardsEnabled: true,
        ),
      ),
      rewardResult: completion.future,
    );
    final controller = CommerceController(gateway: gateway, enabled: true);
    final scheduler = CommercePlaytimeRewardScheduler(controller: controller);
    addTearDown(() {
      scheduler.dispose();
      controller.dispose();
    });
    await controller.refresh();

    final first = scheduler.checkNow();
    final duplicate = scheduler.checkNow();
    await duplicate;
    expect(gateway.rewardCalls, 1);

    completion.complete(
      const CommerceOperationResult(
        status: CommerceOperationStatus.noChange,
        snapshot: CommerceAccountSnapshot(
          state: CommerceAuthorityState.ready,
          astraBalance: 0,
          echoBalance: 40,
          playtimeRewardsEnabled: true,
        ),
      ),
    );
    await first;
    expect(controller.lastOperation?.status, CommerceOperationStatus.noChange);
  });
}

class _TestCommerceGateway implements CommerceGateway {
  _TestCommerceGateway({
    this.loadResult,
    this.purchaseResult,
    this.exchangeResult,
    this.error,
  });

  Future<CommerceAccountSnapshot>? loadResult;
  Future<CommerceOperationResult>? purchaseResult;
  Future<CommerceOperationResult>? exchangeResult;
  Object? error;
  int loadCalls = 0;
  int purchaseCalls = 0;
  int exchangeCalls = 0;

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
  }) {
    exchangeCalls += 1;
    return exchangeResult ??
        Future.value(
          CommerceOperationResult(
            status: CommerceOperationStatus.rejected,
            snapshot: const CommerceAccountSnapshot.disabled(),
            issueCode: 'fake_exchange_unavailable',
          ),
        );
  }

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) {
    purchaseCalls += 1;
    return purchaseResult ??
        Future.value(
          CommerceOperationResult(
            status: CommerceOperationStatus.rejected,
            snapshot: const CommerceAccountSnapshot.disabled(),
            issueCode: 'fake_purchase_unavailable',
          ),
        );
  }
}

class _TestRewardCommerceGateway extends _TestCommerceGateway
    implements CommercePlaytimeRewardGateway {
  _TestRewardCommerceGateway({super.loadResult, required this.rewardResult});

  final Future<CommerceOperationResult> rewardResult;
  int rewardCalls = 0;

  @override
  Future<CommerceOperationResult> claimPlaytimeReward() {
    rewardCalls += 1;
    return rewardResult;
  }
}
