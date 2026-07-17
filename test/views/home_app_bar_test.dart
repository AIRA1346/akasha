import 'dart:ui' show Tristate;

import 'package:akasha/config/feature_flags.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/screens/home/home_app_bar.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'HomeAppBar exposes settings without placeholder currency or avatar',
    (tester) async {
      var settingsTapCount = 0;
      await tester.pumpWidget(
        _testApp(
          appBar: _appBar(
            onSettings: () => settingsTapCount++,
            onCatalogInbox: () {},
            catalogContributionCount: 2,
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byTooltip('Preferences'), findsOneWidget);
      expect(find.byTooltip('More tools'), findsOneWidget);
      expect(find.byTooltip('Catalog suggestions inbox'), findsOneWidget);
      expect(find.byTooltip('Local vault settings'), findsOneWidget);

      final settings = find.byKey(const ValueKey('home-utility-settings'));
      final settingsSize = tester.getSize(settings);
      expect(settingsSize.width, greaterThanOrEqualTo(44));
      expect(settingsSize.height, greaterThanOrEqualTo(44));

      final cluster = find.byKey(const ValueKey('home-utility-cluster'));
      final clusterRow = tester.widget<Row>(cluster);
      expect(clusterRow.children, hasLength(2));
      expect(
        find.byKey(const ValueKey('home-utility-commerce')),
        findsOneWidget,
      );
      expect(find.text('Astra'), findsNothing);
      expect(find.text('Echo'), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.account_circle_outlined), findsNothing);

      await tester.tap(settings);
      expect(settingsTapCount, 1);
    },
  );

  testWidgets('HomeAppBar overflow menu lists grouped tools', (tester) async {
    await tester.pumpWidget(
      _testApp(appBar: _appBar(vaultLinked: true, onTimelineCapture: () {})),
    );

    await tester.tap(find.byTooltip('More tools'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sync global works catalog (long-press for settings)'),
      findsOneWidget,
    );
    expect(find.text('Import AI markdown'), findsOneWidget);
    expect(find.text('Copy AI prompt templates'), findsOneWidget);
    if (FeatureFlags.showTimeline) {
      expect(find.text('Timeline note'), findsOneWidget);
    } else {
      expect(find.text('Timeline note'), findsNothing);
    }
  });

  testWidgets('optional utility slots keep currency, settings, avatar order', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1400, 800));

    const currencyKey = ValueKey('test-currency-slot');
    const avatarKey = ValueKey('test-avatar-slot');
    await tester.pumpWidget(
      _testApp(
        appBar: _appBar(
          currencySlot: const SizedBox(
            key: currencyKey,
            width: 96,
            height: 44,
            child: Center(child: Text('Astra 120')),
          ),
          avatarSlot: const SizedBox(
            key: avatarKey,
            width: 44,
            height: 44,
            child: Icon(Icons.account_circle_outlined),
          ),
        ),
      ),
    );

    final cluster = find.byKey(const ValueKey('home-utility-cluster'));
    final clusterRow = tester.widget<Row>(cluster);
    expect(clusterRow.children, hasLength(4));
    expect(clusterRow.children[0].key, currencyKey);
    expect(clusterRow.children[1].key, const ValueKey('home-utility-commerce'));
    expect(clusterRow.children[2].key, const ValueKey('home-utility-settings'));
    expect(clusterRow.children[3].key, avatarKey);

    expect(
      tester.getCenter(find.byKey(currencyKey)).dx,
      lessThan(
        tester
            .getCenter(find.byKey(const ValueKey('home-utility-commerce')))
            .dx,
      ),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('home-utility-commerce'))).dx,
      lessThan(
        tester
            .getCenter(find.byKey(const ValueKey('home-utility-settings')))
            .dx,
      ),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('home-utility-settings'))).dx,
      lessThan(tester.getCenter(find.byKey(avatarKey)).dx),
    );
  });

  testWidgets('commerce utility button reports and renders selected state', (
    tester,
  ) async {
    var commerceTapCount = 0;
    await tester.pumpWidget(
      _testApp(appBar: _appBar(onCommerce: () => commerceTapCount++)),
    );

    final commerce = find.byKey(const ValueKey('home-utility-commerce'));
    expect(commerce, findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(
      tester.getSemantics(commerce).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    await tester.tap(commerce);
    expect(commerceTapCount, 1);

    await tester.pumpWidget(
      _testApp(
        appBar: _appBar(
          onCommerce: () => commerceTapCount++,
          commerceSelected: true,
        ),
      ),
    );
    expect(find.byIcon(Icons.storefront), findsOneWidget);
    expect(
      tester.getSemantics(commerce).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('1024 width and 125 percent text scale do not overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 768));

    await tester.pumpWidget(
      _testApp(
        textScaler: const TextScaler.linear(1.25),
        appBar: _appBar(
          currencySlot: const SizedBox(
            width: 112,
            height: 44,
            child: Center(child: Text('Astra 120 · Echo 45')),
          ),
          avatarSlot: const SizedBox.square(
            dimension: 44,
            child: Icon(Icons.account_circle_outlined),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-shell-app-bar'))).height,
      64,
    );
    expect(find.byTooltip('Preferences'), findsOneWidget);
  });
}

Widget _testApp({required PreferredSizeWidget appBar, TextScaler? textScaler}) {
  final scaffold = Scaffold(appBar: appBar);
  return MaterialApp(
    theme: AkashaTheme.dark(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: textScaler == null
        ? scaffold
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: scaffold,
          ),
  );
}

HomeAppBar _appBar({
  bool vaultLinked = false,
  VoidCallback? onTimelineCapture,
  VoidCallback? onCatalogInbox,
  int catalogContributionCount = 0,
  VoidCallback? onSettings,
  VoidCallback? onCommerce,
  bool commerceSelected = false,
  Widget? currencySlot,
  Widget? avatarSlot,
}) {
  return HomeAppBar(
    isSidebarOpen: true,
    isSyncing: false,
    vaultLinked: vaultLinked,
    onToggleSidebar: () {},
    onClipboardImport: () {},
    onTimelineCapture: onTimelineCapture,
    onSync: () {},
    onSyncSettings: () {},
    onPromptTemplates: () {},
    onVaultSettings: () {},
    onClearRegistryCache: () {},
    onCatalogInbox: onCatalogInbox,
    catalogContributionCount: catalogContributionCount,
    onSettings: onSettings ?? () {},
    onCommerce: onCommerce ?? () {},
    commerceSelected: commerceSelected,
    currencySlot: currencySlot,
    avatarSlot: avatarSlot,
  );
}
