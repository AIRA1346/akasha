import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/views/catalog_entity_browse_widgets.dart';
import 'package:akasha/screens/home/views/destination_context_header.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dedicated destinations state distinct product roles', (
    tester,
  ) async {
    const expectations = {
      AppDestination.explore: (
        title: '탐색',
        description: '사전과 아카이브에서 다음 기록 대상을 찾습니다.',
      ),
      AppDestination.library: (
        title: '라이브러리',
        description: '볼트에 보관한 기록과 나만의 서재를 살펴봅니다.',
      ),
      AppDestination.collections: (
        title: '컬렉션',
        description: '작품과 엔티티를 의도적으로 묶은 컬렉션입니다.',
      ),
      AppDestination.graph: (
        title: '그래프',
        description: '직접 만든 지식 지도와 기록에서 파생된 연결을 함께 살펴봅니다.',
      ),
      AppDestination.timeline: (
        title: '타임라인',
        description: '시간순 기록과 메모, 엔티티 기록, 연결 후보를 한곳에서 관리합니다.',
      ),
    };

    for (final entry in expectations.entries) {
      await _pumpHeader(tester, destination: entry.key);
      expect(find.text(entry.value.title), findsOneWidget);
      expect(find.text(entry.value.description), findsOneWidget);
      expect(find.byKey(DestinationContextHeader.headerKey), findsOneWidget);
      expect(tester.takeException(), isNull, reason: entry.key.name);
    }
  });

  testWidgets('Home does not add browse role chrome', (tester) async {
    await _pumpHeader(tester, destination: AppDestination.home);

    expect(find.byKey(DestinationContextHeader.headerKey), findsNothing);
    expect(find.text('destination body'), findsOneWidget);
  });

  testWidgets('Explore entity strip uses localized scoped copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.forPreset(AkashaThemeRegistry.classicDarkPreset),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CatalogEntityBrowseCompactStrip(
            cards: const [],
            highlightEntityId: null,
            onOpenEntity: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('엔티티 둘러보기 · 0'), findsOneWidget);
    expect(find.textContaining('Entity Discovery'), findsNothing);
  });

  testWidgets('context header geometry is theme invariant at 125% text', (
    tester,
  ) async {
    Future<Map<String, Rect>> geometry(
      AppDestination destination,
      Size size,
      AkashaThemePreset preset,
    ) async {
      await _pumpHeader(
        tester,
        destination: destination,
        preset: preset,
        textScale: 1.25,
        surfaceSize: size,
      );
      return {
        'header': tester.getRect(
          find.byKey(DestinationContextHeader.headerKey),
        ),
        'title': tester.getRect(find.byKey(DestinationContextHeader.titleKey)),
        'description': tester.getRect(
          find.byKey(DestinationContextHeader.descriptionKey),
        ),
      };
    }

    for (final destination in const [
      AppDestination.explore,
      AppDestination.graph,
      AppDestination.timeline,
    ]) {
      for (final size in const [
        Size(1600, 900),
        Size(1366, 768),
        Size(1024, 720),
      ]) {
        Map<String, Rect>? baseline;
        for (final preset in AkashaThemeRegistry.presets) {
          final current = await geometry(destination, size, preset);
          baseline ??= current;
          expect(
            current,
            baseline,
            reason: '${destination.name} ${preset.id} $size',
          );
        }
      }
    }
  });
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required AppDestination destination,
  AkashaThemePreset preset = AkashaThemeRegistry.classicDarkPreset,
  double textScale = 1,
  Size surfaceSize = const Size(1024, 720),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
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
        body: DestinationContextFrame(
          destination: destination,
          child: const Center(child: Text('destination body')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
