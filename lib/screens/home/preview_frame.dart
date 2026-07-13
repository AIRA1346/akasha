import '../../models/akasha_item.dart';
import '../../models/user_catalog_entity.dart';

/// Shell Preview의 단일 선택 계약.
///
/// UX-2에서는 Work/Entity를 실제로 렌더링하고, 나머지 target은 이후 surface가
/// 같은 상태 경계를 재사용할 수 있도록 payload 계약만 고정한다.
sealed class PreviewTarget {
  const PreviewTarget();
}

final class NoPreviewTarget extends PreviewTarget {
  const NoPreviewTarget._();

  static const instance = NoPreviewTarget._();
}

final class WorkPreviewTarget extends PreviewTarget {
  const WorkPreviewTarget(this.item);

  final AkashaItem item;
}

final class EntityPreviewTarget extends PreviewTarget {
  const EntityPreviewTarget(this.entity);

  final UserCatalogEntity entity;
}

final class CollectionPreviewTarget extends PreviewTarget {
  const CollectionPreviewTarget(this.collectionId);

  final String collectionId;
}

final class RelationPreviewTarget extends PreviewTarget {
  const RelationPreviewTarget({required this.sourceId, required this.targetId});

  final String sourceId;
  final String targetId;
}

final class TimelineRecordPreviewTarget extends PreviewTarget {
  const TimelineRecordPreviewTarget(this.recordId);

  final String recordId;
}

/// Preview→Workbench 진입 시 복귀용 스냅샷 (current + back stack).
class PreviewReturnSnapshot {
  const PreviewReturnSnapshot({required this.current, required this.backStack});

  final PreviewTarget current;
  final List<PreviewTarget> backStack;
}
