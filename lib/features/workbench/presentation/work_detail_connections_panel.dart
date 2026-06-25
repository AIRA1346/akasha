import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/work_link_neighbors_sections.dart';
import 'widgets/workbench_record_links_sections.dart';

/// 워크벤치 우측 연결 패널 — 연결|정보 탭. 실데이터 link neighbors 연동.
class WorkDetailConnectionsPanel extends StatefulWidget {
  const WorkDetailConnectionsPanel({
    super.key,
    required this.item,
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
    this.width = 300,
  });

  final AkashaItem item;
  final WorkLinkNeighbors linkNeighbors;
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
  final double width;

  @override
  State<WorkDetailConnectionsPanel> createState() =>
      _WorkDetailConnectionsPanelState();
}

class _WorkDetailConnectionsPanelState extends State<WorkDetailConnectionsPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ColoredBox(
        color: AkashaColors.workbenchPanel,
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
                    label: '연결',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _PanelTab(
                    label: '정보',
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
                        '연결 맵',
                        style: AkashaTypography.caption.copyWith(
                          color: AkashaColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 0 ? _buildConnectionsTab() : _buildInfoTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AkashaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.loadingLinkNeighbors && !widget.linkNeighbors.hasAnyLink)
            Padding(
              padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
              child: Text(
                '섹션의 「추가」로 Entity를 연결합니다. 인물은 출연 슬롯, 그 외는 감상 본문에 [[링크]]가 삽입됩니다.',
                style: AkashaTypography.caption.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ),
          WorkLinkNeighborsSections(
            neighbors: widget.linkNeighbors,
            loading: widget.loadingLinkNeighbors,
            conceptTags: widget.draftTags,
            sourceWork: widget.item,
            workbenchLayout: true,
            showEmptySections: false,
            onOpenEntity: widget.onOpenLinkedEntity,
            onOpenWork: widget.onOpenLinkedWork,
            onAddEntity: widget.onAddEntityLink,
            onAddWork: widget.onAddWorkLink,
            sectionTitleStyle: AkashaTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: AkashaSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final n = widget.linkNeighbors;
    final linkCount = n.characters.length +
        n.connectedWorks.length +
        n.events.length +
        n.concepts.length +
        n.places.length +
        n.organizations.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AkashaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(label: '연결 수', value: '$linkCount'),
          if (widget.item.filePath != null)
            _InfoRow(label: '저장 경로', value: widget.item.filePath!),
          if (widget.draftTags.isNotEmpty) ...[
            const SizedBox(height: AkashaSpacing.sm),
            Text('태그', style: AkashaTypography.sectionLabel),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.draftTags
                  .map(
                    (t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AkashaColors.surface,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AkashaSpacing.md),
          WorkbenchIncomingLinksSection(
            loading: widget.loadingIncoming,
            paths: widget.incomingPaths,
            staleLabelRecordCount: widget.staleLabelRecordCount,
            refreshKey: const Key('work_incoming_refresh_panel'),
            onRefresh: widget.onRefreshIncoming,
            onOpen: widget.onOpenIncoming,
          ),
          const SizedBox(height: AkashaSpacing.md),
          WorkbenchSameDayRecordsSection(
            loading: widget.loadingSameDay,
            refs: widget.sameDayRefs,
            anchor: widget.item.addedAt,
            onOpen: widget.onOpenSameDay ?? (_) {},
          ),
          const SizedBox(height: AkashaSpacing.lg),
        ],
      ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AkashaColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AkashaColors.accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey[500],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: AkashaTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AkashaTypography.caption.copyWith(
                color: AkashaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
