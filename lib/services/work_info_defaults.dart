import '../models/akasha_item.dart';
import '../models/enums.dart';
import 'works_registry.dart';

/// 작품정보 패널 「기본값으로」 — work_id 유지
class WorkInfoDefaults {
  WorkInfoDefaults._();

  static void applyRegistryDefaults(AkashaItem item) {
    final resolved = WorksRegistry.resolveWorkId(item.workId);
    final work =
        resolved.isNotEmpty ? WorksRegistry.getWorkById(resolved) : null;

    if (work != null) {
      item.title = work.displayTitle();
      item.creator = work.creator;
      item.releaseYear = work.releaseYear;
      item.tags = List<String>.from(work.tags);
      item.posterPath = null;
    }

    item.rating = 0;
    item.isHallOfFame = false;

    if (item.category.isContentType) {
      item.setWorkStatus(ContentWorkStatus.completed.label);
      item.setMyStatus(ContentMyStatus.notStarted.label);
    } else {
      item.setWorkStatus(GameWorkStatus.released.label);
      item.setMyStatus(GameMyStatus.backlog.label);
    }
  }
}
