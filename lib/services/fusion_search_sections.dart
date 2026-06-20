import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../models/akasha_item.dart';
import 'fusion_search_service.dart';

/// Fusion 검색 결과 type별 섹션 — Archive-First R1.
class FusionHitGroups {
  const FusionHitGroups({
    required this.localWork,
    required this.localEntity,
    required this.catalogWork,
    required this.catalogEntityOnly,
    required this.globalWork,
    required this.globalEntity,
  });

  final List<AkashaItem> localWork;
  final List<EntityJournalEntry> localEntity;
  final List<FusionRegistryHit> catalogWork;
  final List<FusionRegistryHit> catalogEntityOnly;
  final List<FusionRegistryHit> globalWork;
  final List<FusionRegistryHit> globalEntity;

  bool get hasRegistryHits =>
      catalogWork.isNotEmpty ||
      catalogEntityOnly.isNotEmpty ||
      globalWork.isNotEmpty ||
      globalEntity.isNotEmpty;

  bool get hasAnyHits =>
      localWork.isNotEmpty ||
      localEntity.isNotEmpty ||
      hasRegistryHits;
}

abstract final class FusionSearchSections {
  static FusionHitGroups group({
    required List<AkashaItem> localWork,
    required List<EntityJournalEntry> localEntity,
    required List<FusionRegistryHit> catalogHits,
    required List<FusionRegistryHit> globalHits,
  }) {
    return FusionHitGroups(
      localWork: localWork,
      localEntity: localEntity,
      catalogWork: catalogHits
          .where((h) => h.entityType == EntityAnchorType.work)
          .toList(),
      catalogEntityOnly: catalogHits
          .where((h) => h.catalogOnly && h.entityType != EntityAnchorType.work)
          .toList(),
      globalWork: globalHits
          .where((h) => h.entityType == EntityAnchorType.work)
          .toList(),
      globalEntity: globalHits
          .where((h) => h.entityType != EntityAnchorType.work)
          .toList(),
    );
  }
}
