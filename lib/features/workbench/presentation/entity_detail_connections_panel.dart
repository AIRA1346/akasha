import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../widgets/entity_link_neighbors_sections.dart';
import 'widgets/workbench_record_links_sections.dart';
import '../../../utils/app_l10n.dart';

/// 워크벤치 우측 연결 패널 — Entity (WorkDetailConnectionsPanel과 동일 3열 구조).
class EntityDetailConnectionsPanel extends StatefulWidget {
  const EntityDetailConnectionsPanel({
    super.key,
    required this.entity,
    required this.linkNeighbors,
    required this.loadingLinkNeighbors,
    required this.draftTags,
    this.onOpenLinkedEntity,
    this.onOpenLinkedWork,
    this.onGoKnowledgeGraph,
    this.onFocusSanctum,
    this.onAddEntityLink,
    this.onAddWorkLink,
    this.loadingIncoming = false,
    this.incomingPaths = const [],
    this.staleLabelRecordCount = 0,
    this.onRefreshIncoming,
    this.onOpenIncoming,
    this.loadingSameDay = false,
    this.sameDayRefs = const [],
    this.onOpenSameDay,
    this.onDraftTagsChanged,
    this.width = 300,
  });

  final UserCatalogEntity entity;
  final EntityLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final List<String> draftTags;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final void Function(AkashaItem work)? onOpenLinkedWork;
  final VoidCallback? onGoKnowledgeGraph;
  final VoidCallback? onFocusSanctum;
  final void Function(EntityAnchorType type)? onAddEntityLink;
  final VoidCallback? onAddWorkLink;
  final bool loadingIncoming;
  final List<String> incomingPaths;
  final int staleLabelRecordCount;
  final VoidCallback? onRefreshIncoming;
  final ValueChanged<String>? onOpenIncoming;
  final bool loadingSameDay;
  final List<SameDayRecordRef> sameDayRefs;
  final ValueChanged<SameDayRecordRef>? onOpenSameDay;
  final ValueChanged<List<String>>? onDraftTagsChanged;
  final double width;

  @override
  State<EntityDetailConnectionsPanel> createState() =>
      _EntityDetailConnectionsPanelState();
}

class _EntityDetailConnectionsPanelState
    extends State<EntityDetailConnectionsPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return SizedBox(
      width: widget.width,
      child: ColoredBox(
        color: palette.workbenchPanel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AkashaSpacing.md,
                AkashaSpacing.md,
                AkashaSpacing.md,
                AkashaSpacing.xs,
              ),
              child: Row(
                children: [
                  _PanelTab(
                    label: l10n?.tabConnection ?? '연결',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _PanelTab(
                    label: l10n?.tabInfo ?? '정보',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                  const Spacer(),
                  if (widget.onGoKnowledgeGraph != null)
                    TextButton(
                      onPressed: widget.onGoKnowledgeGraph,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n?.labelDashboardConnectionMap ?? '연결 맵',
                        style: AkashaTypography.caption.copyWith(
                          color: palette.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? _buildConnectionsTab(l10n)
                  : _buildInfoTab(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsTab(dynamic l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AkashaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.loadingLinkNeighbors && !widget.linkNeighbors.hasAnyLink)
            Padding(
              padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
              child: Text(
                l10n?.helpEntityConnectionExplain ??
                    '섹션의 「추가」로 연결하면 기록 본문에 [[링크]]가 삽입됩니다.',
                style: AkashaTypography.caption.copyWith(
                  color: AkashaColors.textMuted,
                ),
              ),
            ),
          EntityLinkNeighborsSections(
            neighbors: widget.linkNeighbors,
            entityTags: widget.draftTags,
            loading: widget.loadingLinkNeighbors,
            workbenchLayout: true,
            showEmptySections: false,
            onOpenEntity: widget.onOpenLinkedEntity,
            onOpenWork: widget.onOpenLinkedWork,
            onAddEntity: widget.onAddEntityLink,
            onAddWork: widget.onAddWorkLink,
            onRecordCta: widget.onFocusSanctum,
            sectionTitleStyle: AkashaTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AkashaColors.textSecondary,
            ),
          ),
          const SizedBox(height: AkashaSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildInfoTab(dynamic l10n) {
    final n = widget.linkNeighbors;
    final linkCount =
        n.connectedWorks.length +
        n.persons.length +
        n.events.length +
        n.concepts.length +
        n.places.length +
        n.organizations.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AkashaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: l10n?.workbenchTabType ?? '유형',
            value: _getLocalizedEntityType(widget.entity.entityType, l10n),
          ),
          _InfoRow(
            label: l10n?.workbenchTabConnectionCount ?? '연결 수',
            value: '$linkCount',
          ),
          if (widget.entity.aliases.isNotEmpty)
            _InfoRow(
              label: l10n?.workbenchTabAliases ?? '별칭',
              value: widget.entity.aliases.join(', '),
            ),
          if (widget.draftTags.isNotEmpty ||
              widget.onDraftTagsChanged != null) ...[
            const SizedBox(height: AkashaSpacing.sm),
            Text(l10n?.labelTags ?? '태그', style: AkashaTypography.caption),
            const SizedBox(height: 4),
            if (widget.onDraftTagsChanged != null)
              EditableTagChips(
                tags: widget.draftTags,
                onChanged: widget.onDraftTagsChanged!,
                compact: true,
              )
            else
              Text(widget.draftTags.join(', '), style: AkashaTypography.body),
          ],
          const SizedBox(height: AkashaSpacing.md),
          WorkbenchIncomingLinksSection(
            loading: widget.loadingIncoming,
            paths: widget.incomingPaths,
            staleLabelRecordCount: widget.staleLabelRecordCount,
            refreshKey: const Key('entity_conn_incoming_refresh'),
            onRefresh: widget.onRefreshIncoming,
            onOpen: widget.onOpenIncoming,
          ),
          const SizedBox(height: AkashaSpacing.md),
          if (widget.onOpenSameDay != null)
            WorkbenchSameDayRecordsSection(
              loading: widget.loadingSameDay,
              refs: widget.sameDayRefs,
              anchor: widget.entity.addedAt,
              onOpen: widget.onOpenSameDay!,
            ),
        ],
      ),
    );
  }

  String _getLocalizedEntityType(String entityType, dynamic l10n) {
    if (l10n == null) return entityType;
    switch (entityType) {
      case 'work':
        return l10n.entityTypeWork;
      case 'person':
        return l10n.entityTypePerson;
      case 'concept':
        return l10n.entityTypeConcept;
      case 'event':
        return l10n.entityTypeEvent;
      case 'place':
        return l10n.entityTypePlace;
      case 'organization':
        return l10n.entityTypeOrganization;
      case 'custom':
        return l10n.entityTypeCustom;
      case 'phenomenon':
        return l10n.entityTypePhenomenon;
      default:
        return entityType;
    }
  }
}

class _PanelTab extends StatelessWidget {
  const _PanelTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? palette.accent.withValues(alpha: 0.35)
                : palette.borderSubtle(0.18),
          ),
        ),
        child: Text(
          label,
          style: AkashaTypography.caption.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : AkashaColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: AkashaTypography.caption),
          ),
          Expanded(child: Text(value, style: AkashaTypography.body)),
        ],
      ),
    );
  }
}
