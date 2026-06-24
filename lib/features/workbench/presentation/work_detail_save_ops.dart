import '../../../models/akasha_item.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_archive_ops.dart';
import 'work_detail_draft_ops.dart';

/// WorkDetailWorkspace 저장 플로우 결과.
sealed class WorkDetailSaveFlowResult {
  const WorkDetailSaveFlowResult();
}

class WorkDetailSaveSkipped extends WorkDetailSaveFlowResult {
  const WorkDetailSaveSkipped();
}

class WorkDetailSaveFailed extends WorkDetailSaveFlowResult {
  const WorkDetailSaveFailed(this.error);

  final Object error;
}

class WorkDetailSaveSucceeded extends WorkDetailSaveFlowResult {
  const WorkDetailSaveSucceeded({
    required this.saved,
    required this.stillDirty,
    required this.savedAt,
  });

  final AkashaItem saved;
  final bool stillDirty;
  final DateTime savedAt;
}

/// WorkDetailWorkspace — persist + UI 패치 데이터.
abstract final class WorkDetailSaveOps {
  static bool shouldSkip({
    required bool suppressPersist,
    required bool isSaving,
  }) =>
      suppressPersist || isSaving;

  static Future<WorkDetailSaveFlowResult> run({
    required AkashaItem draft,
    required SanctumPageView pageView,
    required String contentAtSave,
    required String currentFileContent,
    required String currentBodyContent,
  }) async {
    try {
      final outcome = await WorkDetailArchiveOps.persist(
        draft: draft,
        pageView: pageView,
        contentAtSave: contentAtSave,
        currentFileContent: currentFileContent,
        currentBodyContent: currentBodyContent,
      );
      return WorkDetailSaveSucceeded(
        saved: outcome.saved,
        stillDirty: outcome.stillDirty,
        savedAt: DateTime.now(),
      );
    } catch (e) {
      return WorkDetailSaveFailed(e);
    }
  }

  static String? bodyMarkdownAfterSave({
    required AkashaItem saved,
    required bool silent,
    required bool stillDirty,
  }) {
    if (silent || stillDirty) return null;
    return WorkDetailDraftOps.initialBodyMarkdown(saved);
  }
}
