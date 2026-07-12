import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('begin creates SteamID account, 64-bit order, authorization_pending', () async {
    final order = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.premiumPack100.id,
      idempotencyKey: 'client-op-1',
    );
    expect(order.orderId.value, 900001);
    expect(order.state, ServerOrderState.authorizationPending);
    expect(order.lastSteamPhase, SteamTxnPhase.initAccepted);
    expect(await repo.getAccount('76561198000000001'), isNotNull);
    expect(repo.transactionDepth, 0);
  });

  test('begin is idempotent on client key', () async {
    final a = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.premiumPack100.id,
      idempotencyKey: 'client-op-1',
    );
    final b = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.premiumPack100.id,
      idempotencyKey: 'client-op-1',
    );
    expect(a.orderId, b.orderId);
    expect(repo.ordersById.length, 1);
  });

  test('complete finalizes and grants Astra once', () async {
    final order = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.premiumPack100.id,
      idempotencyKey: 'client-op-1',
    );
    final wallet = await backend.completePremiumPackPurchase(
      orderId: order.orderId,
      finalizeIdempotencyKey: 'fin-1',
    );
    expect(wallet.premium, 100);
    expect(
      (await repo.getOrder(order.orderId))!.state,
      ServerOrderState.completed,
    );

    final again = await backend.completePremiumPackPurchase(
      orderId: order.orderId,
      finalizeIdempotencyKey: 'fin-1',
    );
    expect(again.premium, 100);
    expect(repo.ledger.where((e) => e.type == LedgerEntryType.credit).length, 1);
  });

  test('indeterminate finalize does not grant; QueryTxn/GetReport can complete', () async {
    steam.finalizeIndeterminate = true;
    final order = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.premiumPack100.id,
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
    expect(
      (await repo.getOrder(order.orderId))!.state,
      ServerOrderState.indeterminate,
    );

    steam.orderPhase[order.orderIdKey] = SteamTxnPhase.reportCompleted;
    steam.finalizeIndeterminate = false;
    final wallet = await backend.resolveIndeterminateOrder(
      orderId: order.orderId,
      resolveIdempotencyKey: 'resolve-1',
    );
    expect(wallet.premium, 100);
  });

  test('GetReport chargeback reverses grant without touching Echo', () async {
    final order = await backend.beginPremiumPackPurchase(
      steamId: '76561198000000001',
      productId: CommerceCatalog.premiumPack100.id,
      idempotencyKey: 'client-op-1',
    );
    await backend.completePremiumPackPurchase(
      orderId: order.orderId,
      finalizeIdempotencyKey: 'fin-1',
    );

    // Simulate Echo grant on same account via domain ledger append.
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

    steam.reportQueue.add(
      SteamReportRow(
        orderId: order.orderIdKey,
        steamId: '76561198000000001',
        phase: SteamTxnPhase.reportChargeback,
        reportId: 'rpt-100',
      ),
    );
    final n = await backend.reconcileGetReport(cursorHighWater: '0');
    expect(n, 1);
    final w = await backend.wallet('76561198000000001');
    expect(w.premium, 0);
    expect(w.earned, 25);
    expect(
      (await repo.getOrder(order.orderId))!.state,
      ServerOrderState.chargedBack,
    );
    expect(
      (await repo.getReconciliationCursor('steam_getreport'))!.highWaterMark,
      'rpt-100',
    );
  });

  test('server product catalog is available from repository', () async {
    final products = await repo.listProducts();
    expect(products.any((p) => p.id == CommerceCatalog.supportAkasha.id), isTrue);
    expect(
      products.firstWhere((p) => p.id == CommerceCatalog.supportAkasha.id).kind,
      ProductKind.support,
    );
  });

  test('SteamTxnPhase and ServerOrderState stay distinct enums', () {
    expect(SteamTxnPhase.values.map((e) => e.name).toSet().contains('created'), isFalse);
    expect(ServerOrderState.values.map((e) => e.name).contains('created'), isTrue);
    expect(ServerOrderState.values.length, greaterThanOrEqualTo(10));
  });
}
