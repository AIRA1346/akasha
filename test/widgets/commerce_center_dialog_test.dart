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
    expect(find.text('500 Astra 또는 500 Echo'), findsNWidgets(3));
    expect(find.text('출시 준비 중'), findsNWidgets(3));
    expect(find.text('Steam에서 구매'), findsNothing);
    expect(find.text('Astra 0'), findsNothing);

    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();

    expect(find.text('아스트라'), findsOneWidget);
    expect(find.text('에코'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('클래식 다크'), findsOneWidget);
    expect(find.text('미드나이트 블루'), findsOneWidget);
    expect(find.text('벚꽃'), findsNothing);
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
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();

    expect(find.text('120'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('벚꽃'), findsOneWidget);
    expect(find.text('보유 중'), findsOneWidget);
    expect(find.text('소유권 확인 불가'), findsNothing);
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
    expect(find.text('500 Astra 또는 500 Echo'), findsNWidgets(3));

    await tester.tap(find.text('인벤토리'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
