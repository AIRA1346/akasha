import 'package:flutter/material.dart';

import '../../../core/archiving/same_day_record_ref.dart';
import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../widgets/entity_link_neighbors_sections.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'widgets/workbench_panel_styles.dart';
import 'widgets/workbench_record_links_sections.dart';
import 'work_detail_info_poster.dart';

/// Entity collectible — Workbench 좌측 정보 패널 (Phase 6).
class EntityDetailInfoPanel extends StatelessWidget {
  const EntityDetailInfoPanel({
    super.key,
    required this.item,
    required this.preview,
    required this.aliases,
    required this.hasJournal,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.draftTags,
    required this.isSaving,
    this.isDirty = false,
    this.lastSavedAt,
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
    required this.onDraftTagsChanged,
    required this.onSave,
    required this.onPosterTap,
    required this.posterUrlCtrl,
    required this.showAddToLibrary,
    required this.onAddToLibrary,
    this.canDeleteMd = false,
    this.onDeleteArchive,
    this.onClose,
    this.onGoKnowledgeGraph,
    this.linkNeighbors = const EntityLinkNeighbors(),
    this.loadingLinkNeighbors = false,
    this.onOpenLinkedEntity,
    this.onOpenLinkedWork,
    this.onFocusSanctumForLinks,
  });

  final AkashaItem item;
  final AkashaItem preview;
  final List<String> aliases;
  final bool hasJournal;
  final double panelWidth;
  final bool infoPanelLocked;
  final List<String> draftTags;
  final bool isSaving;
  final bool isDirty;
  final DateTime? lastSavedAt;
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
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onSave;
  final VoidCallback onPosterTap;
  final TextEditingController posterUrlCtrl;
  final bool showAddToLibrary;
  final VoidCallback onAddToLibrary;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final EntityLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final void Function(AkashaItem work)? onOpenLinkedWork;
  final VoidCallback? onFocusSanctumForLinks;

  @override
  Widget build(BuildContext context) {
    final entityItem = item as EntityItem;
    final badge = entityTypeBadgeLabel(entityItem.entityType);
    final saveLabel = hasJournal ? 'md 저장' : 'journal 생성';

    return WorkbenchResizablePanel(
      width: panelWidth,
      minWidth: 220,
      maxWidth: 400,
      locked: infoPanelLocked,
      onWidthChanged: onInfoWidthChanged,
      onToggleLock: onToggleInfoLock,
      child: ColoredBox(
        color: AkashaColors.workbenchPanel,
        child: SingleChildScrollView(
          padding: WorkbenchPanelStyles.panelPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: WorkDetailInfoPoster(
                  preview: preview,
                  posterUrlCtrl: posterUrlCtrl,
                  gradColors: categoryGradient(item.category),
                  maxWidth: panelWidth,
                  maxHeight: 180,
                  onPosterTap: onPosterTap,
                  onClose: onClose,
                ),
              ),
              const SizedBox(height: AkashaSpacing.md),
              Text(item.title, style: AkashaTypography.headline),
              const SizedBox(height: AkashaSpacing.xs),
              Text(badge, style: AkashaTypography.bodySecondary),
              if (aliases.isNotEmpty) ...[
                const SizedBox(height: AkashaSpacing.sm),
                Text(
                  '별칭: ${aliases.join(', ')}',
                  style: AkashaTypography.body,
                ),
              ],
              const SizedBox(height: AkashaSpacing.sm),
              Row(
                children: [
                  Icon(
                    hasJournal
                        ? Icons.inventory_2_outlined
                        : Icons.cloud_outlined,
                    size: 14,
                    color: hasJournal
                        ? AkashaColors.statusSaved
                        : AkashaColors.textMuted,
                  ),
                  const SizedBox(width: AkashaSpacing.sm),
                  Text(
                    hasJournal ? '기록 있음' : '기록 없음 (카탈로그만)',
                    style: AkashaTypography.bodySecondary.copyWith(
                      color: hasJournal
                          ? AkashaColors.statusSaved
                          : AkashaColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AkashaSpacing.lg),

              WorkbenchPanelStyles.connectionsHeader(),
              const SizedBox(height: AkashaSpacing.sm),
              EntityLinkNeighborsSections(
                neighbors: linkNeighbors,
                entityTags: draftTags,
                loading: loadingLinkNeighbors,
                onOpenEntity: onOpenLinkedEntity,
                onOpenWork: onOpenLinkedWork,
                onRecordCta: onFocusSanctumForLinks,
                sectionTitleStyle: AkashaTypography.sectionTitle,
              ),
              if (onGoKnowledgeGraph != null) ...[
                const SizedBox(height: AkashaSpacing.xs),
                WorkbenchPanelStyles.graphListButton(
                  onPressed: onGoKnowledgeGraph!,
                ),
              ],

              WorkbenchPanelStyles.panelDivider(),
              WorkbenchIncomingLinksSection(
                loading: loadingIncoming,
                paths: incomingPaths,
                staleLabelRecordCount: staleLabelRecordCount,
                refreshKey: const Key('entity_incoming_refresh'),
                onRefresh: onRefreshIncoming,
                onOpen: onOpenIncoming,
              ),
              const SizedBox(height: AkashaSpacing.md),
              WorkbenchSameDayRecordsSection(
                loading: loadingSameDay,
                refs: sameDayRefs,
                anchor: item.addedAt,
                onOpen: onOpenSameDay,
              ),

              WorkbenchPanelStyles.panelDivider(),
              WorkbenchPanelStyles.sectionLabel('태그'),
              const SizedBox(height: AkashaSpacing.sm),
              EditableTagChips(
                tags: draftTags,
                onChanged: onDraftTagsChanged,
                compact: false,
              ),

              const SizedBox(height: AkashaSpacing.lg),
              WorkbenchSaveActions(
                isSaving: isSaving,
                isDirty: isDirty,
                lastSavedAt: lastSavedAt,
                saveLabel: saveLabel,
                explicitSaveLabel: saveLabel,
                onSave: onSave,
                showAddToLibrary: showAddToLibrary,
                libraryLabel:
                    hasJournal ? '서재에 담기' : '저장하고 서재에 담기',
                onAddToLibrary: onAddToLibrary,
                canDeleteMd: canDeleteMd,
                onDeleteArchive: onDeleteArchive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
