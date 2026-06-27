import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/connection_similarity.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_discovery_loader.dart';

class DiscoverySectionEmptyCta extends StatelessWidget {
  const DiscoverySectionEmptyCta({
    super.key,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AkashaTypography.bodySecondary,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: AkashaColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: Text(primaryLabel, style: AkashaTypography.compactLabel),
              ),
              if (secondaryLabel != null && onSecondary != null)
                OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!, style: AkashaTypography.compactLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiscoverySectionTabButton extends StatelessWidget {
  const DiscoverySectionTabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? AkashaColors.textPrimary : AkashaColors.textCaption,
      ),
      child: Text(
        label,
        style: AkashaTypography.body.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class DiscoverySectionPairCard extends StatelessWidget {
  const DiscoverySectionPairCard({
    super.key,
    required this.highlight,
    required this.onItemTap,
    this.onItemDoubleTap,
    required this.onOpenEntity,
    this.onConnectSuggested,
  });

  final DiscoveryPairHighlight highlight;
  final void Function(AkashaItem item) onItemTap;
  final void Function(AkashaItem item)? onItemDoubleTap;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;

  @override
  Widget build(BuildContext context) {
    final badge = similarityBadgeLabel(
      axis: highlight.axis,
      percent: highlight.percent,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            badge,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AkashaTypography.sectionLabel.copyWith(
              color: AkashaColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiscoverySectionWorkThumb(
                  item: highlight.left,
                  onTap: () => onItemTap(highlight.left),
                  onDoubleTap: onItemDoubleTap == null
                      ? null
                      : () => onItemDoubleTap!(highlight.left),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AkashaColors.accent,
                  ),
                ),
                if (highlight.isSuggestion)
                  DiscoverySectionSuggestionThumb(
                    candidate: highlight.candidate!,
                    onTap: onConnectSuggested == null
                        ? null
                        : () => onConnectSuggested!(
                              highlight.candidate!,
                              highlight.left,
                            ),
                  )
                else
                  DiscoverySectionWorkThumb(
                    item: highlight.right,
                    onTap: () => onItemTap(highlight.right),
                    onDoubleTap: onItemDoubleTap == null
                        ? null
                        : () => onItemDoubleTap!(highlight.right),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverySectionSuggestionThumb extends StatelessWidget {
  const DiscoverySectionSuggestionThumb({
    super.key,
    required this.candidate,
    this.onTap,
  });

  final LinkCandidate candidate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AkashaColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AkashaColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.add_link_rounded,
                color: AkashaColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                candidate.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AkashaTypography.micro.copyWith(
                  color: AkashaColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverySectionSingleCard extends StatelessWidget {
  const DiscoverySectionSingleCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDoubleTap,
  });

  final AkashaItem item;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NEW',
                  style: AkashaTypography.micro.copyWith(
                    color: AkashaColors.newBadgeText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DiscoverySectionWorkThumb(item: item, onTap: onTap),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AkashaTypography.caption.copyWith(
                  color: AkashaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoverySectionEntityCard extends StatelessWidget {
  const DiscoverySectionEntityCard({
    super.key,
    required this.entity,
    required this.onTap,
    this.onDoubleTap,
  });

  final UserCatalogEntity entity;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final avatarItem = EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: entity.posterPath,
      tags: entity.tags,
      addedAt: entity.addedAt,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AkashaTypography.caption.copyWith(
                  color: AkashaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoverySectionWorkThumb extends StatelessWidget {
  const DiscoverySectionWorkThumb({
    super.key,
    required this.item,
    required this.onTap,
    this.onDoubleTap,
  });

  final AkashaItem item;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: PosterImage(item: item, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
