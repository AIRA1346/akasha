import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/work_link_neighbors_sections.dart';

/// 워크벤치 우측 연결 패널 — mock 3열 레이아웃 (R15).
class WorkDetailConnectionsPanel extends StatelessWidget {
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
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
                AkashaSpacing.sm,
              ),
              child: Row(
                children: [
                  Text('연결', style: AkashaTypography.sectionTitle),
                  const Spacer(),
                  if (onGoKnowledgeGraph != null)
                    TextButton(
                      onPressed: onGoKnowledgeGraph,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AkashaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AddRow(
                      label: '인물 추가',
                      onTap: onAddEntityLink == null
                          ? null
                          : () => onAddEntityLink!(EntityAnchorType.person),
                    ),
                    const SizedBox(height: AkashaSpacing.sm),
                    WorkLinkNeighborsSections(
                      neighbors: linkNeighbors,
                      loading: loadingLinkNeighbors,
                      conceptTags: draftTags,
                      sourceWork: item,
                      onOpenEntity: onOpenLinkedEntity,
                      onOpenWork: onOpenLinkedWork,
                      onLinkCta: onFocusSanctum,
                      sectionTitleStyle: AkashaTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: AkashaSpacing.md),
                    _AddRow(
                      label: '작품 연결 추가',
                      onTap: onFocusSanctum,
                    ),
                    _AddRow(
                      label: '개념 추가',
                      onTap: onAddEntityLink == null
                          ? null
                          : () => onAddEntityLink!(EntityAnchorType.concept),
                    ),
                    _AddRow(
                      label: '장소 추가',
                      onTap: onAddEntityLink == null
                          ? null
                          : () => onAddEntityLink!(EntityAnchorType.place),
                    ),
                    _AddRow(
                      label: '사건 추가',
                      onTap: onAddEntityLink == null
                          ? null
                          : () => onAddEntityLink!(EntityAnchorType.event),
                    ),
                    const SizedBox(height: AkashaSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[300],
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}
