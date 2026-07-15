import 'package:akasha/widgets/commerce_center_dialog.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
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
  CommerceAccountSnapshot account = const CommerceAccountSnapshot.disabled(),
  TextScaler? textScaler,
}) {
  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AkashaTheme.dark(),
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
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
