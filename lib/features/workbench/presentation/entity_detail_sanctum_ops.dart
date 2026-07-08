import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../widgets/web_image_search_dialog.dart';
import 'work_detail_sanctum_ops.dart';

import '../../../generated/l10n/app_localizations.dart';

/// Entity Sanctum — HTML보내기·포스터 (workspace UI에서 위임).
abstract final class EntityDetailSanctumOps {
  static Future<WorkDetailHtmlExportResult> exportHtml({
    required AkashaItem item,
    required String bodyMarkdown,
    String? titleOverride,
    AppLocalizations? l10n,
  }) =>
      WorkDetailSanctumOps.exportHtml(
        item: item,
        bodyMarkdown: bodyMarkdown,
        titleOverride: titleOverride,
        l10n: l10n,
      );

  static String htmlExportSnackMessage(WorkDetailHtmlExportResult result, [AppLocalizations? l10n]) =>
      WorkDetailSanctumOps.htmlExportSnackMessage(result, l10n);

  static Future<String?> pickPosterUrl({
    required BuildContext context,
    required String title,
    required MediaCategory category,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (searchCtx) => WebImageSearchDialog(
        initialQuery: title,
        category: category,
      ),
    );
  }
}
