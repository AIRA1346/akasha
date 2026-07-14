import 'package:flutter/material.dart';

import '../services/relationship_discovery_service.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_typography.dart';

/// Work Preview — Concept Theme Cluster (R13).
class WorkPreviewThemeClustersSection extends StatelessWidget {
  const WorkPreviewThemeClustersSection({
    super.key,
    required this.clusters,
    this.onOpenConcept,
    this.compact = false,
  });

  final List<ConceptThemeCluster> clusters;
  final void Function(ConceptThemeCluster cluster)? onOpenConcept;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) return const SizedBox.shrink();
    final palette = context.akashaPalette;

    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 14, color: palette.textMuted),
              const SizedBox(width: 6),
              Text(
                '반복되는 주제',
                style: AkashaTypography.caption.copyWith(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cluster in clusters)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '${cluster.concept.title} (${cluster.workCount})',
                    style: AkashaTypography.caption.copyWith(
                      fontSize: compact ? 9 : 10,
                      color: palette.textPrimary,
                    ),
                  ),
                  avatar: Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: palette.accent,
                  ),
                  onPressed: onOpenConcept == null
                      ? null
                      : () => onOpenConcept!(cluster),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
