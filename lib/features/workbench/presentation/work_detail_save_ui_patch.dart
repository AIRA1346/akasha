import '../../../models/akasha_item.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_save_ops.dart';

/// WorkDetailWorkspace — 저장 성공 후 UI·상태 패치.
class WorkDetailSaveUiPatch {
  const WorkDetailSaveUiPatch({
    required this.item,
    required this.titleText,
    required this.posterText,
    required this.bodyText,
    required this.pageView,
    required this.draftTags,
    required this.registryTags,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.savedAt,
    required this.stillDirty,
  });

  final AkashaItem item;
  final String? titleText;
  final String? posterText;
  final String? bodyText;
  final SanctumPageView? pageView;
  final List<String> draftTags;
  final Set<String> registryTags;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final DateTime savedAt;
  final bool stillDirty;

  static WorkDetailSaveUiPatch fromSucceeded({
    required WorkDetailSaveSucceeded result,
    required SanctumPageView currentPageView,
    required bool silent,
    required bool switchToPreview,
  }) {
    final saved = result.saved;
    final bodyMarkdown = WorkDetailSaveOps.bodyMarkdownAfterSave(
      saved: saved,
      silent: silent,
      stillDirty: result.stillDirty,
    );
    final fields = WorkDetailDraftOps.draftFieldsFromItem(saved);
    return WorkDetailSaveUiPatch(
      item: saved,
      titleText: bodyMarkdown != null ? saved.title : null,
      posterText: bodyMarkdown != null ? (saved.posterPath ?? '') : null,
      bodyText: bodyMarkdown,
      pageView: bodyMarkdown != null && switchToPreview
          ? SanctumPageView.preview
          : null,
      draftTags: List<String>.from(saved.tags),
      registryTags: WorkDetailDraftOps.loadRegistryTags(saved.workId),
      draftRating: fields.rating,
      draftWorkStatus: fields.workStatus,
      draftMyStatus: fields.myStatus,
      draftHallOfFame: fields.hallOfFame,
      savedAt: result.savedAt,
      stillDirty: result.stillDirty,
    );
  }
}
