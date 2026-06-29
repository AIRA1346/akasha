import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_typography.dart';
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
            style: AkashaTypography.posterRatingPending,
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            watchlistStatusEmojiLabel(item),
            style: AkashaTypography.bodySecondary.copyWith(
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
            color: AkashaColors.editorAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AkashaColors.editorAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            entityTypeBadgeLabel(item.entityType),
            style: AkashaTypography.posterEntityTypeBadge,
          ),
        ),
        const Spacer(),
        if (incomingRecordCount > 0)
          Text(
            '🔗 $incomingRecordCount',
            style: AkashaTypography.posterEntityLinkCount,
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
                  style: AkashaTypography.posterMetaTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.creator.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.creator,
                  style: AkashaTypography.bodySecondary.copyWith(height: 1.2),
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
                      style: AkashaTypography.caption.copyWith(
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
