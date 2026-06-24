import 'dart:io';

/// 외부 편집 감지 시 워크벤치가 취할 동작.
enum VaultDiskChangeAction {
  noOp,
  /// 디스크가 더 최신이고 로컬 dirty — 배너로 사용자에게 선택 요청.
  promptReload,
  /// 디스크가 더 최신이고 clean — 자동 reload.
  reload,
}

/// Work journal vault 파일 mtime 추적·외부 변경 판별.
class WorkDetailVaultDiskSync {
  DateTime? diskMtime;
  bool externalChangePending = false;

  void refreshDiskMtime(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      diskMtime = null;
      return;
    }
    final file = File(filePath);
    diskMtime = file.existsSync() ? file.lastModifiedSync() : null;
  }

  static VaultDiskChangeAction resolveChange({
    required DateTime? knownMtime,
    required DateTime fileMtime,
    required bool isSaving,
    required bool isDirty,
  }) {
    if (isSaving) return VaultDiskChangeAction.noOp;
    if (knownMtime != null && !fileMtime.isAfter(knownMtime)) {
      return VaultDiskChangeAction.noOp;
    }
    if (isDirty) return VaultDiskChangeAction.promptReload;
    return VaultDiskChangeAction.reload;
  }

  VaultDiskChangeAction evaluateFileChange({
    required String? filePath,
    required bool isSaving,
    required bool isDirty,
  }) {
    if (filePath == null || filePath.isEmpty) {
      return VaultDiskChangeAction.noOp;
    }
    final file = File(filePath);
    if (!file.existsSync()) return VaultDiskChangeAction.noOp;

    final action = resolveChange(
      knownMtime: diskMtime,
      fileMtime: file.lastModifiedSync(),
      isSaving: isSaving,
      isDirty: isDirty,
    );
    if (action == VaultDiskChangeAction.promptReload) {
      externalChangePending = true;
    }
    return action;
  }

  void dismissExternalChange(String? filePath) {
    externalChangePending = false;
    refreshDiskMtime(filePath);
  }
}
