import '../../../models/akasha_item.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_save_ops.dart';
import 'work_detail_save_ui_patch.dart';

/// WorkDetailWorkspace 저장 오케스트레이션 결과.
sealed class WorkDetailSaveOrchestrationResult {
  const WorkDetailSaveOrchestrationResult();
}

class WorkDetailSaveOrchestrationSkipped extends WorkDetailSaveOrchestrationResult {
  const WorkDetailSaveOrchestrationSkipped();
}

class WorkDetailSaveOrchestrationFailed extends WorkDetailSaveOrchestrationResult {
  const WorkDetailSaveOrchestrationFailed(this.error);

  final Object error;
}

class WorkDetailSaveOrchestrationSucceeded extends WorkDetailSaveOrchestrationResult {
  const WorkDetailSaveOrchestrationSucceeded({
    required this.patch,
    required this.stillDirty,
    required this.saved,
  });

  final WorkDetailSaveUiPatch patch;
  final bool stillDirty;
  final AkashaItem saved;
}

/// WorkDetailWorkspace — autosave 취소·persist·UI 패치 생성.
abstract final class WorkDetailSaveOrchestrator {
  static Future<WorkDetailSaveOrchestrationResult> run({
    required bool suppressPersist,
    required bool isSaving,
    required void Function() cancelAutosave,
    required AkashaItem draft,
    required SanctumPageView pageView,
    required String contentAtSave,
    required String currentFileContent,
    required String currentBodyContent,
    required SanctumPageView currentPageView,
    required bool silent,
    required bool switchToPreview,
  }) async {
    if (WorkDetailSaveOps.shouldSkip(
      suppressPersist: suppressPersist,
      isSaving: isSaving,
    )) {
      return const WorkDetailSaveOrchestrationSkipped();
    }

    cancelAutosave();
    final result = await WorkDetailSaveOps.run(
      draft: draft,
      pageView: pageView,
      contentAtSave: contentAtSave,
      currentFileContent: currentFileContent,
      currentBodyContent: currentBodyContent,
    );

    return switch (result) {
      WorkDetailSaveSkipped() => const WorkDetailSaveOrchestrationSkipped(),
      WorkDetailSaveFailed(:final error) =>
        WorkDetailSaveOrchestrationFailed(error),
      WorkDetailSaveSucceeded result => WorkDetailSaveOrchestrationSucceeded(
          patch: WorkDetailSaveUiPatch.fromSucceeded(
            result: result,
            currentPageView: currentPageView,
            silent: silent,
            switchToPreview: switchToPreview,
          ),
          stillDirty: result.stillDirty,
          saved: result.saved,
        ),
    };
  }
}
