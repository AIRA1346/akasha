import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:test/test.dart';

void main() {
  const testFlexibleThemeA = CommerceProduct(
    id: 'test_theme_flexible_a',
    kind: ProductKind.themePackage,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: 50,
      earnedPrice: 80,
    ),
    entitlementKey: 'theme:test_flexible_a',
  );
  const testFlexibleThemeB = CommerceProduct(
    id: 'test_theme_flexible_b',
    kind: ProductKind.themePackage,
    payment: PaymentOption(
      policy: PaymentPolicy.chooseOne,
      premiumPrice: 50,
      earnedPrice: 40,
    ),
    entitlementKey: 'theme:test_flexible_b',
  );
  const testAstraOnlyTheme = CommerceProduct(
    id: 'test_theme_astra_only',
    kind: ProductKind.themePackage,
    payment: PaymentOption(policy: PaymentPolicy.premiumOnly, premiumPrice: 60),
    entitlementKey: 'theme:test_astra_only',
  );
  const testSupport = CommerceProduct(
    id: 'test_support_10',
    kind: ProductKind.support,
    payment: PaymentOption(policy: PaymentPolicy.premiumOnly, premiumPrice: 10),
    displayNameEn: 'Support AKASHA',
    displayNameKo: 'AKASHA 후원',
  );

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

  group('approved launch catalog', () {
    test('uses equal choose-one prices for all paid launch themes', () {
      expect(CommerceCatalog.astraUnitsPerReferenceUsd, 100);
      expect(CommerceCatalog.launchThemePackages, hasLength(3));
      for (final product in CommerceCatalog.launchThemePackages) {
        expect(product.kind, ProductKind.themePackage);
        expect(product.offerState, CommerceOfferState.planned);
        expect(product.payment?.policy, PaymentPolicy.chooseOne);
        expect(
          product.payment?.premiumPrice,
          CommerceCatalog.launchThemeAstraPrice,
        );
        expect(
          product.payment?.earnedPrice,
          CommerceCatalog.launchThemeEchoPrice,
        );
        expect(product.entitlementKey, startsWith('theme:'));
      }
    });

    test('account snapshot never invents unknown zero balances', () {
      const disabled = CommerceAccountSnapshot.disabled();
      expect(disabled.astraBalance, isNull);
      expect(disabled.echoBalance, isNull);
      expect(disabled.hasKnownBalances, isFalse);
      expect(disabled.canTransact, isFalse);

      const ready = CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 0,
        echoBalance: 0,
      );
      expect(ready.hasKnownBalances, isTrue);
      expect(ready.canTransact, isTrue);
    });
  });

  group('premium pack finalization', () {
    test('grants Astra once after FinalizeTxn succeeds', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      final wallet = await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        finalizeIdempotencyKey: 'finalize-1',
      );
      expect(wallet.premium, 100);
      expect(wallet.earned, 0);
      expect(payments.finalizeCalls, 1);
      expect((await repo.getOrder(order.id))!.status, OrderStatus.completed);
    });

    test(
      'blocks duplicate grant for the same finalize idempotency key',
      () async {
        final order = await commerce.createPremiumPackOrder(
          userId: 'u1',
          productId: CommerceCatalog.premiumPack100.id,
          idempotencyKey: 'order-1',
        );
        await commerce.finalizePremiumPackPurchase(
          orderId: order.id,
          finalizeIdempotencyKey: 'finalize-1',
        );
        final again = await commerce.finalizePremiumPackPurchase(
          orderId: order.id,
          finalizeIdempotencyKey: 'finalize-1',
        );
        expect(again.premium, 100);
        expect(repo.ledger.where((e) => e.userId == 'u1').length, 1);
      },
    );

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
      for (var i = 0; i < 5; i++) {
        final order = await commerce.createPremiumPackOrder(
          userId: 'u1',
          productId: CommerceCatalog.premiumPack100.id,
          idempotencyKey: 'order-fund-$i',
        );
        await commerce.finalizePremiumPackPurchase(
          orderId: order.id,
          finalizeIdempotencyKey: 'finalize-fund-$i',
        );
      }
    }

    test('unlocks theme with Astra and creates entitlement', () async {
      await fundPremium();
      final ent = await commerce.unlockTheme(
        userId: 'u1',
        productId: CommerceCatalog.sakuraThemePackage.id,
        payWith: CurrencyKind.premium,
        idempotencyKey: 'unlock-1',
      );
      expect(ent.key, 'theme:sakura');
      final wallet = await commerce.wallet('u1');
      expect(wallet.premium, 0);
    });

    test('unlocks theme with Echo when chooseOne allows it', () async {
      await commerce.grantEarned(
        userId: 'u1',
        amount: 500,
        idempotencyKey: 'echo-1',
      );
      final ent = await commerce.unlockTheme(
        userId: 'u1',
        productId: CommerceCatalog.sakuraThemePackage.id,
        payWith: CurrencyKind.earned,
        idempotencyKey: 'unlock-echo',
      );
      expect(ent.key, 'theme:sakura');
      expect((await commerce.wallet('u1')).earned, 0);
    });

    test('rejects Echo for Astra-only theme', () async {
      repo.products[testAstraOnlyTheme.id] = testAstraOnlyTheme;
      await commerce.grantEarned(
        userId: 'u1',
        amount: 100,
        idempotencyKey: 'echo-1',
      );
      expect(
        () => commerce.unlockTheme(
          userId: 'u1',
          productId: testAstraOnlyTheme.id,
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
        productId: CommerceCatalog.sakuraThemePackage.id,
        payWith: CurrencyKind.premium,
        idempotencyKey: 'unlock-1',
      );
      expect(
        () => commerce.unlockTheme(
          userId: 'u1',
          productId: CommerceCatalog.sakuraThemePackage.id,
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
          productId: CommerceCatalog.sakuraThemePackage.id,
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

  group('support and refund', () {
    test('support spends Astra without entitlement', () async {
      repo.products[testSupport.id] = testSupport;
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        finalizeIdempotencyKey: 'finalize-1',
      );
      final wallet = await commerce.purchaseSupport(
        userId: 'u1',
        productId: testSupport.id,
        idempotencyKey: 'support-1',
      );
      expect(wallet.premium, 90);
      expect(repo.entitlementsByUserKey, isEmpty);
      expect(testSupport.displayNameEn, 'Support AKASHA');
      expect(testSupport.displayNameKo, 'AKASHA 후원');
      expect(testSupport.kind, ProductKind.support);
    });

    test('refund adds reversal and does not delete prior credit', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        finalizeIdempotencyKey: 'finalize-1',
      );
      final afterRefund = await commerce.refundCompletedPremiumPack(
        orderId: order.id,
        idempotencyKey: 'refund-1',
      );
      expect(afterRefund.premium, 0);
      expect(repo.ledger.length, 2);
      expect(repo.ledger.first.type, LedgerEntryType.credit);
      expect(repo.ledger.last.type, LedgerEntryType.reversal);
      expect((await repo.getOrder(order.id))!.status, OrderStatus.refunded);
    });

    test(
      'refund after spend allows negative premium, keeps entitlement, blocks Astra spend, leaves Echo',
      () async {
        repo.products[testFlexibleThemeA.id] = testFlexibleThemeA;
        repo.products[testFlexibleThemeB.id] = testFlexibleThemeB;
        repo.products[testSupport.id] = testSupport;
        final order = await commerce.createPremiumPackOrder(
          userId: 'u1',
          productId: CommerceCatalog.premiumPack100.id,
          idempotencyKey: 'order-1',
        );
        await commerce.finalizePremiumPackPurchase(
          orderId: order.id,
          finalizeIdempotencyKey: 'finalize-1',
        );
        await commerce.unlockTheme(
          userId: 'u1',
          productId: testFlexibleThemeA.id,
          payWith: CurrencyKind.premium,
          idempotencyKey: 'unlock-1',
        );
        await commerce.grantEarned(
          userId: 'u1',
          amount: 80,
          idempotencyKey: 'echo-keep',
        );

        final afterRefund = await commerce.refundCompletedPremiumPack(
          orderId: order.id,
          idempotencyKey: 'refund-1',
        );
        expect(afterRefund.premium, -50);
        expect(afterRefund.earned, 80);
        expect(
          await repo.findEntitlement(
            userId: 'u1',
            key: 'theme:test_flexible_a',
          ),
          isNotNull,
        );

        expect(
          () => commerce.purchaseSupport(
            userId: 'u1',
            productId: testSupport.id,
            idempotencyKey: 'support-blocked',
          ),
          throwsA(
            isA<CommerceRejected>().having(
              (e) => e.code,
              'code',
              'insufficient_balance',
            ),
          ),
        );

        // Echo spend still works while premium is negative.
        final echoTheme = await commerce.unlockTheme(
          userId: 'u1',
          productId: testFlexibleThemeB.id,
          payWith: CurrencyKind.earned,
          idempotencyKey: 'echo-theme',
        );
        expect(echoTheme.key, 'theme:test_flexible_b');
        final w = await commerce.wallet('u1');
        expect(w.premium, -50);
        expect(w.earned, 40);
      },
    );

    test('refund idempotency does not double-reverse', () async {
      final order = await commerce.createPremiumPackOrder(
        userId: 'u1',
        productId: CommerceCatalog.premiumPack100.id,
        idempotencyKey: 'order-1',
      );
      await commerce.finalizePremiumPackPurchase(
        orderId: order.id,
        finalizeIdempotencyKey: 'finalize-1',
      );
      await commerce.refundCompletedPremiumPack(
        orderId: order.id,
        idempotencyKey: 'refund-1',
      );
      final again = await commerce.refundCompletedPremiumPack(
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
