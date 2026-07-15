import 'package:akasha_commerce_server/akasha_commerce_server.dart';
import 'package:test/test.dart';

import 'support/in_memory_steam_sandbox_transport.dart';

void main() {
  const realSteamId = '76561198000000001';
  const spoofSteamId = '76561198999999999';
  late SteamPublisherCredentials credentials;
  late SandboxSteamTicketAuthenticator authenticator;
  late FakeSecureCommerceRepository repo;
  late FakeSteamMicroTxnAdapter steam;
  late SecureCommerceService service;
  late CommercePurchaseGateway gateway;
  var id = 0;

  setUp(() {
    credentials = SteamPublisherCredentials.forLocalHarness();
    authenticator = SandboxSteamTicketAuthenticator(credentials: credentials);
    repo = FakeSecureCommerceRepository();
    steam = FakeSteamMicroTxnAdapter();
    id = 0;
    service = SecureCommerceService(
      repository: repo,
      steam: steam,
      orderIds: MonotonicOrderId64Generator(start: 800001),
      clock: () => DateTime.utc(2026, 7, 12, 12),
      idFactory: () => 'g_${++id}',
    );
    gateway = CommercePurchaseGateway(
      service: service,
      authenticator: authenticator,
      credentials: credentials,
    );
  });

  void issue(String ticket, {String steamId = realSteamId, int? appId}) {
    authenticator.issueSandboxTicket(
      ticket,
      VerifiedSteamIdentity(
        steamId64: steamId,
        appId: appId ?? credentials.appId,
      ),
    );
  }

  test('ticket auth failure rejects begin', () async {
    await expectLater(
      gateway.beginPremiumPackPurchase(
        authTicketHex: 'missing',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'op-1',
      ),
      throwsA(
        isA<SteamAuthException>().having(
          (e) => e.code,
          'code',
          'ticket_invalid',
        ),
      ),
    );
  });

  test('ticket reuse is rejected', () async {
    issue('ticket-once');
    await gateway.beginPremiumPackPurchase(
      authTicketHex: 'ticket-once',
      productId: CommerceCatalog.astraPack500.id,
      idempotencyKey: 'op-1',
    );
    await expectLater(
      gateway.beginPremiumPackPurchase(
        authTicketHex: 'ticket-once',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'op-2',
      ),
      throwsA(
        isA<SteamAuthException>().having((e) => e.code, 'code', 'ticket_reuse'),
      ),
    );
  });

  test('AppID mismatch on ticket is rejected', () async {
    issue('bad-app', appId: 111);
    await expectLater(
      gateway.beginPremiumPackPurchase(
        authTicketHex: 'bad-app',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'op-1',
      ),
      throwsA(
        isA<SteamAuthException>().having(
          (e) => e.code,
          'code',
          'appid_mismatch',
        ),
      ),
    );
  });

  test(
    'verified SteamID owns order; spoofed client SteamID is irrelevant',
    () async {
      issue('t1');
      final order = await gateway.beginPremiumPackPurchase(
        authTicketHex: 't1',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'op-1',
      );
      expect(order.steamId, realSteamId);
      expect(repo.accounts.containsKey(spoofSteamId), isFalse);
      expect(repo.accounts.containsKey(realSteamId), isTrue);
    },
  );

  test(
    'authorization callback correlates AppID/OrderID/SteamID then grants once',
    () async {
      issue('t-begin');
      final order = await gateway.beginPremiumPackPurchase(
        authTicketHex: 't-begin',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'op-1',
      );
      expect((await service.wallet(realSteamId)).premium, 0);

      issue('t-fin');
      final wallet = await gateway.completeAfterUserAuthorization(
        authTicketHex: 't-fin',
        callback: MicroTxnAuthorizationCallback(
          appId: credentials.appId,
          orderId: order.orderId,
          authorized: true,
          clientClaimedSteamId: spoofSteamId,
        ),
        finalizeIdempotencyKey: 'fin-1',
      );
      expect(wallet.premium, 500);
      expect(order.steamId, isNot(spoofSteamId));
    },
  );

  test('callback AppID mismatch rejected', () async {
    issue('t-begin');
    final order = await gateway.beginPremiumPackPurchase(
      authTicketHex: 't-begin',
      productId: CommerceCatalog.astraPack500.id,
      idempotencyKey: 'op-1',
    );
    issue('t-fin');
    await expectLater(
      gateway.completeAfterUserAuthorization(
        authTicketHex: 't-fin',
        callback: MicroTxnAuthorizationCallback(
          appId: 999,
          orderId: order.orderId,
          authorized: true,
        ),
        finalizeIdempotencyKey: 'fin-1',
      ),
      throwsA(
        isA<CommerceRejected>().having((e) => e.code, 'code', 'appid_mismatch'),
      ),
    );
  });

  test(
    'callback SteamID mismatch rejected when ticket is another user',
    () async {
      issue('t-begin');
      final order = await gateway.beginPremiumPackPurchase(
        authTicketHex: 't-begin',
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 'op-1',
      );
      issue('t-other', steamId: spoofSteamId);
      await expectLater(
        gateway.completeAfterUserAuthorization(
          authTicketHex: 't-other',
          callback: MicroTxnAuthorizationCallback(
            appId: credentials.appId,
            orderId: order.orderId,
            authorized: true,
          ),
          finalizeIdempotencyKey: 'fin-1',
        ),
        throwsA(
          isA<CommerceRejected>().having(
            (e) => e.code,
            'code',
            'steamid_mismatch',
          ),
        ),
      );
    },
  );

  test(
    'sandbox adapter redacts key in audit and does not grant on InitTxn',
    () async {
      final transport = InMemorySteamSandboxTransport();
      final audit = <SteamApiResponseAudit>[];
      final adapter = SandboxSteamMicroTxnAdapter(
        credentials: credentials,
        transport: transport,
        auditLog: audit,
      );
      final harness = SecureCommerceService(
        repository: FakeSecureCommerceRepository(),
        steam: adapter,
        orderIds: MonotonicOrderId64Generator(start: 1),
        idFactory: () => 's_1',
      );
      final order = await harness.beginPremiumPackPurchase(
        steamId: realSteamId,
        productId: CommerceCatalog.astraPack500.id,
        idempotencyKey: 's-op',
      );
      expect((await harness.wallet(realSteamId)).premium, 0);
      expect(order.state, ServerOrderState.authorizationPending);
      expect(audit, isNotEmpty);
      expect(audit.first.method, 'InitTxn');
      expect(audit.first.redactedBody.contains(credentials.webApiKey), isFalse);
      expect(
        SandboxSteamMicroTxnAdapter.redact(
          'key=${credentials.webApiKey}&status=OK',
        ),
        'key=***&status=OK',
      );

      await harness.completePremiumPackPurchase(
        orderId: order.orderId,
        finalizeIdempotencyKey: 's-fin',
      );
      expect((await harness.wallet(realSteamId)).premium, 500);
      expect(audit.any((a) => a.method == 'FinalizeTxn'), isTrue);
    },
  );

  test(
    'sandbox GetUserInfo / QueryTxn / RefundTxn / GetReport audited',
    () async {
      final transport = InMemorySteamSandboxTransport();
      final audit = <SteamApiResponseAudit>[];
      final adapter = SandboxSteamMicroTxnAdapter(
        credentials: credentials,
        transport: transport,
        auditLog: audit,
        reportQueue: [
          const SteamReportRow(
            orderId: '1',
            steamId: realSteamId,
            phase: SteamTxnPhase.reportCompleted,
            reportId: 'r1',
          ),
        ],
      );
      expect(
        (await adapter.getUserInfo(steamId: realSteamId)).phase,
        SteamTxnPhase.userAuthorized,
      );
      await adapter.initTxn(
        steamId: realSteamId,
        orderId: '1',
        productId: 'p',
        premiumGrantAmount: 100,
      );
      transport.orderStatus['1'] = 'Succeeded';
      expect(
        (await adapter.queryTxn(steamId: realSteamId, orderId: '1')).phase,
        SteamTxnPhase.reportCompleted,
      );
      await adapter.refundTxn(steamId: realSteamId, orderId: '1');
      final rows = await adapter.getReport(cursorHighWater: '0');
      expect(rows.single.reportId, 'r1');
      expect(transport.getReportCalls, 1);
      final methods = audit.map((a) => a.method).toSet();
      expect(
        methods.containsAll([
          'GetUserInfo',
          'InitTxn',
          'QueryTxn',
          'RefundTxn',
          'GetReport',
        ]),
        isTrue,
      );
    },
  );

  test('production credentials require env; harness does not', () {
    expect(
      () => SteamPublisherCredentials.fromEnvironment(environment: {}),
      throwsStateError,
    );
    expect(
      SteamPublisherCredentials.forLocalHarness().webApiKey,
      'SANDBOX_TEST_KEY_NOT_FOR_PRODUCTION',
    );
  });
}
