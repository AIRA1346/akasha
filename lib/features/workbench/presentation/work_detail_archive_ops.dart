import '../../../models/akasha_item.dart';
import '../../../screens/detail/detail_archive_save.dart';
import '../../../services/file_service.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'workbench_vault.dart';

class WorkDetailSaveOutcome {
  const WorkDetailSaveOutcome({
    required this.saved,
    required this.stillDirty,
  });

  final AkashaItem saved;
  final bool stillDirty;
}

/// WorkDetailWorkspace 저장·아카이브 상태 (E2-6 확장).
abstract final class WorkDetailArchiveOps {
  static bool isArchivedInVault(AkashaItem item) =>
      WorkbenchVault.port.isArchivedInVault(item);

  static bool isArchived(AkashaItem item) {
    final vault = WorkbenchVault.port;
    return isArchivedInVault(item) ||
        vault.inMemoryCache.containsKey(AkashaFileService.cacheKeyFor(item));
  }

  static Future<WorkDetailSaveOutcome> persist({
    required AkashaItem draft,
    required SanctumPageView pageView,
    required String contentAtSave,
    required String currentFileContent,
    required String currentBodyContent,
  }) async {
    final saved = await DetailArchiveSave.save(draft);
    final stillDirty = pageView == SanctumPageView.file
        ? currentFileContent != contentAtSave
        : currentBodyContent != contentAtSave;
    return WorkDetailSaveOutcome(saved: saved, stillDirty: stillDirty);
  }

  static Future<bool> deleteFromVault(AkashaItem item) =>
      WorkbenchVault.port.deleteItem(item);

  static String saveSuccessMessage(AkashaItem saved) {
    final hasVault = WorkbenchVault.port.vaultPath != null;
    return hasVault
        ? '"${saved.title}" md 파일을 저장했습니다.'
        : '"${saved.title}"을(를) 임시 저장했습니다.';
  }
}
