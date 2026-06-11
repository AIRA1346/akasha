import 'akasha_item.dart';

enum WorkDragSource { catalogGrid, libraryGrid, searchResult }

/// 포스터 카드 → 서재 드롭 페이로드 (DnD-A)
class WorkDragPayload {
  final String workId;
  final AkashaItem item;
  final WorkDragSource source;

  const WorkDragPayload({
    required this.workId,
    required this.item,
    this.source = WorkDragSource.catalogGrid,
  });
}
