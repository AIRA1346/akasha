import 'package:flutter/material.dart';

import '../../../services/entity_link_picker_candidates.dart';
import '../../../services/link_candidate_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../widgets/fusion_search_dialog_tiles.dart';
import 'add_catalog_entity_dialog.dart';

class EntityLinkPickerTab extends StatelessWidget {
  const EntityLinkPickerTab({
    super.key,
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
      borderRadius: AkashaRadius.smBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: AkashaSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AkashaColors.accent.withValues(alpha: 0.15) : null,
          borderRadius: AkashaRadius.smBorder,
          border: Border.all(
            color: selected ? AkashaColors.accent : AkashaColors.textCaption,
          ),
        ),
        child: Text(
          label,
          style: AkashaTypography.bodySecondary.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? AkashaColors.accent : AkashaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class EntityLinkPickerSectionLabel extends StatelessWidget {
  const EntityLinkPickerSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AkashaSpacing.xs),
      child: Text(text, style: AkashaTypography.sectionLabel),
    );
  }
}

class EntityLinkRecommendationTile extends StatelessWidget {
  const EntityLinkRecommendationTile({
    super.key,
    required this.candidate,
    required this.onTap,
  });

  final LinkCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        FusionSearchEntityIcons.forType(candidate.anchorType),
        size: 20,
        color: AkashaColors.accent,
      ),
      title: Text(
        candidate.title,
        style: AkashaTypography.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          _reasonLabel(candidate.reason),
          if (candidate.matchDetail != null) candidate.matchDetail!,
        ].join(' · '),
        style: AkashaTypography.caption,
      ),
      trailing: const Icon(
        Icons.north_west,
        size: 14,
        color: AkashaColors.linkAccent,
      ),
    );
  }

  static String _reasonLabel(LinkCandidateReason reason) {
    return switch (reason) {
      LinkCandidateReason.creator => 'creator',
      LinkCandidateReason.tag => 'tag',
      LinkCandidateReason.seed => 'seed',
      LinkCandidateReason.catalog => 'catalog',
    };
  }
}

class EntityLinkCandidateTile extends StatelessWidget {
  const EntityLinkCandidateTile({
    super.key,
    required this.candidate,
    required this.onTap,
  });

  final EntityLinkPickerCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entity = candidate.entity;
    final badge = entityTypeBadgeLabel(entity.anchorType);

    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        FusionSearchEntityIcons.forType(entity.anchorType),
        size: 20,
        color: candidate.isArchived
            ? AkashaColors.linkAccent
            : AkashaColors.textMuted,
      ),
      title: Text(
        entity.title,
        style: AkashaTypography.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          badge,
          if (candidate.isSeed) '사전 인물',
          if (candidate.isArchived) '아카이브',
          if (!candidate.isSeed) entity.entityId,
        ].join(' · '),
        style: AkashaTypography.caption,
      ),
      trailing: entity.aliases.isNotEmpty
          ? Text(
              entity.aliases.take(2).join(', '),
              style: AkashaTypography.caption.copyWith(
                color: AkashaColors.textCaption,
              ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}
