import 'package:akasha_commerce_server/akasha_commerce_server.dart';
import 'package:test/test.dart';

void main() {
  late FakeSecureCommerceRepository repo;
  late FakeSteamMicroTxnAdapter steam;
  late SecureCommerceService backend;
  var id = 0;

  setUp(() {
    repo = FakeSecureCommerceRepository();
    steam = FakeSteamMicroTxnAdapter();
    id = 0;
    backend = SecureCommerceService(
      repository: repo,
      steam: steam,
      orderIds: MonotonicOrderId64Generator(start: 900001),
      clock: () => DateTime.utc(2026, 7, 12, 10),
      idFactory: () => 'b_${++id}',
    );
  });

  test(
    'begin creates SteamID account, 64-bit order, authorization_pending',
    () async {
      final order = await backend.beginPremiumPackPurchase(
        steamId: '76561198000000001',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'client-op-1',
      );
      expect(order.orderId.value, 900001);
      expect(order.state, ServerOrderState.authorizationPending);
      expect(order.lastSteamPhase, SteamTxnPhase.initAccepted);
      expect(await repo.getAccount('76561198000000001'), isNotNull);
    },
  );

  test('InitTxn success alone does not grant Astra', () async {
    await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.astraPack500.id,
      idempotencyKey: 'client-op-1',
    );
    expect((await backend.wallet('76561198000000001')).premium, 0);
  });

  test('begin rejects raw or retired Astra item ids before InitTxn', () async {
    for (final productId in ['astra_unit', 'astra_pack_100']) {
      await expectLater(
        backend.beginPremiumPackPurchase(
          steamId: '76561198000000001',
          productId: productId,
          idempotencyKey: 'reject-$productId',
        ),
        throwsA(
          isA<CommerceRejected>().having(
            (error) => error.code,
            'code',
            'unapproved_astra_pack',
          ),
        ),
      );
    }
    expect(steam.orderPhase, isEmpty);
  });

  test('begin is idempotent on client key', () async {
    final a = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.astraPack500.id,
      idempotencyKey: 'client-op-1',
    );
    final b = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.astraPack500.id,
      idempotencyKey: 'client-op-1',
    );
    expect(a.orderId, b.orderId);
    expect(repo.ordersById.length, 1);
  });

  test('complete finalizes and grants Astra once', () async {
    final order = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.astraPack500.id,
      idempotencyKey: 'client-op-1',
    );
    final wallet = await backend.completePremiumPackPurchase(
      orderId: order.orderId,
      finalizeIdempotencyKey: 'fin-1',
    );
    expect(wallet.premium, 500);

    final again = await backend.completePremiumPackPurchase(
      orderId: order.orderId,
      finalizeIdempotencyKey: 'fin-1',
    );
    expect(again.premium, 500);
    expect(
      repo.ledger.where((e) => e.type == LedgerEntryType.credit).length,
      1,
    );
  });

  test(
    'indeterminate finalize does not grant; QueryTxn can complete',
    () async {
      steam.finalizeIndeterminate = true;
      final order = await backend.beginPremiumPackPurchase(
        steamId: '76561198000000001',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'client-op-1',
      );
      await expectLater(
        backend.completePremiumPackPurchase(
          orderId: order.orderId,
          finalizeIdempotencyKey: 'fin-1',
        ),
        throwsA(
          isA<CommerceRejected>().having(
            (e) => e.code,
            'code',
            'finalize_indeterminate',
          ),
        ),
      );
      expect((await backend.wallet('76561198000000001')).premium, 0);

      steam.orderPhase[order.orderIdKey] = SteamTxnPhase.reportCompleted;
      steam.finalizeIndeterminate = false;
      final wallet = await backend.resolveIndeterminateOrder(
        orderId: order.orderId,
        resolveIdempotencyKey: 'resolve-1',
      );
      expect(wallet.premium, 500);
    },
  );

  test(
    'GetReport chargeback reverses once; Echo untouched; cursor persisted',
    () async {
      final order = await backend.beginPremiumPackPurchase(
        steamId: '76561198000000001',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'client-op-1',
      );
      await backend.completePremiumPackPurchase(
        orderId: order.orderId,
        finalizeIdempotencyKey: 'fin-1',
      );
      await repo.appendLedger(
        LedgerEntry(
          id: 'echo1',
          userId: '76561198000000001',
          currency: CurrencyKind.earned,
          type: LedgerEntryType.credit,
          amount: 25,
          idempotencyKey: 'echo-1',
          createdAt: DateTime.utc(2026, 7, 12),
        ),
      );

      final row = SteamReportRow(
        orderId: order.orderIdKey,
        steamId: '76561198000000001',
        phase: SteamTxnPhase.reportChargeback,
        reportId: 'rpt-100',
      );
      steam.reportQueue.add(row);
      expect(await backend.reconcileGetReport(cursorHighWater: '0'), 1);
      expect((await backend.wallet('76561198000000001')).premium, 0);
      expect((await backend.wallet('76561198000000001')).earned, 25);

      // Duplicate page / same reportId must not reverse again.
      steam.reportQueue.add(row);
      expect(await backend.reconcileGetReport(cursorHighWater: 'rpt-100'), 0);
      expect(
        repo.ledger.where((e) => e.type == LedgerEntryType.reversal).length,
        1,
      );
      expect(
        (await repo.getReconciliationCursor('steam_getreport'))!.highWaterMark,
        'rpt-100',
      );
    },
  );

  test('unknown Steam phase maps to indeterminate via mapper', () {
    expect(
      SteamToServerStateMapper.mapPhase(
        SteamTxnPhase.indeterminate,
        current: ServerOrderState.finalizing,
      ),
      ServerOrderState.indeterminate,
    );
    expect(
      SteamToServerStateMapper.unknownSteamStatus(ServerOrderState.authorized),
      ServerOrderState.indeterminate,
    );
    expect(
      SteamTxnPhase.values.map((e) => e.name).contains('created'),
      isFalse,
    );
    expect(
      ServerOrderState.values.map((e) => e.name).contains('created'),
      isTrue,
    );
  });
}
