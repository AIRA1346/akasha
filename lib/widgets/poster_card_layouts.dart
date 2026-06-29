import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_typography.dart';
import '../utils/catalog_display_title.dart';
import '../utils/status_helpers.dart';
import 'poster_card_layout_badges.dart';
import 'poster_card_layout_meta.dart';
import 'poster_card_style.dart';
import 'poster_image.dart';
import 'star_rating.dart';

export 'poster_card_layout_badges.dart';
export 'poster_card_layout_meta.dart';

class PosterCardPosterLayout extends StatelessWidget {
  const PosterCardPosterLayout({
    super.key,
    required this.item,
    required this.showArchivedBadge,
    required this.curatedLibraryCount,
    required this.formatSlots,
    required this.incomingRecordCount,
    this.onHideFormatSlot,
  });

  final AkashaItem item;
  final bool showArchivedBadge;
  final int curatedLibraryCount;
  final List<FormatSlot> formatSlots;
  final int incomingRecordCount;
  final void Function(FormatSlot slot)? onHideFormatSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: PosterImage(
                  item: item,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              if (curatedLibraryCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: PosterCardLibraryCountBadge(count: curatedLibraryCount),
                ),
              if (showArchivedBadge)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: PosterCardArchivedBadge(),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: PosterCardPosterMeta(
              item: item,
              formatSlots: formatSlots,
              incomingRecordCount: incomingRecordCount,
              onHideFormatSlot: onHideFormatSlot,
            ),
          ),
        ),
      ],
    );
  }
}

class PosterCardFactCardLayout extends StatelessWidget {
  const PosterCardFactCardLayout({
    super.key,
    required this.item,
    required this.showArchivedBadge,
    required this.curatedLibraryCount,
    required this.formatSlots,
    required this.incomingRecordCount,
    this.onHideFormatSlot,
  });

  final AkashaItem item;
  final bool showArchivedBadge;
  final int curatedLibraryCount;
  final List<FormatSlot> formatSlots;
  final int incomingRecordCount;
  final void Function(FormatSlot slot)? onHideFormatSlot;

  @override
  Widget build(BuildContext context) {
    final isEntity = item is EntityItem;
    final entity = isEntity ? item as EntityItem : null;
    final accent = PosterCardStyle.categoryAccent(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.42),
                        AkashaColors.posterGradientEnd,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: -6,
                child: Icon(
                  isEntity
                      ? iconForEntityAnchorType(entity!.entityType)
                      : item.category.icon,
                  size: 56,
                  color: AkashaColors.borderSubtle(0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AkashaColors.borderSubtle(0.12),
                        ),
                      ),
                      child: Icon(
                        isEntity
                            ? iconForEntityAnchorType(entity!.entityType)
                            : item.category.icon,
                        size: 16,
                        color: AkashaColors.textPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEntity
                            ? entityTypeBadgeLabel(entity!.entityType)
                            : item.category.label,
                        style: AkashaTypography.posterCategoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (curatedLibraryCount > 0) ...[
                      PosterCardLibraryCountBadge(count: curatedLibraryCount),
                      const SizedBox(width: 6),
                    ],
                    if (showArchivedBadge)
                      const PosterCardArchivedBadge(size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolveCatalogDisplayTitle(item),
                  style: AkashaTypography.posterFactCardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                if (item.creator.isNotEmpty)
                  Text(
                    item.creator,
                    style: AkashaTypography.bodySecondary.copyWith(height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Spacer(),
                if (isEntity)
                  Row(
                    children: [
                      PosterCardMetaPill(
                        label: entityTypeBadgeLabel(entity!.entityType),
                        background: accent.withValues(alpha: 0.15),
                        foreground: accent,
                      ),
                      const Spacer(),
                      if (incomingRecordCount > 0)
                        Text(
                          '🔗 $incomingRecordCount',
                          style: AkashaTypography.posterEntityLinkCount,
                        ),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      PosterCardMetaPill(
                        label: watchlistStatusEmojiLabel(item),
                        background: accent.withValues(alpha: 0.2),
                        foreground: accent,
                      ),
                      const Spacer(),
                      if (item.rating > 0)
                        StarRating(rating: item.rating, size: 12),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PosterCardFormatSlotRow(
                    formatSlots: formatSlots,
                    onHideFormatSlot: onHideFormatSlot,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
