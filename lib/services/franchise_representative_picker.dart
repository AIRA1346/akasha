import '../models/akasha_item.dart';
import '../models/franchise_group.dart';
import 'file_service.dart';
import 'franchise_registry.dart';
import 'works_registry.dart';
/// 프랜차이즈 IP당 대표 item 선택 + 로컬 검색 dedupe (단일 규칙)
class FranchiseRepresentativePicker {
  /// 아카이브 우선 → primary workId → 최근 추가 순
  static AkashaItem pickBest(
    List<AkashaItem> candidates,
    FranchiseGroup group, {
    AkashaFileService? vault,
  }) {
    if (candidates.isEmpty) {
      throw ArgumentError.value(
        candidates,
        'candidates',
        'must not be empty',
      );
    }
    if (candidates.length == 1) return candidates.first;

    final service = vault ?? AkashaFileService();
    final primaryResolved = WorksRegistry.resolveWorkId(group.primaryWorkId);

    final archived =
        candidates.where((c) => service.isArchivedInVault(c)).toList();
    if (archived.isNotEmpty) {
      archived.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return archived.first;
    }

    for (final item in candidates) {
      final resolved = WorksRegistry.resolveWorkId(item.workId);
      if (resolved == primaryResolved || item.workId == group.primaryWorkId) {
        return item;
      }
    }

    final sorted = List<AkashaItem>.from(candidates)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.first;
  }

  /// 그룹 전체 풀에서 대표 item 선택 (후보 없으면 null)
  static AkashaItem? pickForGroup(
    FranchiseGroup group,
    List<AkashaItem> pool, {
    AkashaFileService? vault,
  }) {
    final candidates = pool.where((item) {
      return FranchiseRegistry.groupFor(item.workId)?.id == group.id;
    }).toList();
    if (candidates.isEmpty) return null;
    return pickBest(candidates, group, vault: vault);
  }

  /// 로컬 검색 결과 — IP당 1행
  static List<AkashaItem> dedupeLocalByFranchise(List<AkashaItem> items) {
    final emittedFranchises = <String>{};
    final result = <AkashaItem>[];

    for (final item in items) {
      final group = FranchiseRegistry.groupFor(item.workId);
      if (group == null) {
        result.add(item);
        continue;
      }

      if (emittedFranchises.contains(group.id)) continue;
      emittedFranchises.add(group.id);

      final franchiseItems = items
          .where(
            (i) => FranchiseRegistry.groupFor(i.workId)?.id == group.id,
          )
          .toList();
      result.add(pickBest(franchiseItems, group));
    }

    return result;
  }
}
