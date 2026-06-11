import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../services/franchise_registry.dart';
import '../services/markdown_parser.dart';
import '../services/works_registry.dart';
import '../utils/archived_works_query.dart';

/// Case D — fusion 카드 담기 범위 (대표 매체 vs IP 전체)
class FranchiseLibraryScope {
  /// 볼트에 아카이브된 franchise 멤버가 2개 이상이면 IP 전체 옵션 표시
  static bool offersEntireIpOption(
    BrowseCard card,
    List<AkashaItem> vaultItems,
  ) {
    return archivedWorkIdsForEntireIp(card, vaultItems).length > 1;
  }

  static String representativeWorkId(BrowseCard card) {
    final id = card.item.workId;
    if (id.isNotEmpty) {
      final resolved = WorksRegistry.resolveWorkId(id);
      return resolved.isNotEmpty ? resolved : id;
    }
    return MarkdownParser.ensureWorkId(card.item);
  }

  static List<String> workIdsForSingleFormat(BrowseCard card) {
    return [representativeWorkId(card)];
  }

  /// 볼트에 md 있는 franchise 멤버 workId (정규화·중복 제거)
  static List<String> archivedWorkIdsForEntireIp(
    BrowseCard card,
    List<AkashaItem> vaultItems,
  ) {
    final franchiseId = card.franchiseId;
    if (franchiseId == null) {
      return workIdsForSingleFormat(card);
    }

    final seen = <String>{};
    final result = <String>[];
    for (final item in vaultItems) {
      if (item.workId.isEmpty) continue;
      if (!ArchivedWorksQuery.isArchivedItem(item)) continue;
      final group = FranchiseRegistry.groupFor(item.workId);
      if (group?.id != franchiseId) continue;

      final resolved = WorksRegistry.resolveWorkId(item.workId);
      final stored = resolved.isNotEmpty ? resolved : item.workId;
      if (seen.add(stored)) result.add(stored);
    }
    return result;
  }

  /// 배지·담김 표시용 — 카드에 연관된 모든 workId
  static List<String> relatedWorkIds(
    BrowseCard card,
    List<AkashaItem> vaultItems,
  ) {
    if (card.franchiseId != null) {
      final ip = archivedWorkIdsForEntireIp(card, vaultItems);
      if (ip.isNotEmpty) return ip;
    }
    return workIdsForSingleFormat(card);
  }
}
