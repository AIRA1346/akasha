import 'package:akasha/widgets/commerce_center_dialog.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/services/commerce_controller.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows approved theme catalog without fake balances or buy CTA', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('상점 및 인벤토리'), findsOneWidget);
    expect(find.text('아스트라 충전'), findsOneWidget);
    expect(find.text('아스트라 500개'), findsOneWidget);
    expect(find.text('아스트라 1,000개'), findsOneWidget);
    expect(find.text('아스트라 2,500개'), findsOneWidget);
    expect(find.text('500 Astra 또는 500 Echo'), findsNWidgets(3));
    expect(find.text('출시 준비 중'), findsNWidgets(6));
    expect(find.text('Steam 연결 후 현지 가격 확인'), findsNWidgets(3));
    expect(find.text('Steam에서 구매'), findsNothing);
    expect(find.text('Astra 0'), findsNothing);
    expect(
      find.byKey(const ValueKey('commerce-authority-disabled')),
      findsOneWidget,
    );

    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();

    expect(find.text('아스트라'), findsOneWidget);
    expect(find.text('에코'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('클래식 다크'), findsOneWidget);
    expect(find.text('미드나이트 블루'), findsOneWidget);
    expect(find.text('벚꽃'), findsNothing);
    await tester.drag(
      find.byKey(const PageStorageKey('commerce-inventory-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('소유권 확인 불가'), findsOneWidget);
  });

  testWidgets('renders provider balances and owned premium theme when known', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        account: const CommerceAccountSnapshot(
          state: CommerceAuthorityState.ready,
          astraBalance: 120,
          echoBalance: 45,
          entitlementKeys: {'theme:sakura'},
          localizedPrices: {
            CommerceCatalog.astraPack500ProductId: CommerceLocalizedPrice(
              productId: CommerceCatalog.astraPack500ProductId,
              currencyCode: 'KRW',
              currentAmount: 550000,
            ),
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Steam 가격 · 5,500 KRW'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('commerce-authority-ready')),
      findsOneWidget,
    );
    expect(find.text('보유 중'), findsOneWidget);

    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();

    expect(find.text('120'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('벚꽃'), findsOneWidget);
    expect(find.text('보유 중'), findsWidgets);
    expect(find.text('소유권 확인 불가'), findsNothing);
  });

  testWidgets('shows loading authority without inventing account values', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        account: const CommerceAccountSnapshot(
          state: CommerceAuthorityState.loading,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The loading indicator is intentionally continuous, so settle cannot
    // complete while this authority state is visible.
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('commerce-authority-loading')),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Astra 0'), findsNothing);
    expect(find.byKey(const ValueKey('commerce-retry-button')), findsNothing);
  });

  testWidgets('retries an unavailable provider and exposes refreshed data', (
    tester,
  ) async {
    final gateway = _RetryCommerceGateway();
    final controller = CommerceController(gateway: gateway, enabled: true);
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(
      _harness(account: null, commerceController: controller),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('commerce-authority-unavailable')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('commerce-retry-button')));
    await tester.pumpAndSettle();

    expect(gateway.loadCalls, 2);
    expect(
      find.byKey(const ValueKey('commerce-authority-ready')),
      findsOneWidget,
    );
    expect(find.text('Steam 가격 · 5,500 KRW'), findsOneWidget);

    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();
    expect(find.text('900'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets(
    'reads the app-root commerce snapshot when no override is given',
    (tester) async {
      final controller = CommerceController(
        gateway: const _DialogCommerceGateway(),
        enabled: true,
      );
      addTearDown(controller.dispose);
      await controller.refresh();

      await tester.pumpWidget(
        _harness(account: null, commerceController: controller),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.inventory_2_outlined));
      await tester.pumpAndSettle();

      expect(find.text('321'), findsOneWidget);
      expect(find.text('654'), findsOneWidget);
    },
  );

  testWidgets('sandbox Astra purchase requires confirmation and reconciles', (
    tester,
  ) async {
    final gateway = _TransactionCommerceGateway();
    final controller = CommerceController(gateway: gateway, enabled: true);
    addTearDown(controller.dispose);
    await controller.refresh();
    await tester.pumpWidget(
      _harness(account: null, commerceController: controller),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Steam 거래가 활성화되어 있습니다. 완료 후 인벤토리에서 결과를 확인합니다.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('commerce-buy-astra_pack_500')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('commerce-purchase-confirmation')),
      findsOneWidget,
    );
    expect(gateway.purchaseProductIds, isEmpty);

    await tester.tap(find.byKey(const ValueKey('commerce-confirm-purchase')));
    await tester.pumpAndSettle();

    expect(gateway.purchaseProductIds, [CommerceCatalog.astraPack500ProductId]);
    expect(
      find.byKey(const ValueKey('commerce-result-confirmed')),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('theme exchange enforces one affordable currency choice', (
    tester,
  ) async {
    final gateway = _TransactionCommerceGateway(
      initialAstra: 400,
      initialEcho: 600,
    );
    final controller = CommerceController(gateway: gateway, enabled: true);
    addTearDown(controller.dispose);
    await controller.refresh();
    await tester.pumpWidget(
      _harness(account: null, commerceController: controller),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('commerce-store-scroll')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('commerce-exchange-theme_package_sakura')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('선택한 재화는 즉시 소비'), findsOneWidget);
    final astra = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('commerce-pay-astra')),
        matching: find.byType(OutlinedButton),
      ),
    );
    final echo = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('commerce-pay-echo')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(astra.onPressed, isNull);
    expect(echo.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('commerce-pay-echo')));
    await tester.pumpAndSettle();

    expect(gateway.exchangeProductIds, [CommerceCatalog.sakuraThemeProductId]);
    expect(gateway.exchangeCurrencies, [CurrencyKind.earned]);
    expect(controller.snapshot.echoBalance, 100);
    expect(
      controller.snapshot.owns(CommerceCatalog.sakuraThemeEntitlementKey),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('commerce-result-confirmed')),
      findsOneWidget,
    );
  });

  testWidgets('1024 by 720 at 125 percent text scale does not overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 720));
    await tester.pumpWidget(
      _harness(textScaler: const TextScaler.linear(1.25)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('아스트라 충전'), findsOneWidget);

    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('480 by 720 compact layout remains usable at 125 percent', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(480, 720));
    await tester.pumpWidget(
      _harness(textScaler: const TextScaler.linear(1.25)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('아스트라 충전'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('아스트라'), findsOneWidget);
    expect(find.text('에코'), findsOneWidget);
  });
}

Widget _harness({
  CommerceAccountSnapshot? account = const CommerceAccountSnapshot.disabled(),
  CommerceController? commerceController,
  TextScaler? textScaler,
}) {
  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AkashaTheme.dark(),
    builder: (context, child) {
      Widget content = child!;
      if (textScaler != null) {
        content = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: content,
        );
      }
      if (commerceController != null) {
        content = CommerceScope(controller: commerceController, child: content);
      }
      return content;
    },
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showCommerceCenterDialog(context, account: account),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

class _DialogCommerceGateway implements CommerceGateway {
  const _DialogCommerceGateway();

  @override
  Future<CommerceAccountSnapshot> loadAccount() async =>
      const CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 321,
        echoBalance: 654,
        entitlementKeys: {'theme:amethyst'},
      );

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

class _RetryCommerceGateway implements CommerceGateway {
  int loadCalls = 0;

  @override
  Future<CommerceAccountSnapshot> loadAccount() async {
    loadCalls += 1;
    if (loadCalls == 1) throw StateError('offline');
    return const CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: 900,
      echoBalance: 60,
      localizedPrices: {
        CommerceCatalog.astraPack500ProductId: CommerceLocalizedPrice(
          productId: CommerceCatalog.astraPack500ProductId,
          currencyCode: 'KRW',
          currentAmount: 550000,
        ),
      },
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

class _TransactionCommerceGateway implements CommerceGateway {
  _TransactionCommerceGateway({this.initialAstra = 500, this.initialEcho = 500})
    : _snapshot = CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: initialAstra,
        echoBalance: initialEcho,
        localizedPrices: const {
          CommerceCatalog.astraPack500ProductId: CommerceLocalizedPrice(
            productId: CommerceCatalog.astraPack500ProductId,
            currencyCode: 'KRW',
            currentAmount: 550000,
          ),
        },
        transactionsEnabled: true,
      );

  final int initialAstra;
  final int initialEcho;
  final List<String> purchaseProductIds = [];
  final List<String> exchangeProductIds = [];
  final List<CurrencyKind> exchangeCurrencies = [];
  CommerceAccountSnapshot _snapshot;

  @override
  Future<CommerceAccountSnapshot> loadAccount() async => _snapshot;

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) async {
    purchaseProductIds.add(productId);
    _snapshot = CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: (_snapshot.astraBalance ?? 0) + 500,
      echoBalance: _snapshot.echoBalance,
      entitlementKeys: _snapshot.entitlementKeys,
      localizedPrices: _snapshot.localizedPrices,
      transactionsEnabled: true,
    );
    return CommerceOperationResult(
      status: CommerceOperationStatus.confirmed,
      snapshot: _snapshot,
      providerHandle: 'purchase_1',
    );
  }

  @override
  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  }) async {
    exchangeProductIds.add(productId);
    exchangeCurrencies.add(payWith);
    _snapshot = CommerceAccountSnapshot(
      state: CommerceAuthorityState.ready,
      astraBalance: payWith == CurrencyKind.premium
          ? (_snapshot.astraBalance ?? 0) - 500
          : _snapshot.astraBalance,
      echoBalance: payWith == CurrencyKind.earned
          ? (_snapshot.echoBalance ?? 0) - 500
          : _snapshot.echoBalance,
      entitlementKeys: {
        ..._snapshot.entitlementKeys,
        CommerceCatalog.sakuraThemeEntitlementKey,
      },
      localizedPrices: _snapshot.localizedPrices,
      transactionsEnabled: true,
    );
    return CommerceOperationResult(
      status: CommerceOperationStatus.confirmed,
      snapshot: _snapshot,
      providerHandle: 'exchange_1',
    );
  }
}
