import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_insight_loader.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_lower_section.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_quick_actions_section.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLinkIndex implements RecordLinkPort {
  _FakeLinkIndex(this.summary);

  final RecordLinkSummary summary;

  @override
  Future<RecordLinkSummary> loadSummary() async => summary;

  @override
  Future<Iterable<String>> incomingEntityIds() async => const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async => const [];

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async => const [];

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}
}

class _FailingLinkIndex extends _FakeLinkIndex {
  _FailingLinkIndex() : super(RecordLinkSummary.empty);

  @override
  Future<RecordLinkSummary> loadSummary() =>
      Future<RecordLinkSummary>.error(StateError('link summary unavailable'));
}

class _CountingLinkIndex extends _FakeLinkIndex {
  _CountingLinkIndex() : super(RecordLinkSummary.empty);

  int loadCount = 0;

  @override
  Future<RecordLinkSummary> loadSummary() async {
    loadCount++;
    return summary;
  }
}

class _FakeRecordIndex extends RecordSummaryIndexService {
  _FakeRecordIndex(this.records);

  final List<VaultRecordSummary> records;

  @override
  Future<List<VaultRecordSummary>> load(String vaultPath) async => records;
}

class _FailingRecordIndex extends RecordSummaryIndexService {
  @override
  Future<List<VaultRecordSummary>> load(String vaultPath) =>
      Future<List<VaultRecordSummary>>.error(
        StateError('record index unavailable'),
      );
}

VaultRecordSummary _record({
  required String id,
  required String title,
  required RecordKind kind,
  DateTime? addedAt,
  DateTime? updatedAt,
}) {
  return VaultRecordSummary(
    id: id,
    recordKind: kind,
    entityType: kind == RecordKind.entityJournal ? 'person' : 'work',
    title: title,
    relativePath: 'records/$id.md',
    addedAt: addedAt,
    updatedAt: updatedAt,
  );
}

Future<Map<String, Rect>> _pumpLowerSection(
  WidgetTester tester, {
  required double width,
  AkashaThemePreset preset = AkashaThemeRegistry.classicDarkPreset,
  double textScale = 1,
  RecordLinkPort? linkIndex,
  RecordSummaryIndexService? recordIndex,
}) async {
  final now = DateTime(2026, 7, 14, 12);
  await tester.binding.setSurfaceSize(Size(width + 64, 900));
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: width,
              child: HomeDashboardLowerSection(
                linkIndex:
                    linkIndex ??
                    _FakeLinkIndex(
                      const RecordLinkSummary(
                        totalLinkCount: 12,
                        linkedRecordCount: 5,
                        connectedEntityCount: 3,
                      ),
                    ),
                linkIndexRevision: 1,
                vaultPath: 'C:/vault',
                recordIndex:
                    recordIndex ??
                    _FakeRecordIndex([
                      _record(
                        id: 'work-1',
                        title: '오늘 추가한 작품',
                        kind: RecordKind.workJournal,
                        addedAt: DateTime(2026, 7, 14, 10),
                        updatedAt: DateTime(2026, 7, 14, 10),
                      ),
                      _record(
                        id: 'entity-1',
                        title: '오늘 수정한 인물',
                        kind: RecordKind.entityJournal,
                        addedAt: DateTime(2026, 7, 10, 9),
                        updatedAt: DateTime(2026, 7, 14, 11),
                      ),
                    ]),
                now: now,
                onSearch: () {},
                onExploreEntities: () {},
                onGoExplore: () {},
                onGoKnowledgeGraph: () {},
                onTimeline: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  return {
    'layout': tester.getRect(find.byKey(HomeDashboardLowerSection.layoutKey)),
    'quick': tester.getRect(
      find.byKey(HomeDashboardQuickActionsSection.panelKey),
    ),
    'connection': tester.getRect(
      find.byKey(HomeDashboardLowerSection.connectionPanelKey),
    ),
    'activity': tester.getRect(
      find.byKey(HomeDashboardLowerSection.activityPanelKey),
    ),
  };
}

void main() {
  test(
    'activity loader uses actual same-day timestamps and update meaning',
    () async {
      final now = DateTime(2026, 7, 14, 12);
      final data = await loadHomeArchiveActivity(
        vaultPath: 'C:/vault',
        recordIndex: _FakeRecordIndex([
          _record(
            id: 'added',
            title: 'Added',
            kind: RecordKind.workJournal,
            addedAt: DateTime(2026, 7, 14, 10),
            updatedAt: DateTime(2026, 7, 14, 10),
          ),
          _record(
            id: 'updated',
            title: 'Updated',
            kind: RecordKind.entityJournal,
            addedAt: DateTime(2026, 7, 10, 10),
            updatedAt: DateTime(2026, 7, 14, 11),
          ),
          _record(
            id: 'yesterday',
            title: 'Yesterday',
            kind: RecordKind.freeformJournal,
            updatedAt: DateTime(2026, 7, 13, 23),
          ),
        ]),
        now: now,
      );

      expect(data.vaultAvailable, isTrue);
      expect(data.todayCount, 2);
      expect(data.items.map((item) => item.recordId), ['updated', 'added']);
      expect(data.items.first.kind, HomeArchiveActivityKind.updated);
      expect(data.items.last.kind, HomeArchiveActivityKind.added);
    },
  );

  test(
    'activity loader distinguishes an unavailable vault from an empty day',
    () async {
      final unavailable = await loadHomeArchiveActivity(
        vaultPath: null,
        recordIndex: _FakeRecordIndex(const []),
        now: DateTime(2026, 7, 14),
      );
      final empty = await loadHomeArchiveActivity(
        vaultPath: 'C:/vault',
        recordIndex: _FakeRecordIndex(const []),
        now: DateTime(2026, 7, 14),
      );

      expect(unavailable.vaultAvailable, isFalse);
      expect(empty.vaultAvailable, isTrue);
      expect(empty.items, isEmpty);
    },
  );

  for (final width in const [600.0, 900.0, 1200.0]) {
    testWidgets('lower Home grid renders at width $width and 125% text', (
      tester,
    ) async {
      await _pumpLowerSection(tester, width: width, textScale: 1.25);

      expect(find.text('12개의 연결'), findsWidgets);
      expect(find.text('오늘 추가한 작품'), findsOneWidget);
      expect(find.text('오늘 수정한 인물'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Classic Dark and Midnight Blue keep lower grid geometry', (
    tester,
  ) async {
    final classic = await _pumpLowerSection(tester, width: 1200);
    final midnight = await _pumpLowerSection(
      tester,
      width: 1200,
      preset: AkashaThemeRegistry.midnightBluePreset,
    );

    expect(midnight, classic);
  });

  testWidgets('lower Home panels expose honest error states', (tester) async {
    await _pumpLowerSection(
      tester,
      width: 1200,
      linkIndex: _FailingLinkIndex(),
      recordIndex: _FailingRecordIndex(),
    );

    expect(find.text('연결 요약을 잠시 불러올 수 없습니다.'), findsOneWidget);
    expect(find.text('오늘의 기록 활동을 잠시 불러올 수 없습니다.'), findsOneWidget);
  });

  testWidgets('changing Vault reloads the connection summary', (tester) async {
    final linkIndex = _CountingLinkIndex();
    var vaultPath = 'C:/vault-a';

    Widget buildApp() => MaterialApp(
      theme: AkashaTheme.forPreset(AkashaThemeRegistry.classicDarkPreset),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeDashboardLowerSection(
            linkIndex: linkIndex,
            linkIndexRevision: 0,
            vaultPath: vaultPath,
            recordIndex: _FakeRecordIndex(const []),
            now: DateTime(2026, 7, 14),
            onSearch: () {},
            onExploreEntities: () {},
            onGoExplore: () {},
            onGoKnowledgeGraph: () {},
            onTimeline: () {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(linkIndex.loadCount, 1);

    vaultPath = 'C:/vault-b';
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(linkIndex.loadCount, 2);
  });
}
