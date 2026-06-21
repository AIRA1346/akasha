import 'package:akasha/models/entity_browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/widgets/entity_collectible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EntityBrowseCard _sampleCard({
  String title = '나츠키 스바루',
  String creator = '나가월 탓페이',
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
      creator: creator,
      aliases: aliases,
      addedAt: DateTime.utc(2024, 1, 1),
    ),
    isArchived: archived,
    incomingRecordCount: incoming,
    bodyPreview: bodyPreview,
  );
}

void main() {
  testWidgets('shows title, creator, type badge, incoming count in poster layout', (
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
              showPoster: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('나츠키 스바루'), findsAtLeastNWidgets(1));
    expect(find.text('나가월 탓페이'), findsOneWidget);
    expect(find.text('Person'), findsOneWidget);
    expect(find.text('🔗 3'), findsOneWidget);

    await tester.tap(find.byType(EntityCollectibleCard));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows title, creator, type badge, incoming count in fact card layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: EntityCollectibleCard(
              card: _sampleCard(incoming: 5),
              onTap: () {},
              showPoster: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('나츠키 스바루'), findsOneWidget);
    expect(find.text('나가월 탓페이'), findsOneWidget);
    expect(find.text('Person'), findsNWidgets(2)); // Badge in header + footer
    expect(find.text('🔗 5'), findsOneWidget);
  });
}
