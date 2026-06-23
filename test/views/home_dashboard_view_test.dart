import 'dart:async';

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
  @override
  List<UserCatalogEntity> get all => const [];

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
  }) =>
      const [];

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

void main() {
  testWidgets('HomeDashboardView shows hero and exploration sections', (tester) async {
    var searchTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: HomeDashboardView(
          vaultItems: const [],
          recentExploreItems: const [],
          userCatalog: _FakeUserCatalog(),
          linkIndex: _FakeLinkIndex(),
          onPreviewWork: (_) {},
          onPreviewEntity: (_) {},
          onSearch: () => searchTapped = true,
          onVaultSettings: () {},
        ),
      ),
    );

    expect(find.text('기록하고, 연결하고, 발견하세요'), findsOneWidget);
    expect(
      find.text(
        '작품, 사람, 사건, 개념을 기록하면 연결이 생기고 새로운 발견으로 이어집니다.',
      ),
      findsOneWidget,
    );
    expect(find.text('탐험 시작하기'), findsOneWidget);
    expect(find.text('계속 탐험하기'), findsOneWidget);
    expect(find.text('오늘의 연결'), findsOneWidget);
    expect(find.text('최근 발견'), findsOneWidget);
    expect(find.text('최근 기록'), findsOneWidget);
    expect(find.text('안녕하세요, 탐험가님!'), findsNothing);
    expect(find.text('빠른 액션'), findsNothing);
    expect(find.text('검색으로 탐험 시작'), findsNothing);
    expect(find.text('검색으로 더 보기'), findsNothing);
    expect(
      find.text('탐험을 시작하면 최근에 본 작품과 인물이 여기에 표시됩니다.'),
      findsOneWidget,
    );
    expect(find.text('[[wiki]]'), findsNothing);

    await tester.tap(find.text('탐험 시작하기'));
    expect(searchTapped, isTrue);
  });
}
