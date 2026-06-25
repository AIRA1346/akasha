import '../../../models/akasha_item.dart';
import 'work_detail_sanctum_ops.dart';

/// Entity Sanctum — HTML보내기 (workspace UI에서 위임).
abstract final class EntityDetailSanctumOps {
  static Future<WorkDetailHtmlExportResult> exportHtml({
    required AkashaItem item,
    required String bodyMarkdown,
    String? titleOverride,
  }) =>
      WorkDetailSanctumOps.exportHtml(
        item: item,
        bodyMarkdown: bodyMarkdown,
        titleOverride: titleOverride,
      );

  static String htmlExportSnackMessage(WorkDetailHtmlExportResult result) =>
      WorkDetailSanctumOps.htmlExportSnackMessage(result);
}
