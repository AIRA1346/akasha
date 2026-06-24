import '../models/akasha_item.dart';
import '../services/works_registry.dart';

/// 작품 링크 탐색용 — 볼트 항목·canonical work_id 정규화.
abstract final class WorkLinkResolution {
  static AkashaItem vaultWorkForLinks(
    AkashaItem work,
    List<AkashaItem> vaultItems,
  ) {
    if (work.filePath != null && work.filePath!.isNotEmpty) return work;
    for (final item in vaultItems) {
      if (WorksRegistry.setContainsWorkId({work.workId}, item.workId)) {
        return item;
      }
      if (work.workId.isEmpty &&
          item.title == work.title &&
          item.category == work.category) {
        return item;
      }
    }
    if (work.workId.isNotEmpty) {
      for (final item in vaultItems) {
        if (item.title == work.title && item.category == work.category) {
          return item;
        }
      }
    }
    return work;
  }

  static bool workIdsReferToSame(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return WorksRegistry.setContainsWorkId({a}, b);
  }

  static Set<String> equivalentWorkIds(
    String workId,
    List<AkashaItem> vaultItems,
  ) {
    final ids = <String>{workId, WorksRegistry.resolveWorkId(workId)};
    for (final item in vaultItems) {
      if (WorksRegistry.setContainsWorkId(ids, item.workId)) {
        ids.add(item.workId);
      }
    }
    return ids;
  }
}
