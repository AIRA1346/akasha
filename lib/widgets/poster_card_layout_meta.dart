import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../theme/akasha_colors.dart';
import '../utils/catalog_display_title.dart';
import '../utils/status_helpers.dart';
import 'format_chip_row.dart';
import 'poster_card_style.dart';
import 'star_rating.dart';

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
