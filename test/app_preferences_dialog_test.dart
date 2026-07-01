import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akasha/config/catalog_locale.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/screens/home/dialogs/app_preferences_dialog.dart';
import 'package:akasha/services/catalog_locale_preferences.dart';
import 'package:akasha/services/user_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogLocaleScope.setCurrent(CatalogLocale.ko);
    UserPreferences.uiScaleListenable.value = UserPreferences.defaultUiScale;
  });

  Widget harness({Locale locale = const Locale('ko'), VoidCallback? onQuit}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showAppPreferencesDialog(
                context,
                onOpenAppTheme: () {},
                onOpenVaultSettings: () {},
                onQuit: onQuit,
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('shows desktop preferences actions', (tester) async {
    await UserPreferences.setUiScale(1.2);
    await tester.pumpWidget(harness());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('환경설정'), findsOneWidget);
    expect(find.text('표시 언어'), findsOneWidget);
    expect(find.text('한국어'), findsOneWidget);
    expect(find.text('표시 배율'), findsOneWidget);
    expect(find.text('120%'), findsOneWidget);
    expect(find.text('앱 테마'), findsOneWidget);
    expect(find.text('볼트 설정'), findsOneWidget);
    expect(find.text('종료'), findsOneWidget);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows English preferences copy', (tester) async {
    CatalogLocaleScope.setCurrent(CatalogLocale.en);
    await tester.pumpWidget(harness(locale: const Locale('en')));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Display language'), findsOneWidget);
    expect(find.text('Display scale'), findsOneWidget);
    expect(find.text('App theme'), findsOneWidget);
    expect(find.text('Vault settings'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
  });

  testWidgets('language dropdown persists selection', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(CatalogLocaleScope.current, CatalogLocale.en);
    expect(await CatalogLocalePreferences.loadInitial(), CatalogLocale.en);
  });

  testWidgets('quit button calls provided callback', (tester) async {
    var quitCalled = false;
    await tester.pumpWidget(harness(onQuit: () => quitCalled = true));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료'));
    await tester.pumpAndSettle();

    expect(quitCalled, isTrue);
    expect(find.text('환경설정'), findsNothing);
  });
}
