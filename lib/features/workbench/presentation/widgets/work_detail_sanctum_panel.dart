import 'package:flutter/material.dart';

import '../../../../core/archiving/record_link.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/entity_link_selection.dart';
import '../../../../models/enums.dart';
import '../../../../services/sanctum_body_templates.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../widgets/sanctum/sanctum_archive_toolbar.dart';
import '../../../../widgets/sanctum_page_panel.dart';
import '../widgets/workbench_panel_styles.dart';
import 'work_sanctum_section_editor.dart';

/// Work 워크벤치 — Sanctum 3열 (섹션 편집·템플릿·완성도).
class WorkDetailSanctumPanel extends StatelessWidget {
  const WorkDetailSanctumPanel({
    super.key,
    required this.pageView,
    required this.onViewChanged,
    required this.titleController,
    required this.onTitleChanged,
    required this.sectionEditorKey,
    required this.bodyController,
    required this.fileController,
    required this.previewMarkdown,
    this.mdFilePath,
    required this.isDirty,
    required this.isSaving,
    required this.externalChangePending,
    required this.onReloadFromDisk,
    required this.onDismissExternalChange,
    this.lastSavedAt,
    required this.onBodyChanged,
    required this.onFileChanged,
    required this.onOpenFileView,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
    this.userCatalog,
    this.onOpenLinkedEntity,
    required this.category,
    required this.archiveCompletionBodyRaw,
    required this.canExportHtml,
    required this.onApplyTemplate,
    required this.onExportHtml,
    required this.saveLabel,
    required this.onSave,
    this.showAddToLibrary = false,
    required this.libraryLabel,
    this.onAddToLibrary,
    required this.onReset,
    required this.canDeleteMd,
    this.onDeleteArchive,
  });

  final SanctumPageView pageView;
  final ValueChanged<SanctumPageView> onViewChanged;
  final TextEditingController titleController;
  final VoidCallback onTitleChanged;
  final GlobalKey<WorkSanctumSectionEditorState> sectionEditorKey;
  final TextEditingController bodyController;
  final TextEditingController fileController;
  final String previewMarkdown;
  final String? mdFilePath;
  final bool isDirty;
  final bool isSaving;
  final bool externalChangePending;
  final VoidCallback onReloadFromDisk;
  final VoidCallback onDismissExternalChange;
  final DateTime? lastSavedAt;
  final VoidCallback onBodyChanged;
  final VoidCallback onFileChanged;
  final VoidCallback onOpenFileView;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;
  final UserCatalogPort? userCatalog;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final MediaCategory category;
  final String archiveCompletionBodyRaw;
  final bool canExportHtml;
  final ValueChanged<SanctumBodyTemplate> onApplyTemplate;
  final VoidCallback onExportHtml;
  final String saveLabel;
  final VoidCallback onSave;
  final bool showAddToLibrary;
  final String libraryLabel;
  final VoidCallback? onAddToLibrary;
  final VoidCallback onReset;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AkashaColors.workbenchEditor,
      child: SanctumPagePanel(
        view: pageView,
        onViewChanged: onViewChanged,
        headerTitle: '작품 정보 편집',
        titleController: titleController,
        onTitleChanged: onTitleChanged,
        sectionLayout: true,
        sectionEditorKey: sectionEditorKey,
        previewMarkdown: previewMarkdown,
        mdFilePath: mdFilePath,
        isDirty: isDirty,
        isSaving: isSaving,
        externalChangePending: externalChangePending,
        onReloadFromDisk: onReloadFromDisk,
        onDismissExternalChange: onDismissExternalChange,
        lastSavedAt: lastSavedAt,
        bodyController: bodyController,
        fileController: fileController,
        onBodyChanged: onBodyChanged,
        onFileChanged: onFileChanged,
        onOpenFileView: onOpenFileView,
        onWikiLinkTap: onWikiLinkTap,
        onRequestEntityLink: onRequestEntityLink,
        userCatalog: userCatalog,
        onOpenLinkedEntity: onOpenLinkedEntity,
        archiveCompletionBodyRaw: archiveCompletionBodyRaw,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SanctumArchiveToolbar(
              category: category,
              canExportHtml: canExportHtml,
              onApplyTemplate: onApplyTemplate,
              onExportHtml: onExportHtml,
            ),
            WorkbenchSaveActions(
              isSaving: isSaving,
              isDirty: isDirty,
              lastSavedAt: lastSavedAt,
              saveLabel: saveLabel,
              onSave: onSave,
              showAddToLibrary: showAddToLibrary,
              libraryLabel: libraryLabel,
              onAddToLibrary: onAddToLibrary,
              showReset: true,
              onReset: onReset,
              canDeleteMd: canDeleteMd,
              onDeleteArchive: onDeleteArchive,
            ),
          ],
        ),
      ),
    );
  }
}
