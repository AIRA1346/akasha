import 'work_detail_vault_sync.dart';

/// Vault 디스크 변경 이벤트 → UI/ reload 분기.
abstract final class WorkbenchVaultDiskOps {
  static Future<void> handleChange({
    required VaultDiskChangeAction action,
    required bool mounted,
    required void Function() promptRebuild,
    required Future<void> Function({required bool silent}) reloadFromDisk,
    bool reloadSilent = true,
  }) async {
    switch (action) {
      case VaultDiskChangeAction.noOp:
        return;
      case VaultDiskChangeAction.promptReload:
        if (mounted) promptRebuild();
      case VaultDiskChangeAction.reload:
        await reloadFromDisk(silent: reloadSilent);
    }
  }
}
