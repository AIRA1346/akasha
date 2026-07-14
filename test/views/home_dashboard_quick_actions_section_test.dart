import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_quick_actions_section.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Map<String, Rect>> _pumpSection(
  WidgetTester tester, {
  required double width,
  AkashaThemePreset preset = AkashaThemeRegistry.classicDarkPreset,
  double textScale = 1,
  VoidCallback? onSearch,
  VoidCallback? onEntities,
  VoidCallback? onExplore,
}) async {
  await tester.binding.setSurfaceSize(Size(width + 64, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: AkashaTheme.forPreset(preset),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: HomeDashboardQuickActionsSection(
              onSearch: onSearch ?? () {},
              onExploreEntities: onEntities ?? () {},
              onGoExplore: onExplore ?? () {},
              onGoKnowledgeGraph: () {},
              onTimeline: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);

  return {
    'panel': tester.getRect(
      find.byKey(HomeDashboardQuickActionsSection.panelKey),
    ),
    'grid': tester.getRect(
      find.byKey(HomeDashboardQuickActionsSection.gridKey),
    ),
    'search': tester.getRect(
      find.byKey(HomeDashboardQuickActionsSection.actionKey('search')),
    ),
    'entities': tester.getRect(
      find.byKey(HomeDashboardQuickActionsSection.actionKey('entities')),
    ),
    'explore': tester.getRect(
      find.byKey(HomeDashboardQuickActionsSection.actionKey('explore')),
    ),
  };
}

void main() {
  for (final width in const [420.0, 800.0, 1200.0]) {
    testWidgets('Quick Actions adapts at width $width with 125% text', (
      tester,
    ) async {
      await _pumpSection(tester, width: width, textScale: 1.25);

      expect(find.text('작품 검색'), findsOneWidget);
      expect(find.text('인물 탐색'), findsOneWidget);
      expect(find.text('전체 탐색'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Classic Dark and Midnight Blue keep action geometry', (
    tester,
  ) async {
    final classic = await _pumpSection(tester, width: 1200);
    final midnight = await _pumpSection(
      tester,
      width: 1200,
      preset: AkashaThemeRegistry.midnightBluePreset,
    );

    expect(midnight, classic);
  });

  testWidgets('actions invoke their existing navigation callbacks', (
    tester,
  ) async {
    var searchCount = 0;
    var entityCount = 0;
    var exploreCount = 0;
    await _pumpSection(
      tester,
      width: 1200,
      onSearch: () => searchCount++,
      onEntities: () => entityCount++,
      onExplore: () => exploreCount++,
    );

    await tester.tap(
      find.byKey(HomeDashboardQuickActionsSection.actionKey('search')),
    );
    await tester.tap(
      find.byKey(HomeDashboardQuickActionsSection.actionKey('entities')),
    );
    await tester.tap(
      find.byKey(HomeDashboardQuickActionsSection.actionKey('explore')),
    );

    expect((searchCount, entityCount, exploreCount), (1, 1, 1));
  });

  testWidgets('first action is keyboard reachable and activatable', (
    tester,
  ) async {
    var searchCount = 0;
    await _pumpSection(tester, width: 1200, onSearch: () => searchCount++);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(searchCount, 1);
  });
}
