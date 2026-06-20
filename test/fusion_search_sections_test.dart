import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/registry_work.dart';
import 'package:akasha/services/fusion_search_sections.dart';
import 'package:akasha/services/fusion_search_service.dart';

RegistryWork _work(String id, {String title = 't'}) => RegistryWork(
      workId: id,
      title: title,
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
    );

FusionRegistryHit _hit({
  required String id,
  required EntityAnchorType type,
  FusionRegistrySource source = FusionRegistrySource.userCatalog,
  bool catalogOnly = false,
}) {
  return FusionRegistryHit(
    work: _work(id, title: id),
    source: source,
    entityType: type,
    catalogOnly: catalogOnly,
  );
}

void main() {
  test('FusionSearchSections splits catalog and global by entity type', () {
    final groups = FusionSearchSections.group(
      localWork: const [],
      localEntity: const [],
      catalogHits: [
        _hit(id: 'wk_u_aaaaaaaa', type: EntityAnchorType.work),
        _hit(
          id: 'pe_u_bbbbbbbb',
          type: EntityAnchorType.person,
          catalogOnly: true,
        ),
        _hit(
          id: 'co_u_cccccccc',
          type: EntityAnchorType.concept,
          catalogOnly: true,
        ),
      ],
      globalHits: [
        _hit(
          id: 'wk_000000001',
          type: EntityAnchorType.work,
          source: FusionRegistrySource.globalRegistry,
        ),
        _hit(
          id: 'pe_000000001',
          type: EntityAnchorType.person,
          source: FusionRegistrySource.globalRegistry,
        ),
      ],
    );

    expect(groups.catalogWork.length, 1);
    expect(groups.catalogEntityOnly.length, 2);
    expect(groups.globalWork.length, 1);
    expect(groups.globalEntity.length, 1);
    expect(groups.hasRegistryHits, isTrue);
  });
}
