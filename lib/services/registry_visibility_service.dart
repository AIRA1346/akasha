import 'franchise_registry.dart';
import 'user_registry_preferences.dart';
import 'works_registry.dart';

/// 검색 결과에서 원격 사전 항목의 표시 힌트
enum RegistryRemoteHint {
  available,
  siblingTracked,
  hidden,
}

/// 사전 가상 카드·자동 아카이브 표시 여부를 단일 게이트에서 판단합니다.
class RegistryVisibilityService {
  static bool shouldMaterializeVirtual({
    required String workId,
    required Set<String> userWorkIds,
  }) {
    if (workId.isEmpty) return false;

    if (WorksRegistry.setContainsWorkId(userWorkIds, workId)) {
      return false;
    }

    final prefs = UserRegistryPreferences.instance;
    if (prefs.isHidden(workId)) return false;

    // 그리드: IP 1카드 고정 — 형제 매체 가상 카드 억제
    final group = FranchiseRegistry.groupFor(workId);
    if (group != null &&
        FranchiseRegistry.isSiblingCovered(workId, userWorkIds)) {
      return false;
    }

    return true;
  }

  /// 자동 아카이빙: 형제가 없을 때는 primary만, 형제가 있으면 전부 스킵
  static bool shouldAutoArchiveRegistryWork({
    required String workId,
    required Set<String> userWorkIds,
  }) {
    if (!shouldMaterializeVirtual(workId: workId, userWorkIds: userWorkIds)) {
      return false;
    }

    final group = FranchiseRegistry.groupFor(workId);
    if (group == null) return true;

    if (FranchiseRegistry.isSiblingCovered(workId, userWorkIds)) {
      return false;
    }

    final resolved = WorksRegistry.resolveWorkId(workId);
    final primary = WorksRegistry.resolveWorkId(group.primaryWorkId);
    return resolved == primary || workId == group.primaryWorkId;
  }

  /// FusionSearchDialog: 그리드와 달리 검색에서는 표시하되 힌트로 구분
  static RegistryRemoteHint remoteSearchHint({
    required String workId,
    required Set<String> userWorkIds,
  }) {
    if (workId.isEmpty) return RegistryRemoteHint.available;

    final prefs = UserRegistryPreferences.instance;
    if (prefs.isHidden(workId)) return RegistryRemoteHint.hidden;

    final group = FranchiseRegistry.groupFor(workId);
    if (group != null &&
        FranchiseRegistry.isSiblingCovered(workId, userWorkIds)) {
      return RegistryRemoteHint.siblingTracked;
    }

    return RegistryRemoteHint.available;
  }

  static int remoteHintSortOrder(RegistryRemoteHint hint) {
    switch (hint) {
      case RegistryRemoteHint.available:
        return 0;
      case RegistryRemoteHint.siblingTracked:
        return 1;
      case RegistryRemoteHint.hidden:
        return 2;
    }
  }
}
