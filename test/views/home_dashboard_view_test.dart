import 'dart:async';

import 'package:akasha/config/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/home_dashboard_view.dart';
import 'package:akasha/theme/akasha_theme.dart';

class _FakeUserCatalog implements UserCatalogPort {
  _FakeUserCatalog([this.entities = const []]);

  final List<UserCatalogEntity> entities;

  @override
  List<UserCatalogEntity> get all => entities;

  @override
  Stream<void> get onChanged => const Stream.empty();

  @override
  Future<void> load() async {}

  @override
  UserCatalogEntity? getById(String entityId) => null;

  @override
  Future<void> remove(String entityId) async {}

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) => const [];

  @override
  Future<void> upsert(UserCatalogEntity entity) async {}
}

class _FakeLinkIndex implements RecordLinkPort {
  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async => const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async => const [];

  @override
  Future<Iterable<String>> incomingEntityIds() async => const [];
}

Widget _wrap(HomeDashboardView child) {
  return MaterialApp(theme: AkashaTheme.dark(), home: child);
}

HomeDashboardView _dashboard({
  VoidCallback? onSearch,
  List<AkashaItem> vaultItems = const [],
  List<AkashaItem> recentExploreItems = const [],
  List<UserCatalogEntity> catalogEntities = const [],
  int collectionCount = 0,
}) {
  return HomeDashboardView(
    vaultItems: vaultItems,
    recentExploreItems: recentExploreItems,
    collectionCount: collectionCount,
    userCatalog: _FakeUserCatalog(catalogEntities),
    linkIndex: _FakeLinkIndex(),
    onPreviewWork: (_) {},
    onPreviewEntity: (_) {},
    onSearch: onSearch ?? () {},
    onGoExplore: () {},
    onGoExploreEntities: (_) {},
    onGoKnowledgeGraph: () {},
    onTimeline: () {},
  );
}

void main() {
  testWidgets('HomeDashboardView v1 shows hero, continue, quick actions', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_dashboard()));

    expect(find.text('기록하고, 연결하고, 발견하세요'), findsOneWidget);
    expect(
      find.text('작품, 사람, 사건, 개념을 기록하면 연결이 생기고 새로운 발견으로 이어집니다.'),
      findsOneWidget,
    );
    expect(find.text('탐험 시작하기'), findsNothing);
    expect(find.text('계속 탐험하기'), findsOneWidget);
    expect(find.text('빠른 액션'), findsOneWidget);
    expect(find.text('작품 검색'), findsOneWidget);
    expect(find.text('인물 탐색'), findsOneWidget);

    if (FeatureFlags.showKnowledgeGraph) {
      expect(find.text('연결 맵'), findsOneWidget);
    } else {
      expect(find.text('전체 탐색'), findsOneWidget);
    }

    expect(find.text('탐험을 시작하면 최근에 본 작품과 인물이 여기에 표시됩니다.'), findsOneWidget);

    // v1: post-v1 blocks hidden via FeatureFlags
    if (!FeatureFlags.showDiscoveryHome) {
      expect(find.text('오늘의 연결'), findsNothing);
      expect(find.text('최근 발견'), findsNothing);
      expect(find.text('발견의 여정'), findsNothing);
    }
    if (!FeatureFlags.showTimeline) {
      expect(find.text('기록'), findsNothing);
    }

    expect(find.text('안녕하세요, 탐험가님!'), findsNothing);
    expect(find.text('검색으로 탐험 시작'), findsNothing);
    expect(find.text('[[wiki]]'), findsNothing);
  });

  testWidgets(
    'empty archive Hero offers a real start action without fake stats',
    (tester) async {
      var searchCount = 0;

      await tester.pumpWidget(_wrap(_dashboard(onSearch: () => searchCount++)));

      expect(
        find.byKey(const ValueKey('home-dashboard-hero-stats')),
        findsNothing,
      );
      expect(find.text('첫 기록 시작'), findsOneWidget);

      await tester.tap(find.text('첫 기록 시작'));
      expect(searchCount, 1);
    },
  );

  testWidgets('archive Hero reports only values derived from local data', (
    tester,
  ) async {
    final item = ContentItem(
      workId: 'work-1',
      title: 'Archive work',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      tags: const ['Fantasy', ' favorite '],
    );
    final entity = UserCatalogEntity.userLocal(
      entityId: 'person-1',
      type: EntityAnchorType.person,
      title: 'Archive person',
      tags: const ['fantasy', 'Character'],
    );

    await tester.pumpWidget(
      _wrap(
        _dashboard(
          vaultItems: [item],
          catalogEntities: [entity],
          collectionCount: 2,
        ),
      ),
    );

    void expectStat(String id, String label, String value) {
      final tile = find.byKey(ValueKey<String>('home-dashboard-hero-stat-$id'));
      expect(tile, findsOneWidget);
      expect(
        find.descendant(of: tile, matching: find.text(label)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text(value)),
        findsOneWidget,
      );
    }

    expectStat('records', '아카이브 기록', '1');
    expectStat('entities', '엔티티', '1');
    expectStat('collections', '컬렉션', '2');
    expectStat('tags', '태그', '3');
    expect(find.text('첫 기록 시작'), findsNothing);
  });
}
