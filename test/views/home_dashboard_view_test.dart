import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
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

void main() {
  testWidgets('HomeDashboardView shows welcome and quick actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: HomeDashboardView(
          vaultItems: const [],
          recentExploreItems: const [],
          userCatalog: _FakeUserCatalog(),
          onOpenWork: (_) {},
          onOpenEntity: (_) {},
          onSearch: () {},
          onTimeline: () {},
          onGoExplore: () {},
          onExploreEntities: () {},
          onVaultSettings: () {},
        ),
      ),
    );

    expect(find.text('안녕하세요, 탐험가님!'), findsOneWidget);
    expect(find.text('계속 탐험하기'), findsOneWidget);
    expect(find.text('빠른 액션'), findsOneWidget);
    expect(
      find.text('아직 탐색 기록이 없습니다. 작품이나 인물을 열면 여기에 표시됩니다.'),
      findsOneWidget,
    );
  });
}
