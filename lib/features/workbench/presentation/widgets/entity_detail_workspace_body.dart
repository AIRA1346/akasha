import 'package:flutter/material.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/archiving/entity_anchor.dart';
import '../../../../core/archiving/record_link.dart';
import '../../../../core/archiving/same_day_record_ref.dart';
import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/entity_link_selection.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../utils/entity_link_neighbors.dart';
import '../../../../screens/home/views/preview_record_view_model.dart';
import '../../../../widgets/sanctum_page_panel.dart';
import '../entity_detail_connections_panel.dart';
import '../entity_detail_info_panel.dart';
import 'entity_detail_sanctum_panel.dart';
import 'workbench_breadcrumb.dart';

/// Entity 워크벤치 — breadcrumb + 3열 본문.
class EntityDetailWorkspaceBody extends StatelessWidget {
  const EntityDetailWorkspaceBody({
    super.key,
    required this.entity,
    required this.preview,
    required this.hasJournal,
    required this.saveLabel,
    required this.infoPanelWidth,
    required this.infoPanelLocked,
    required this.posterUrlCtrl,
    required this.bodyCtrl,
    required this.fileCtrl,
    required this.draftTags,
    required this.pageView,
    required this.isDirty,
    required this.isSaving,
    required this.externalChangePending,
    required this.lastSavedAt,
    required this.showAddToLibrary,
    required this.linkNeighbors,
    required this.loadingLinkNeighbors,
    required this.loadingIncoming,
    required this.incomingPaths,
    required this.staleLabelRecordCount,
    required this.loadingSameDay,
    required this.sameDayRefs,
    required this.onClose,
    required this.onGoKnowledgeGraph,
    required this.userCatalog,
    required this.linkIndex,
    required this.journalStoragePath,
    required this.onWikiLinkTap,
    required this.onRequestEntityLink,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
    required this.onPosterTap,
    required this.onFocusSanctum,
    required this.onViewChanged,
    required this.onReloadFromDisk,
    required this.onDismissExternalChange,
    required this.onBodyChanged,
    required this.onFileChanged,
    required this.onOpenFileView,
    required this.onSave,
    required this.onExportHtml,
    required this.onAddToLibrary,
    required this.onDeleteArchive,
    required this.onOpenLinkedEntity,
    required this.onOpenLinkedWork,
    required this.onAddEntityLink,
    required this.onAddWorkLink,
    required this.onRefreshIncoming,
    required this.onOpenIncoming,
    required this.onOpenSameDay,
    required this.onDraftTagsChanged,
  });

  final UserCatalogEntity entity;
  final EntityItem preview;
  final bool hasJournal;
  final String saveLabel;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final TextEditingController posterUrlCtrl;
  final TextEditingController bodyCtrl;
  final TextEditingController fileCtrl;
  final List<String> draftTags;
  final SanctumPageView pageView;
  final bool isDirty;
  final bool isSaving;
  final bool externalChangePending;
  final DateTime? lastSavedAt;
  final bool showAddToLibrary;
  final EntityLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final bool loadingIncoming;
  final List<String> incomingPaths;
  final int staleLabelRecordCount;
  final bool loadingSameDay;
  final List<SameDayRecordRef> sameDayRefs;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final UserCatalogPort? userCatalog;
  final RecordLinkPort? linkIndex;
  final String? journalStoragePath;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final Future<void> Function() onPosterTap;
  final VoidCallback onFocusSanctum;
  final ValueChanged<SanctumPageView> onViewChanged;
  final Future<void> Function() onReloadFromDisk;
  final VoidCallback onDismissExternalChange;
  final VoidCallback onBodyChanged;
  final VoidCallback onFileChanged;
  final VoidCallback onOpenFileView;
  final Future<void> Function() onSave;
  final Future<void> Function() onExportHtml;
  final Future<void> Function() onAddToLibrary;
  final Future<void> Function()? onDeleteArchive;
  final void Function(UserCatalogEntity entity) onOpenLinkedEntity;
  final void Function(AkashaItem work) onOpenLinkedWork;
  final Future<void> Function(EntityAnchorType type)? onAddEntityLink;
  final Future<void> Function()? onAddWorkLink;
  final VoidCallback onRefreshIncoming;
  final Future<void> Function(String path) onOpenIncoming;
  final Future<void> Function(SameDayRecordRef ref) onOpenSameDay;
  final ValueChanged<List<String>> onDraftTagsChanged;

  @override
  Widget build(BuildContext context) {
    final typeLabel = entityTypeDisplayLabel(entity.anchorType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (FeatureFlags.showWorkbenchBreadcrumb)
          WorkbenchBreadcrumb(
            segments: [
              WorkbenchBreadcrumbSegment(
                label: '서재',
                onTap: onClose,
              ),
              WorkbenchBreadcrumbSegment(label: typeLabel),
              WorkbenchBreadcrumbSegment(label: entity.title),
            ],
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EntityDetailInfoPanel(
                entity: entity,
                preview: preview,
                hasJournal: hasJournal,
                panelWidth: infoPanelWidth,
                infoPanelLocked: infoPanelLocked,
                onInfoWidthChanged: onInfoWidthChanged,
                onToggleInfoLock: onToggleInfoLock,
                onPosterTap: onPosterTap,
                posterUrlCtrl: posterUrlCtrl,
                onClose: onClose,
                onFocusSanctum: onFocusSanctum,
              ),
              Expanded(
                child: EntityDetailSanctumPanel(
                  pageView: pageView,
                  onViewChanged: onViewChanged,
                  bodyController: bodyCtrl,
                  fileController: fileCtrl,
                  previewMarkdown: bodyCtrl.text,
                  mdFilePath: journalStoragePath,
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
                  hasJournal: hasJournal,
                  saveLabel: saveLabel,
                  onSave: onSave,
                  onExportHtml: onExportHtml,
                  showAddToLibrary: showAddToLibrary,
                  libraryLabel:
                      hasJournal ? '서재에 담기' : '저장하고 서재에 담기',
                  onAddToLibrary: onAddToLibrary,
                  onDeleteArchive: onDeleteArchive,
                ),
              ),
              EntityDetailConnectionsPanel(
                entity: entity,
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
                onDraftTagsChanged: onDraftTagsChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
