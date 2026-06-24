import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/features/workbench/presentation/entity_detail_draft_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/widgets/sanctum_page_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initialPageView opens body when journal empty', () {
    expect(
      EntityDetailDraftOps.initialPageView(''),
      SanctumPageView.body,
    );
    expect(
      EntityDetailDraftOps.initialPageView('  '),
      SanctumPageView.body,
    );
    expect(
      EntityDetailDraftOps.initialPageView('note'),
      SanctumPageView.preview,
    );
  });

  test('serializeFile without journal uses entity fields', () {
    final entity = UserCatalogEntity(
      entityId: 'ent_draft',
      entityType: UserCatalogEntity.entityTypePerson,
      title: '인물',
      subtype: MediaCategory.manga,
      addedAt: DateTime.utc(2024, 6, 1),
    );
    final text = EntityDetailDraftOps.serializeFile(
      entity: entity,
      journal: null,
      body: '본문',
      tags: const ['tag-a'],
      posterPath: 'https://example.com/p.jpg',
    );
    expect(text, contains('ent_draft'));
    expect(text, contains('본문'));
  });

  test('buildEntityItem maps journal poster and tags', () {
    final entity = UserCatalogEntity(
      entityId: 'ent_item',
      entityType: UserCatalogEntity.entityTypePerson,
      title: 'Title',
      subtype: MediaCategory.manga,
      addedAt: DateTime.utc(2024, 1, 1),
      tags: const ['catalog'],
    );
    final item = EntityDetailDraftOps.buildEntityItem(entity, null);
    expect(item.entityId, 'ent_item');
    expect(item.tags, const ['catalog']);
    expect(item.entityType, EntityAnchorType.person);
  });
}
