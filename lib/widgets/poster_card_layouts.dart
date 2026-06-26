import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../theme/akasha_colors.dart';
import '../utils/catalog_display_title.dart';
import '../utils/status_helpers.dart';
import 'format_chip_row.dart';
import 'poster_card_style.dart';
import 'poster_image.dart';
import 'star_rating.dart';

class PosterCardLibraryCountBadge extends StatelessWidget {
  const PosterCardLibraryCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.amberAccent.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        '★$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.amberAccent,
        ),
      ),
    );
  }
}

class PosterCardArchivedBadge extends StatelessWidget {
  const PosterCardArchivedBadge({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sanctum vault 연동됨',
      child: Semantics(
        label: '아카이브됨',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCCCCCC),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.description_outlined,
            size: size * 0.58,
            color: const Color(0xFFCCCCCC),
          ),
        ),
      ),
    );
  }
}

class PosterCardMetaPill extends StatelessWidget {
  const PosterCardMetaPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class PosterCardFormatSlotRow extends StatelessWidget {
  const PosterCardFormatSlotRow({
    super.key,
    required this.formatSlots,
    this.onHideFormatSlot,
  });

  final List<FormatSlot> formatSlots;
  final void Function(FormatSlot slot)? onHideFormatSlot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FormatChipRow.rowHeight,
      child: formatSlots.isNotEmpty
          ? FormatChipRow(
              slots: formatSlots,
              onHideSlot: onHideFormatSlot,
            )
          : const SizedBox.shrink(),
    );
  }
}

class PosterCardRatingStatusRow extends StatelessWidget {
  const PosterCardRatingStatusRow({super.key, required this.item});

  final AkashaItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (item.rating > 0)
          StarRating(rating: item.rating, size: 14)
        else
          const Text(
            '⏳ 평가 대기',
            style: TextStyle(
              fontSize: 11,
              color: Colors.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            watchlistStatusEmojiLabel(item),
            style: TextStyle(
              fontSize: 11,
              color: AkashaColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class PosterCardEntityMetaRow extends StatelessWidget {
  const PosterCardEntityMetaRow({
    super.key,
    required this.item,
    required this.incomingRecordCount,
  });

  final EntityItem item;
  final int incomingRecordCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            entityTypeBadgeLabel(item.entityType),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.tealAccent,
            ),
          ),
        ),
        const Spacer(),
        if (incomingRecordCount > 0)
          Text(
            '🔗 $incomingRecordCount',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.tealAccent,
            ),
          ),
      ],
    );
  }
}

class PosterCardPosterMeta extends StatelessWidget {
  const PosterCardPosterMeta({
    super.key,
    required this.item,
    required this.formatSlots,
    required this.incomingRecordCount,
    this.onHideFormatSlot,
  });

  final AkashaItem item;
  final List<FormatSlot> formatSlots;
  final int incomingRecordCount;
  final void Function(FormatSlot slot)? onHideFormatSlot;

  @override
  Widget build(BuildContext context) {
    final displayTitle = resolveCatalogDisplayTitle(item);
    final isEntity = item is EntityItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.creator.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.creator,
                  style: TextStyle(
                    fontSize: 11,
                    color: AkashaColors.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (isEntity)
          PosterCardEntityMetaRow(
            item: item as EntityItem,
            incomingRecordCount: incomingRecordCount,
          )
        else ...[
          PosterCardRatingStatusRow(item: item),
          const SizedBox(height: 2),
          SizedBox(
            height: PosterCardStyle.yearRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: item.releaseYear != null
                  ? Text(
                      '🗓️ ${item.releaseYear}년',
                      style: TextStyle(
                        fontSize: 10,
                        color: AkashaColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 2),
          PosterCardFormatSlotRow(
            formatSlots: formatSlots,
            onHideFormatSlot: onHideFormatSlot,
          ),
        ],
      ],
    );
  }
}

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
                        const Color(0xFF252536),
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
                  color: Colors.white.withValues(alpha: 0.08),
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
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        isEntity
                            ? iconForEntityAnchorType(entity!.entityType)
                            : item.category.icon,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEntity
                            ? entityTypeBadgeLabel(entity!.entityType)
                            : item.category.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.15,
                        ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                if (item.creator.isNotEmpty)
                  Text(
                    item.creator,
                    style: TextStyle(
                      fontSize: 11,
                      color: AkashaColors.textSecondary,
                      height: 1.2,
                    ),
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.tealAccent,
                          ),
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
