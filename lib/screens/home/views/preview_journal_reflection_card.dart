import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/journal_reflection_preview.dart';
import '../../../utils/status_helpers.dart';
import '../../../widgets/star_rating.dart';

/// Home 프리뷰 — Agent·사용자 Work journal 감상 카드.
class PreviewJournalReflectionCard extends StatelessWidget {
  const PreviewJournalReflectionCard({
    super.key,
    required this.item,
    this.isVaultArchived = true,
    this.onOpenDetail,
  });

  final AkashaItem item;
  final bool isVaultArchived;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final memo = JournalReflectionPreview.formatMemo(item.review);
    final hasMemo = JournalReflectionPreview.hasMemo(item.review);
    final hasTags = JournalReflectionPreview.hasTags(item);
    final hasAny = JournalReflectionPreview.hasAnyReflection(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('내 감상', style: AkashaTypography.sectionLabel),
        SizedBox(height: AkashaSpacing.sm + 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AkashaColors.borderSubtle(0.035),
            borderRadius: AkashaRadius.lgBorder,
            border: Border.all(color: AkashaColors.borderSubtle(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetaRow(item: item),
                if (hasTags) ...[
                  SizedBox(height: AkashaSpacing.sm),
                  _TagWrap(tags: item.tags),
                ],
                SizedBox(height: AkashaSpacing.sm),
                if (hasMemo)
                  Text(
                    memo,
                    style: AkashaTypography.dialogBody.copyWith(
                      color: AkashaColors.textPrimary,
                      height: 1.45,
                    ),
                  )
                else
                  Text(
                    JournalReflectionPreview.emptyMemoHint(
                      isVaultArchived: isVaultArchived,
                    ),
                    style: AkashaTypography.bodySecondary.copyWith(height: 1.4),
                  ),
                if (!hasAny && onOpenDetail != null) ...[
                  SizedBox(height: AkashaSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onOpenDetail,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        '기록하기',
                        style: AkashaTypography.bodyEmphasis.copyWith(fontSize: 11),
                      ),
                    ),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});

  final AkashaItem item;

  @override
  Widget build(BuildContext context) {
    final hasRating = JournalReflectionPreview.hasRating(item);
    final hasStatus = JournalReflectionPreview.hasMeaningfulStatus(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasRating)
          StarRating(rating: item.rating, size: 14)
        else
          Text(
            '평가 없음',
            style: AkashaTypography.caption.copyWith(
              color: AkashaColors.textMuted,
            ),
          ),
        if (hasStatus) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              watchlistStatusEmojiLabel(item),
              style: AkashaTypography.bodySecondary.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AkashaColors.accent.withValues(alpha: 0.12),
                borderRadius: AkashaRadius.smBorder,
              ),
              child: Text(
                tag.startsWith('#') ? tag : '#$tag',
                style: AkashaTypography.caption.copyWith(
                  color: AkashaColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
