import '../../../models/akasha_item.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_draft_ops.dart';

/// WorkDetailWorkspace — item → 컨트롤러·draft 필드 동기화 스냅샷.
class WorkDetailItemHydration {
  const WorkDetailItemHydration({
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
  });

  final AkashaItem item;
  final String titleText;
  final String posterText;
  final String bodyText;
  final SanctumPageView pageView;
  final List<String> draftTags;
  final Set<String> registryTags;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;

  static WorkDetailItemHydration fromItem(
    AkashaItem item, {
    required bool resetPageView,
    bool preserveBodyEditor = false,
    String? currentBodyText,
    SanctumPageView? currentPageView,
  }) {
    final bodyText = preserveBodyEditor && currentBodyText != null
        ? currentBodyText
        : WorkDetailDraftOps.initialBodyMarkdown(item);
    if (preserveBodyEditor && currentBodyText != null) {
      WorkDetailDraftOps.syncBodyFromText(item, currentBodyText);
    }
    final pageView = resetPageView
        ? WorkDetailDraftOps.initialPageView(item)
        : (currentPageView ?? WorkDetailDraftOps.initialPageView(item));
    final fields = WorkDetailDraftOps.draftFieldsFromItem(item);
    return WorkDetailItemHydration(
      item: item,
      titleText: item.title,
      posterText: item.posterPath ?? '',
      bodyText: bodyText,
      pageView: pageView,
      draftTags: List<String>.from(item.tags),
      registryTags: WorkDetailDraftOps.loadRegistryTags(item.workId),
      draftRating: fields.rating,
      draftWorkStatus: fields.workStatus,
      draftMyStatus: fields.myStatus,
      draftHallOfFame: fields.hallOfFame,
    );
  }
}
