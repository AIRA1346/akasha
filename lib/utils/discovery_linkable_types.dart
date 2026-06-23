import '../core/archiving/entity_anchor.dart';
import '../models/user_catalog_entity.dart';
import '../services/entity_archive_service.dart';

/// Discovery 파이프라인에서 연결·이웃·후보로 취급하는 Entity 타입 (R10).
abstract final class DiscoveryLinkableTypes {
  static const Set<EntityAnchorType> types = {
    EntityAnchorType.person,
    EntityAnchorType.event,
    EntityAnchorType.concept,
    EntityAnchorType.place,
    EntityAnchorType.organization,
  };

  static bool includes(EntityAnchorType type) => types.contains(type);

  /// Picker·LinkCandidate에서 catalog 엔티티가 연결 가능한지.
  static bool isCatalogLinkable(UserCatalogEntity entity) {
    if (entity.isWorkEntity) return false;
    if (!includes(entity.anchorType)) return false;
    if (EntityArchiveService.usesArchiveFirstFlow(entity.anchorType)) {
      return true;
    }
    return entity.anchorType == EntityAnchorType.place ||
        entity.anchorType == EntityAnchorType.organization;
  }

  static String relationLabel(EntityAnchorType type) => switch (type) {
        EntityAnchorType.person => '인물',
        EntityAnchorType.event => '사건',
        EntityAnchorType.concept => '개념',
        EntityAnchorType.place => '장소',
        EntityAnchorType.organization => '조직',
        _ => '엔티티',
      };
}
