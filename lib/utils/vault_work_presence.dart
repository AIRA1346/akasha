import '../models/akasha_item.dart';
import '../services/works_registry.dart';

/// Vault에 아카이브된 작품인지 판별 (R11 Bridge).
abstract final class VaultWorkPresence {
  static Set<String> vaultWorkIds(Iterable<AkashaItem> vaultItems) {
    return vaultItems
        .map((item) => item.workId)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  static bool isArchivedInVault(String workId, Iterable<AkashaItem> vaultItems) {
    if (workId.isEmpty) return false;
    return WorksRegistry.setContainsWorkId(vaultWorkIds(vaultItems), workId);
  }

  static bool isArchivedInVaultItem(AkashaItem item, Iterable<AkashaItem> vaultItems) {
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      return vaultItems.any((v) => v.filePath == item.filePath);
    }
    return isArchivedInVault(item.workId, vaultItems);
  }

  /// 사전 Preview 전용 — 볼트 md 없이 메모리만 있는 상태.
  static bool isRegistryOnlyPreview(
    AkashaItem item,
    Iterable<AkashaItem> vaultItems,
  ) {
    if (item.workId.isEmpty) return false;
    return !isArchivedInVaultItem(item, vaultItems);
  }
}
