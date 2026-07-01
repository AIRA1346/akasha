import 'package:flutter/material.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/archiving/entity_anchor.dart';
import '../../../../core/archiving/record_link.dart';
import '../../../../core/archiving/same_day_record_ref.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/entity_link_selection.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../utils/work_link_neighbors.dart';
import '../../../../services/sanctum_body_templates.dart';
import '../../../../widgets/sanctum_page_panel.dart';
import '../work_detail_connections_panel.dart';
import '../work_detail_info_panel.dart';
import 'work_detail_sanctum_panel.dart';
import 'work_sanctum_section_editor.dart';
import 'workbench_breadcrumb.dart';
import '../../../../utils/app_l10n.dart';

/// Work 워크벤치 — breadcrumb + 3열 본문.
class WorkDetailWorkspaceBody extends StatelessWidget {
  const WorkDetailWorkspaceBody({
    super.key,
    required this.item,
    required this.preview,
    required this.infoPanelWidth,
    required this.infoPanelLocked,
    required this.vaultLinked,
    required this.titleCtrl,
    required this.posterUrlCtrl,
    required this.bodyCtrl,
    required this.fileCtrl,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.draftTags,
    required this.registryTags,
    required this.isSaving,
    required this.isArchived,
    required this.isArchivedInVault,
    required this.isDirty,
    required this.lastSavedAt,
    required this.showAddToLibrary,
    required this.loadingIncoming,
    required this.incomingPaths,
    required this.staleLabelRecordCount,
    required this.loadingSameDay,
    required this.sameDayRefs,
    required this.linkNeighbors,
    required this.loadingLinkNeighbors,
    required this.pageView,
    required this.sectionEditorKey,
    required this.previewBodyMarkdown,
    required this.externalChangePending,
    required this.onClose,
    required this.onGoKnowledgeGraph,
    required this.userCatalog,
    required this.onWikiLinkTap,
    required this.onRequestEntityLink,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
    required this.onRefreshIncoming,
    required this.onOpenIncoming,
    required this.onOpenSameDay,
    required this.onMarkDirty,
    required this.onDraftRatingChanged,
    required this.onDraftWorkStatusChanged,
    required this.onDraftMyStatusChanged,
    required this.onDraftHallOfFameChanged,
    required this.onDraftTagsChanged,
    required this.onPosterTap,
    required this.onResetToDefaults,
    required this.onSaveArchive,
    required this.onAddToLibrary,
    required this.onDeleteArchive,
    required this.onOpenLinkedEntity,
    required this.onOpenLinkedWork,
    required this.onFocusSanctum,
    required this.onViewChanged,
    required this.onTitleChanged,
    required this.onReloadFromDisk,
    required this.onDismissExternalChange,
    required this.onBodyChanged,
    required this.onFileChanged,
    required this.onOpenFileView,
    required this.onApplyTemplate,
    required this.onExportHtml,
    required this.onAddEntityLink,
    required this.onAddWorkLink,
  });

  final AkashaItem item;
  final AkashaItem preview;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final bool vaultLinked;
  final TextEditingController titleCtrl;
  final TextEditingController posterUrlCtrl;
  final TextEditingController bodyCtrl;
  final TextEditingController fileCtrl;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final List<String> draftTags;
  final Set<String> registryTags;
  final bool isSaving;
  final bool isArchived;
  final bool isArchivedInVault;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final bool showAddToLibrary;
  final bool loadingIncoming;
  final List<String> incomingPaths;
  final int staleLabelRecordCount;
  final bool loadingSameDay;
  final List<SameDayRecordRef> sameDayRefs;
  final WorkLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final SanctumPageView pageView;
  final GlobalKey<WorkSanctumSectionEditorState> sectionEditorKey;
  final String previewBodyMarkdown;
  final bool externalChangePending;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )?
  onRequestEntityLink;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final VoidCallback onRefreshIncoming;
  final Future<void> Function(String path) onOpenIncoming;
  final Future<void> Function(SameDayRecordRef ref) onOpenSameDay;
  final VoidCallback onMarkDirty;
  final ValueChanged<double> onDraftRatingChanged;
  final ValueChanged<String> onDraftWorkStatusChanged;
  final ValueChanged<String> onDraftMyStatusChanged;
  final ValueChanged<bool> onDraftHallOfFameChanged;
  final ValueChanged<List<String>> onDraftTagsChanged;
  final Future<void> Function() onPosterTap;
  final VoidCallback onResetToDefaults;
  final Future<void> Function({bool silent, bool switchToPreview})
  onSaveArchive;
  final Future<void> Function() onAddToLibrary;
  final Future<void> Function() onDeleteArchive;
  final void Function(UserCatalogEntity entity) onOpenLinkedEntity;
  final void Function(AkashaItem work) onOpenLinkedWork;
  final VoidCallback onFocusSanctum;
  final ValueChanged<SanctumPageView> onViewChanged;
  final VoidCallback onTitleChanged;
  final Future<void> Function() onReloadFromDisk;
  final VoidCallback onDismissExternalChange;
  final VoidCallback onBodyChanged;
  final VoidCallback onFileChanged;
  final VoidCallback onOpenFileView;
  final Future<void> Function(SanctumBodyTemplate template) onApplyTemplate;
  final Future<void> Function() onExportHtml;
  final Future<void> Function(EntityAnchorType type)? onAddEntityLink;
  final Future<void> Function()? onAddWorkLink;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final titleLabel = titleCtrl.text.trim().isNotEmpty
        ? titleCtrl.text.trim()
        : item.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (FeatureFlags.showWorkbenchBreadcrumb)
          WorkbenchBreadcrumb(
            segments: [
              WorkbenchBreadcrumbSegment(
                label: l10n?.breadcrumbLibrary ?? '서재',
                onTap: onClose,
              ),
              WorkbenchBreadcrumbSegment(label: l10n?.breadcrumbWork ?? '작품'),
              WorkbenchBreadcrumbSegment(label: titleLabel),
            ],
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkDetailInfoPanel(
                item: item,
                preview: preview,
                panelWidth: infoPanelWidth,
                infoPanelLocked: infoPanelLocked,
                vaultLinked: vaultLinked,
                titleCtrl: titleCtrl,
                posterUrlCtrl: posterUrlCtrl,
                draftRating: draftRating,
                draftWorkStatus: draftWorkStatus,
                draftMyStatus: draftMyStatus,
                draftHallOfFame: draftHallOfFame,
                draftTags: draftTags,
                registryTags: registryTags,
                isSaving: isSaving,
                isArchived: isArchived,
                isDirty: isDirty,
                lastSavedAt: lastSavedAt,
                showAddToLibrary: showAddToLibrary,
                loadingIncoming: loadingIncoming,
                incomingPaths: incomingPaths,
                staleLabelRecordCount: staleLabelRecordCount,
                onRefreshIncoming: onRefreshIncoming,
                loadingSameDay: loadingSameDay,
                sameDayRefs: sameDayRefs,
                onOpenIncoming: onOpenIncoming,
                onOpenSameDay: onOpenSameDay,
                onInfoWidthChanged: onInfoWidthChanged,
                onToggleInfoLock: onToggleInfoLock,
                onMarkDirty: onMarkDirty,
                onDraftRatingChanged: onDraftRatingChanged,
                onDraftWorkStatusChanged: onDraftWorkStatusChanged,
                onDraftMyStatusChanged: onDraftMyStatusChanged,
                onDraftHallOfFameChanged: onDraftHallOfFameChanged,
                onDraftTagsChanged: onDraftTagsChanged,
                onPosterTap: onPosterTap,
                onResetToDefaults: onResetToDefaults,
                onSaveArchive: () => onSaveArchive(),
                onAddToLibrary: onAddToLibrary,
                canDeleteMd: isArchivedInVault,
                onDeleteArchive: onDeleteArchive,
                onClose: onClose,
                linkNeighbors: linkNeighbors,
                loadingLinkNeighbors: loadingLinkNeighbors,
                onOpenLinkedEntity: onOpenLinkedEntity,
                onOpenLinkedWork: onOpenLinkedWork,
                onGoKnowledgeGraph: onGoKnowledgeGraph,
                onFocusSanctum: onFocusSanctum,
              ),
              Expanded(
                child: WorkDetailSanctumPanel(
                  pageView: pageView,
                  onViewChanged: onViewChanged,
                  titleController: titleCtrl,
                  onTitleChanged: onTitleChanged,
                  sectionEditorKey: sectionEditorKey,
                  bodyController: bodyCtrl,
                  fileController: fileCtrl,
                  previewMarkdown: previewBodyMarkdown,
                  mdFilePath: item.filePath,
                  isDirty: isDirty,
                  isSaving: isSaving,
                  externalChangePending: externalChangePending,
                  onReloadFromDisk: onReloadFromDisk,
                  onDismissExternalChange: onDismissExternalChange,
                  lastSavedAt: lastSavedAt,
                  onBodyChanged: onBodyChanged,
                  onFileChanged: onFileChanged,
                  onOpenFileView: onOpenFileView,
                  onWikiLinkTap: onWikiLinkTap,
                  onRequestEntityLink: onRequestEntityLink,
                  userCatalog: userCatalog,
                  onOpenLinkedEntity: onOpenLinkedEntity,
                  category: item.category,
                  archiveCompletionBodyRaw: bodyCtrl.text,
                  canExportHtml: isArchivedInVault,
                  onApplyTemplate: onApplyTemplate,
                  onExportHtml: onExportHtml,
                  saveLabel: isArchived
                      ? (l10n?.actionSaveMd ?? 'md 저장')
                      : (l10n?.actionCreateMd ?? 'md 생성'),
                  onSave: () => onSaveArchive(),
                  showAddToLibrary: showAddToLibrary,
                  libraryLabel: isArchived
                      ? (l10n?.actionAddToLibrary ?? '서재에 담기')
                      : (l10n?.actionSaveAndAddToLibrary ?? '저장하고 서재에 담기'),
                  onAddToLibrary: onAddToLibrary,
                  onReset: onResetToDefaults,
                  canDeleteMd: isArchivedInVault,
                  onDeleteArchive: onDeleteArchive,
                ),
              ),
              WorkDetailConnectionsPanel(
                item: item,
                linkNeighbors: linkNeighbors,
                loadingLinkNeighbors: loadingLinkNeighbors,
                draftTags: draftTags,
                onOpenLinkedEntity: onOpenLinkedEntity,
                onOpenLinkedWork: onOpenLinkedWork,
                onGoKnowledgeGraph: onGoKnowledgeGraph,
                onFocusSanctum: onFocusSanctum,
                onAddEntityLink: onAddEntityLink,
                onAddWorkLink: onAddWorkLink,
                loadingIncoming: loadingIncoming,
                incomingPaths: incomingPaths,
                staleLabelRecordCount: staleLabelRecordCount,
                onRefreshIncoming: onRefreshIncoming,
                onOpenIncoming: onOpenIncoming,
                loadingSameDay: loadingSameDay,
                sameDayRefs: sameDayRefs,
                onOpenSameDay: onOpenSameDay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
