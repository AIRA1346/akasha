import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../services/link_candidate_service.dart';
import '../theme/akasha_colors.dart';

/// Work Preview — 연결 있음 상태에서 미연결 후보 제안 (R8 P2-C).
class WorkPreviewNextConnections extends StatelessWidget {
  const WorkPreviewNextConnections({
    super.key,
    required this.candidates,
    this.onSelectSuggested,
  });

  final List<LinkCandidate> candidates;
  final void Function(LinkCandidate candidate)? onSelectSuggested;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '다음으로 탐험할 연결',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AkashaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final candidate in candidates.take(3))
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    candidate.title,
                    style: const TextStyle(fontSize: 10),
                  ),
                  avatar: Icon(
                    _iconFor(candidate.anchorType),
                    size: 14,
                    color: AkashaColors.accent,
                  ),
                  onPressed: onSelectSuggested == null
                      ? null
                      : () => onSelectSuggested!(candidate),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }
}
