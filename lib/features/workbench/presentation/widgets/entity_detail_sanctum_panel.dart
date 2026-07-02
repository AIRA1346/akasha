import 'package:flutter/material.dart';

import '../../../../core/archiving/record_link.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/entity_link_selection.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../widgets/sanctum/sanctum_archive_toolbar.dart';
import '../../../../widgets/sanctum_page_panel.dart';
import '../widgets/workbench_panel_styles.dart';

/// Entity 워크벤치 — Sanctum 3열 (미리보기·본문·.md).
class EntityDetailSanctumPanel extends StatelessWidget {
  const EntityDetailSanctumPanel({
    super.key,
    required this.pageView,
    required this.onViewChanged,
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
    required this.hasJournal,
    required this.saveLabel,
    required this.onSave,
    required this.onExportHtml,
    this.showAddToLibrary = false,
    required this.libraryLabel,
    this.onAddToLibrary,
    this.onDeleteArchive,
  });

  final SanctumPageView pageView;
  final ValueChanged<SanctumPageView> onViewChanged;
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
  )?
  onRequestEntityLink;
  final UserCatalogPort? userCatalog;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final bool hasJournal;
  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onExportHtml;
  final bool showAddToLibrary;
  final String libraryLabel;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onDeleteArchive;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.akashaPalette.workbenchEditor,
      child: SanctumPagePanel(
        view: pageView,
        onViewChanged: onViewChanged,
        headerTitle: '기록 본문',
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
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SanctumArchiveToolbar(
              showTemplates: false,
              canExportHtml: hasJournal,
              onExportHtml: onExportHtml,
              dense: true,
            ),
            WorkbenchSaveActions(
              isSaving: isSaving,
              isDirty: isDirty,
              lastSavedAt: lastSavedAt,
              saveLabel: saveLabel,
              explicitSaveLabel: saveLabel,
              onSave: onSave,
              showAddToLibrary: showAddToLibrary,
              libraryLabel: libraryLabel,
              onAddToLibrary: onAddToLibrary,
              canDeleteMd: hasJournal,
              onDeleteArchive: onDeleteArchive,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
