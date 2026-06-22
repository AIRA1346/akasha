import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/entity_dashboard_preview_panel.dart';
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
  testWidgets('EntityDashboardPreviewPanel shows record CTA', (tester) async {
    final entity = UserCatalogEntity.userLocal(
      entityId: 'ent_test',
      type: EntityAnchorType.person,
      title: '에밀리아',
      subtype: MediaCategory.animation,
      addedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          body: EntityDashboardPreviewPanel(
            entity: entity,
            userCatalog: _FakeUserCatalog(),
            linkIndex: _FakeLinkIndex(),
            vaultItems: const [],
            onClose: () {},
            onOpenDetail: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('에밀리아'), findsWidgets);
    expect(find.text('기록하기 >'), findsOneWidget);
    expect(find.text('연결된 작품'), findsOneWidget);
    expect(find.textContaining('아직 연결된 작품'), findsOneWidget);
  });
}
