import 'package:flutter/material.dart';

import '../../../core/archiving/record_link.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/journal_reflection_preview.dart';
import '../../../utils/status_helpers.dart';
import '../../../widgets/sanctum/sanctum_wiki_inline_text.dart';
import '../../../widgets/star_rating.dart';

/// Home 프리뷰 — Agent·사용자 Work journal 감상 카드.
class PreviewJournalReflectionCard extends StatelessWidget {
  const PreviewJournalReflectionCard({
    super.key,
    required this.item,
    this.isVaultArchived = true,
    this.onOpenDetail,
    this.userCatalog,
    this.onWikiLinkTap,
  });

  final AkashaItem item;
  final bool isVaultArchived;
  final VoidCallback? onOpenDetail;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final memo = JournalReflectionPreview.formatMemo(item.review);
    final hasMemo = JournalReflectionPreview.hasMemo(item.review);
    final hasTags = JournalReflectionPreview.hasTags(item);
    final hasAny = JournalReflectionPreview.hasAnyReflection(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.previewMyNotes ?? '내 감상',
          style: AkashaTypography.sectionLabel.copyWith(
            color: palette.textSecondary,
          ),
        ),
        SizedBox(height: AkashaSpacing.sm + 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AkashaRadius.lgBorder,
            border: Border.all(color: palette.borderSubtle(0.2)),
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
                  SanctumWikiParagraphs(
                    content: memo,
                    userCatalog: userCatalog,
                    onWikiLinkTap: onWikiLinkTap,
                    style: AkashaTypography.dialogBody.copyWith(
                      color: palette.textPrimary,
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
                        l10n?.actionRecord ?? '기록하기',
                        style: AkashaTypography.bodyEmphasis.copyWith(
                          fontSize: 11,
                        ),
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
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final hasRating = JournalReflectionPreview.hasRating(item);
    final hasStatus = JournalReflectionPreview.hasMeaningfulStatus(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasRating)
          StarRating(rating: item.rating, size: 14)
        else
          Text(
            l10n?.previewNoRating ?? '평가 없음',
            style: AkashaTypography.caption.copyWith(color: palette.textMuted),
          ),
        if (hasStatus) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              watchlistStatusEmojiLabel(item, l10n),
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
    final palette = context.akashaPalette;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: AkashaRadius.smBorder,
              ),
              child: Text(
                tag.startsWith('#') ? tag : '#$tag',
                style: AkashaTypography.caption.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
