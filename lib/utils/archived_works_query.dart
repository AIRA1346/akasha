import '../core/app_vault.dart';
import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../services/franchise_registry.dart';
import '../services/works_registry.dart';

/// 볼트에 아카이브된 작품만 추출 (나의 서재·배지와 동일 기준)
class ArchivedWorksQuery {
  static bool isArchivedItem(AkashaItem item) {
    final vault = AppVault.port;
    if (vault.vaultPath == null) return true;
    return vault.isArchivedInVault(item);
  }

  static List<AkashaItem> archivedItems(List<AkashaItem> allUserItems) {
    return allUserItems.where(isArchivedItem).toList();
  }

  static Set<String> archivedWorkIds(List<AkashaItem> allUserItems) {
    final ids = <String>{};
    for (final item in archivedItems(allUserItems)) {
      if (item.workId.isEmpty) continue;
      ids.add(item.workId);
      final resolved = WorksRegistry.resolveWorkId(item.workId);
      if (resolved.isNotEmpty) ids.add(resolved);
    }
    return ids;
  }

  /// 나의 서재에 표시할 카드 — 사전 전용 가상 카드 제외
  static bool isArchivedBrowseCard(
    BrowseCard card,
    List<AkashaItem> allUserItems,
  ) {
    final franchiseId = card.franchiseId;
    if (franchiseId != null) {
      return allUserItems.any((item) {
        if (FranchiseRegistry.groupFor(item.workId)?.id != franchiseId) {
          return false;
        }
        return isArchivedItem(item);
      });
    }

    final workId = card.item.workId;
    if (workId.isNotEmpty) {
      final archived = archivedWorkIds(allUserItems);
      return archived.contains(workId) ||
          archived.contains(WorksRegistry.resolveWorkId(workId));
    }

    return allUserItems.any(
      (item) =>
          item.title == card.item.title &&
          item.category == card.item.category &&
          isArchivedItem(item),
    );
  }

  static List<BrowseCard> filterArchivedBrowseCards(
    List<BrowseCard> cards,
    List<AkashaItem> allUserItems,
  ) {
    return cards
        .where((c) => isArchivedBrowseCard(c, allUserItems))
        .toList();
  }
}
