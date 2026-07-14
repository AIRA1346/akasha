import 'dart:ui' as ui;

import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/archiving/timeline_entry.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/screens/home/views/destination_empty_state.dart';
import 'package:akasha/screens/home/views/knowledge_graph_view.dart';
import 'package:akasha/screens/home/views/timeline_view.dart';
import 'package:akasha/services/timeline_vault_loader.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_user_catalog_port.dart';

void main() {
  testWidgets('Graph names existing surfaces without implying a new engine', (
    tester,
  ) async {
    await _pumpSurface(
      tester,
      KnowledgeGraphView(
        vaultItems: const [],
        userCatalog: FakeUserCatalogPort(),
        linkIndex: const _EmptyRecordLinkPort(),
        onOpenWork: (_) {},
        onOpenEntity: (_) {},
        vaultPath: '',
        onOpenCanvas: (_) {},
      ),
    );

    expect(find.text('지식 지도'), findsOneWidget);
    expect(find.text('연결 목록'), findsOneWidget);
    expect(find.textContaining('Canvas'), findsNothing);
    expect(find.textContaining('자동 연결'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('destination-empty-state-graph-vault-required'),
      ),
      findsOneWidget,
    );
    expect(find.text('첫 지식 지도 만들기'), findsNothing);

    final mapTabSemantics = tester.getSemantics(
      find.byKey(const ValueKey('graph-tab-0')),
    );
    expect(mapTabSemantics.label, '지식 지도');
    final mapTabData = mapTabSemantics.getSemanticsData();
    expect(mapTabData.flagsCollection.isButton, isTrue);
    expect(mapTabData.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(mapTabData.hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(find.byKey(const ValueKey('graph-tab-1')));
    await tester.pumpAndSettle();
    final connectionTabSemantics = tester.getSemantics(
      find.byKey(const ValueKey('graph-tab-1')),
    );
    expect(connectionTabSemantics.label, '연결 목록');
    final connectionTabData = connectionTabSemantics.getSemanticsData();
    expect(connectionTabData.flagsCollection.isButton, isTrue);
    expect(connectionTabData.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(connectionTabData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Timeline distinguishes unavailable and empty vault states', (
    tester,
  ) async {
    await _pumpSurface(
      tester,
      TimelineView(
        vaultPath: null,
        vaultItems: const [],
        onOpenWork: (_) {},
        onNewEntry: () {},
        loader: const _EmptyTimelineLoader(),
      ),
    );

    expect(find.text('볼트를 먼저 연결하세요.'), findsOneWidget);
    expect(find.textContaining('로컬 볼트'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('destination-empty-state-timeline-vault-required'),
      ),
      findsOneWidget,
    );

    await _pumpSurface(
      tester,
      TimelineView(
        vaultPath: r'C:\vault',
        vaultItems: const [],
        onOpenWork: (_) {},
        onNewEntry: () {},
        loader: const _EmptyTimelineLoader(),
      ),
    );

    expect(find.text('아직 시간순 기록이 없습니다.'), findsOneWidget);
    expect(find.textContaining('날짜와 시간 순서'), findsOneWidget);
    expect(find.text('첫 기록 작성'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination empty-state geometry is theme invariant at 125%', (
    tester,
  ) async {
    Future<Map<String, Rect>> geometry(
      Size size,
      AkashaThemePreset preset,
    ) async {
      await _pumpSurface(
        tester,
        const DestinationEmptyState(
          stateId: 'geometry',
          icon: Icons.timeline,
          title: '아직 시간순 기록이 없습니다.',
          body: '첫 기록을 남기면 날짜와 시간 순서로 이곳에 모입니다.',
          action: FilledButton(onPressed: null, child: Text('첫 기록 작성')),
        ),
        preset: preset,
        size: size,
        textScale: 1.25,
      );
      return {
        'state': tester.getRect(
          find.byKey(const ValueKey('destination-empty-state-geometry')),
        ),
        'title': tester.getRect(
          find.byKey(const ValueKey('destination-empty-title-geometry')),
        ),
        'body': tester.getRect(
          find.byKey(const ValueKey('destination-empty-body-geometry')),
        ),
      };
    }

    for (final size in const [
      Size(1600, 900),
      Size(1366, 768),
      Size(1024, 720),
    ]) {
      Map<String, Rect>? baseline;
      for (final preset in AkashaThemeRegistry.presets) {
        final current = await geometry(size, preset);
        baseline ??= current;
        expect(current, baseline, reason: '${preset.id} $size');
        expect(tester.takeException(), isNull, reason: '${preset.id} $size');
      }
    }
  });
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget child, {
  AkashaThemePreset preset = AkashaThemeRegistry.classicDarkPreset,
  Size size = const Size(1024, 720),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
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
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

class _EmptyRecordLinkPort implements RecordLinkPort {
  const _EmptyRecordLinkPort();

  @override
  Future<Iterable<String>> incomingEntityIds() async => const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async => const [];

  @override
  Future<RecordLinkSummary> loadSummary() async => RecordLinkSummary.empty;

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async => const [];

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}
}

class _EmptyTimelineLoader extends TimelineVaultLoader {
  const _EmptyTimelineLoader();

  @override
  Future<List<TimelineEntry>> loadFromVault(String? vaultPath) async =>
      const [];
}
