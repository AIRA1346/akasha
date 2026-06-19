import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import 'fusion_search_service.dart';

/// Phase B — Fusion 검색 결과 type별 섹션 그룹.
class FusionHitGroups {
  const FusionHitGroups({
    required this.local,
    required this.catalogWork,
    required this.catalogEntity,
    required this.globalWork,
    required this.globalEntity,
  });

  final List<AkashaItem> local;
  final List<FusionRegistryHit> catalogWork;
  final List<FusionRegistryHit> catalogEntity;
  final List<FusionRegistryHit> globalWork;
  final List<FusionRegistryHit> globalEntity;

  bool get hasRegistryHits =>
      catalogWork.isNotEmpty ||
      catalogEntity.isNotEmpty ||
      globalWork.isNotEmpty ||
      globalEntity.isNotEmpty;
}

abstract final class FusionSearchSections {
  static FusionHitGroups group({
    required List<AkashaItem> local,
    required List<FusionRegistryHit> catalogHits,
    required List<FusionRegistryHit> globalHits,
  }) {
    return FusionHitGroups(
      local: local,
      catalogWork: catalogHits
          .where((h) => h.entityType == EntityAnchorType.work)
          .toList(),
      catalogEntity: catalogHits
          .where((h) => h.entityType != EntityAnchorType.work)
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
