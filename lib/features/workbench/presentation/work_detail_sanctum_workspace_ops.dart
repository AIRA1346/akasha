import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/work_info_defaults.dart';
import '../../../services/poster_url_localizer.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_sanctum_ops.dart';
import 'widgets/work_sanctum_section_editor.dart';
import '../../../services/sanctum_body_templates.dart';

/// WorkDetailWorkspace — Sanctum UI 액션 (포스터·템플릿·기본값·HTML).
abstract final class WorkDetailSanctumWorkspaceOps {
  static const resetSnackMessage =
      '사전 기본값으로 되돌렸습니다. (work_id는 유지)';

  static void resetToDefaults({
    required AkashaItem item,
    required TextEditingController titleCtrl,
    required TextEditingController posterUrlCtrl,
    required TextEditingController bodyCtrl,
    required void Function(List<String> tags, Set<String> registryTags) onTags,
    required void Function(
      double rating,
      String workStatus,
      String myStatus,
      bool hallOfFame,
    ) onDraftFields,
    required VoidCallback markDirty,
    required void Function(String message) showSnack,
  }) {
    WorkInfoDefaults.applyRegistryDefaults(item);
    titleCtrl.text = item.title;
    onTags(
      List<String>.from(item.tags),
      WorkDetailDraftOps.loadRegistryTags(item.workId),
    );
    posterUrlCtrl.text = item.posterPath ?? '';
    bodyCtrl.text = WorkDetailDraftOps.initialBodyMarkdown(item);
    final fields = WorkDetailDraftOps.draftFieldsFromItem(item);
    onDraftFields(
      fields.rating,
      fields.workStatus,
      fields.myStatus,
      fields.hallOfFame,
    );
    markDirty();
    showSnack(resetSnackMessage);
  }

  static Future<void> openPosterCorrection({
    required BuildContext context,
    required AkashaItem item,
    required TextEditingController posterUrlCtrl,
    required VoidCallback onApplied,
    required VoidCallback onDirty,
    required VoidCallback scheduleAutoSave,
  }) async {
    final selected = await WorkDetailSanctumOps.pickPosterUrl(
      context: context,
      title: item.title,
      category: item.category,
    );
    if (selected == null) return;
    final resolved = await PosterUrlLocalizer.applyWithSnackBar(
      selected,
      showSnack: (message) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
    posterUrlCtrl.text = resolved;
    onApplied();
    onDirty();
    scheduleAutoSave();
  }

  static Future<String?> applyBodyTemplate({
    required BuildContext context,
    required SanctumBodyTemplate template,
    required TextEditingController bodyCtrl,
    required AkashaItem item,
    required WorkSanctumSectionEditorState? sectionEditor,
    required VoidCallback markDirty,
  }) =>
      WorkDetailSanctumOps.applyBodyTemplate(
        context: context,
        template: template,
        bodyCtrl: bodyCtrl,
        item: item,
        sectionEditor: sectionEditor,
        markDirty: markDirty,
      );

  static Future<void> exportHtml({
    required bool isArchivedInVault,
    required AkashaItem item,
    required TextEditingController titleCtrl,
    required TextEditingController bodyCtrl,
    required void Function(String message) showSnack,
  }) async {
    if (!isArchivedInVault) {
      showSnack('HTML보내기 전에 md를 저장해 주세요.');
      return;
    }

    WorkDetailDraftOps.syncBodyFromEditor(item, bodyCtrl);
    final title = titleCtrl.text.trim();
    final result = await WorkDetailSanctumOps.exportHtml(
      item: item,
      bodyMarkdown: bodyCtrl.text,
      titleOverride: title.isNotEmpty ? title : null,
    );
    showSnack(WorkDetailSanctumOps.htmlExportSnackMessage(result));
  }
}
