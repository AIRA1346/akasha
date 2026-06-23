import 'package:flutter/material.dart';

import '../../../core/archiving/same_day_record_ref.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../models/enums.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'widgets/workbench_panel_styles.dart';
import 'widgets/workbench_record_links_sections.dart';
import 'work_detail_info_form.dart';
import 'work_detail_info_poster.dart';

/// 워크벤치 좌측 작품정보 패널 (E2-6).
class WorkDetailInfoPanel extends StatelessWidget {
  const WorkDetailInfoPanel({
    super.key,
    required this.item,
    required this.preview,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.vaultLinked,
    required this.titleCtrl,
    required this.posterUrlCtrl,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.draftTags,
    required this.registryTags,
    required this.isSaving,
    required this.isArchived,
    this.isDirty = false,
    this.lastSavedAt,
    required this.showAddToLibrary,
    required this.loadingIncoming,
    required this.incomingPaths,
    required this.staleLabelRecordCount,
    required this.onRefreshIncoming,
    required this.loadingSameDay,
    required this.sameDayRefs,
    required this.onOpenIncoming,
    required this.onOpenSameDay,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
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
    this.canDeleteMd = false,
    this.onDeleteArchive,
    this.onClose,
    this.linkNeighbors = const WorkLinkNeighbors(),
    this.loadingLinkNeighbors = false,
    this.onOpenLinkedEntity,
    this.onOpenLinkedWork,
    this.onGoKnowledgeGraph,
    this.onFocusSanctum,
  });

  final AkashaItem item;
  final AkashaItem preview;
  final double panelWidth;
  final bool infoPanelLocked;
  final bool vaultLinked;
  final TextEditingController titleCtrl;
  final TextEditingController posterUrlCtrl;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final List<String> draftTags;
  final Set<String> registryTags;
  final bool isSaving;
  final bool isArchived;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final bool showAddToLibrary;
  final bool loadingIncoming;
  final List<String> incomingPaths;
  final int staleLabelRecordCount;
  final VoidCallback? onRefreshIncoming;
  final bool loadingSameDay;
  final List<SameDayRecordRef> sameDayRefs;
  final ValueChanged<String> onOpenIncoming;
  final ValueChanged<SameDayRecordRef> onOpenSameDay;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final VoidCallback onMarkDirty;
  final ValueChanged<double> onDraftRatingChanged;
  final ValueChanged<String> onDraftWorkStatusChanged;
  final ValueChanged<String> onDraftMyStatusChanged;
  final ValueChanged<bool> onDraftHallOfFameChanged;
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onPosterTap;
  final VoidCallback onResetToDefaults;
  final VoidCallback onSaveArchive;
  final VoidCallback onAddToLibrary;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;
  final VoidCallback? onClose;
  final WorkLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final void Function(AkashaItem work)? onOpenLinkedWork;
  final VoidCallback? onGoKnowledgeGraph;
  final VoidCallback? onFocusSanctum;

  @override
  Widget build(BuildContext context) {
    final gradColors = categoryGradient(item.category);
    final metaLine = [
      if (item.creator.isNotEmpty) item.creator,
      if (item.releaseYear != null) '${item.releaseYear}',
    ].join(' · ');

    return WorkbenchResizablePanel(
      width: panelWidth,
      minWidth: 220,
      maxWidth: 400,
      locked: infoPanelLocked,
      onWidthChanged: onInfoWidthChanged,
      onToggleLock: onToggleInfoLock,
      child: ColoredBox(
        color: AkashaColors.workbenchPanel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!vaultLinked)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AkashaSpacing.md,
                  AkashaSpacing.sm,
                  AkashaSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_off_outlined,
                      size: 14,
                      color: AkashaColors.statusWarning,
                    ),
                    const SizedBox(width: AkashaSpacing.sm),
                    Expanded(
                      child: Text(
                        '볼트 미연동 · 임시 저장만',
                        style: AkashaTypography.caption.copyWith(
                          color: AkashaColors.statusWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final posterMaxHeight = constraints.maxHeight * 0.30;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AkashaSpacing.md,
                          AkashaSpacing.sm,
                          AkashaSpacing.md,
                          AkashaSpacing.xs,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: WorkDetailInfoPoster(
                            preview: preview,
                            posterUrlCtrl: posterUrlCtrl,
                            gradColors: gradColors,
                            maxWidth: constraints.maxWidth,
                            maxHeight: posterMaxHeight,
                            onPosterTap: onPosterTap,
                            onClose: onClose,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: WorkbenchPanelStyles.panelPadding,
                          child: WorkDetailInfoForm(
                            item: item,
                            metaLine: metaLine,
                            titleCtrl: titleCtrl,
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
                            onMarkDirty: onMarkDirty,
                            onDraftRatingChanged: onDraftRatingChanged,
                            onDraftWorkStatusChanged: onDraftWorkStatusChanged,
                            onDraftMyStatusChanged: onDraftMyStatusChanged,
                            onDraftHallOfFameChanged: onDraftHallOfFameChanged,
                            onDraftTagsChanged: onDraftTagsChanged,
                            onResetToDefaults: onResetToDefaults,
                            onSaveArchive: onSaveArchive,
                            onAddToLibrary: onAddToLibrary,
                            canDeleteMd: canDeleteMd,
                            onDeleteArchive: onDeleteArchive,
                            linkNeighbors: linkNeighbors,
                            loadingLinkNeighbors: loadingLinkNeighbors,
                            onOpenLinkedEntity: onOpenLinkedEntity,
                            onOpenLinkedWork: onOpenLinkedWork,
                            onGoKnowledgeGraph: onGoKnowledgeGraph,
                            onFocusSanctum: onFocusSanctum,
                            hideConnectionsSection: true,
                            notesSection: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                WorkbenchIncomingLinksSection(
                                  loading: loadingIncoming,
                                  paths: incomingPaths,
                                  staleLabelRecordCount: staleLabelRecordCount,
                                  refreshKey: const Key('work_incoming_refresh'),
                                  onRefresh: onRefreshIncoming,
                                  onOpen: onOpenIncoming,
                                ),
                                WorkbenchSameDayRecordsSection(
                                  loading: loadingSameDay,
                                  refs: sameDayRefs,
                                  anchor: item.addedAt,
                                  onOpen: onOpenSameDay,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
