import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCommerceRepository repo;
  late FakePaymentProvider payments;
  late CommerceService commerce;
  var clock = DateTime.utc(2026, 7, 12, 8);
  var id = 0;

  setUp(() {
    repo = FakeCommerceRepository();
    payments = FakePaymentProvider();
    id = 0;
    clock = DateTime.utc(2026, 7, 12, 8);
    commerce = CommerceService(
      repository: repo,
      paymentProvider: payments,
      clock: () => clock,
      idFactory: () => 't_${++id}',
    );
  });

  group('CurrencyDisplay', () {
    test('maps premium/earned to Astra/Echo with paid/earned qualifiers', () {
      expect(
        CurrencyDisplay.labeled(CurrencyKind.premium, languageTag: 'en'),
        'Astra (Paid)',
      );
      expect(
        CurrencyDisplay.labeled(CurrencyKind.earned, languageTag: 'en'),
        'Echo (Earned)',
      );
      expect(
        CurrencyDisplay.labeled(CurrencyKind.premium, languageTag: 'ko'),
        '아스트라 (유료)',
      );
      expect(
        CurrencyDisplay.labeled(CurrencyKind.earned, languageTag: 'ko'),
        '에코 (무료 획득)',
      );
    });
  });

  group('premium pack settlement', () {
    test('grants Astra once after payment settles', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      final wallet = await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-1',
      );
      expect(wallet.premium, 100);
      expect(wallet.earned, 0);
      expect(payments.settleCalls, 1);
    });

    test('blocks duplicate grant for the same settle idempotency key', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-1',
      );
      final again = await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-1',
      );
      expect(again.premium, 100);
      expect(repo.ledger.where((e) => e.userId == 'u1').length, 1);
    });

    test('createPremiumPackOrder is idempotent on order key', () async {
      final a = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      final b = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      expect(a.id, b.id);
      expect(repo.ordersById.length, 1);
    });
  });

  group('theme unlock', () {
    Future<void> fundPremium() async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-fund',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-fund',
      );
    }

    test('unlocks theme with Astra and creates entitlement', () async {
      await fundPremium();
      final ent = await commerce.unlockTheme(
        userId: 'u1',
        productId: CommerceCatalog.themeFlex.id,
        payWith: CurrencyKind.premium,
        idempotencyKey: 'unlock-1',
      );
      expect(ent.key, 'theme:flex_demo');
      final wallet = await commerce.wallet('u1');
      expect(wallet.premium, 50);
    });

    test('unlocks theme with Echo when chooseOne allows it', () async {
      await commerce.grantEarned(
        userId: 'u1',
        amount: 100,
        idempotencyKey: 'echo-1',
      );
      final ent = await commerce.unlockTheme(
        userId: 'u1',
        productId: CommerceCatalog.themeFlex.id,
        payWith: CurrencyKind.earned,
        idempotencyKey: 'unlock-echo',
      );
      expect(ent.key, 'theme:flex_demo');
      expect((await commerce.wallet('u1')).earned, 20);
    });

    test('rejects Echo for Astra-only theme', () async {
      await commerce.grantEarned(
        userId: 'u1',
        amount: 100,
        idempotencyKey: 'echo-1',
      );
      expect(
        () => commerce.unlockTheme(
          userId: 'u1',
          productId: CommerceCatalog.themePremiumOnly.id,
          payWith: CurrencyKind.earned,
          idempotencyKey: 'bad',
        ),
        throwsA(
          isA<CommerceRejected>().having(
            (e) => e.code,
            'code',
            'payment_not_allowed',
          ),
        ),
      );
    });

    test('blocks duplicate theme entitlement purchase', () async {
      await fundPremium();
      await commerce.unlockTheme(
        userId: 'u1',
        productId: CommerceCatalog.themeFlex.id,
        payWith: CurrencyKind.premium,
        idempotencyKey: 'unlock-1',
      );
      expect(
        () => commerce.unlockTheme(
          userId: 'u1',
          productId: CommerceCatalog.themeFlex.id,
          payWith: CurrencyKind.premium,
          idempotencyKey: 'unlock-2',
        ),
        throwsA(
          isA<CommerceConflict>().having(
            (e) => e.code,
            'code',
            'entitlement_owned',
          ),
        ),
      );
    });

    test('rejects insufficient balance', () async {
      expect(
        () => commerce.unlockTheme(
          userId: 'u1',
          productId: CommerceCatalog.themeFlex.id,
          payWith: CurrencyKind.premium,
          idempotencyKey: 'unlock-broke',
        ),
        throwsA(
          isA<CommerceRejected>().having(
            (e) => e.code,
            'code',
            'insufficient_balance',
          ),
        ),
      );
    });
  });

  group('donation and refund', () {
    test('donation spends Astra without entitlement', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-1',
      );
      final wallet = await commerce.donate(
        userId: 'u1',
        productId: CommerceCatalog.donationTip.id,
        idempotencyKey: 'donate-1',
      );
      expect(wallet.premium, 90);
      expect(repo.entitlementsByUserKey, isEmpty);
    });

    test('refund adds reversal and does not delete prior credit', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-1',
      );
      final afterRefund = await commerce.refundSettledPremiumPack(
        orderId: order.id,
        idempotencyKey: 'refund-1',
      );
      expect(afterRefund.premium, 0);
      expect(repo.ledger.length, 2);
      expect(repo.ledger.first.type, LedgerEntryType.credit);
      expect(repo.ledger.last.type, LedgerEntryType.reversal);
      expect(
        (await repo.getOrder(order.id))!.status,
        OrderStatus.refunded,
      );
    });

    test('refund idempotency does not double-reverse', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        settleIdempotencyKey: 'settle-1',
      );
      await commerce.refundSettledPremiumPack(
        orderId: order.id,
        idempotencyKey: 'refund-1',
      );
      final again = await commerce.refundSettledPremiumPack(
        orderId: order.id,
        idempotencyKey: 'refund-1',
      );
      expect(again.premium, 0);
      expect(
        repo.ledger.where((e) => e.type == LedgerEntryType.reversal).length,
        1,
      );
    });
  });

  group('invariants', () {
    test('earned grant is idempotent and never converts to premium', () async {
      await commerce.grantEarned(
        userId: 'u1',
        amount: 40,
        idempotencyKey: 'echo-grant',
      );
      await commerce.grantEarned(
        userId: 'u1',
        amount: 40,
        idempotencyKey: 'echo-grant',
      );
      final w = await commerce.wallet('u1');
      expect(w.earned, 40);
      expect(w.premium, 0);
    });
  });
}
