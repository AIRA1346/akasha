import 'package:akasha/models/entity_browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/widgets/entity_collectible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EntityBrowseCard _sampleCard({
  String title = '나츠키 스바루',
  List<String> aliases = const ['스바루'],
  String bodyPreview = '평범한 고등학생이던 그는…',
  bool archived = true,
  int incoming = 3,
}) {
  return EntityBrowseCard(
    entity: UserCatalogEntity(
      entityId: 'ent_person_test',
      entityType: UserCatalogEntity.entityTypePerson,
      subtype: MediaCategory.manga,
      title: title,
      aliases: aliases,
      addedAt: DateTime.utc(2024, 1, 1),
    ),
    isArchived: archived,
    incomingRecordCount: incoming,
    bodyPreview: bodyPreview,
  );
}

void main() {
  testWidgets('shows title, alias, preview, type badge, incoming count', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: EntityCollectibleCard(
              card: _sampleCard(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('나츠키 스바루'), findsOneWidget);
    expect(find.text('스바루'), findsOneWidget);
    expect(find.text('평범한 고등학생이던 그는…'), findsOneWidget);
    expect(find.text('Person'), findsOneWidget);
    expect(find.text('🔗 연결 3'), findsOneWidget);
    expect(find.textContaining('ent_person'), findsNothing);

    await tester.tap(find.byType(EntityCollectibleCard));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows placeholder when body preview empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: EntityCollectibleCard(
              card: _sampleCard(bodyPreview: '', archived: false, incoming: 0),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('(메모 없음)'), findsOneWidget);
    expect(find.text('🔗 연결'), findsNothing);
  });
}
