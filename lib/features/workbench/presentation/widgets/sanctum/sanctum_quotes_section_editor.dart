import 'package:flutter/material.dart';

import '../../../../../theme/akasha_colors.dart';
import '../../../../../theme/akasha_palette.dart';
import '../../../../../theme/akasha_radius.dart';
import '../../../../../theme/akasha_spacing.dart';
import '../../../../../theme/akasha_typography.dart';
import '../../../../../utils/app_l10n.dart';

/// Sanctum 기록 탭 — `# 🎬 명장면` 접이식 편집 UI.
class SanctumQuotesSectionEditor extends StatelessWidget {
  const SanctumQuotesSectionEditor({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.controller,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.workbenchTile,
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: palette.borderSubtle(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AkashaRadius.mdBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AkashaSpacing.md,
                vertical: AkashaSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote_outlined,
                    size: 16,
                    color: AkashaColors.textMuted,
                  ),
                  const SizedBox(width: AkashaSpacing.sm),
                  Text(
                    l10n != null
                        ? l10n.workbenchQuotesSectionTitle
                              .replaceAll('🎬', '')
                              .trim()
                        : '명장면 & 명대사',
                    style: AkashaTypography.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AkashaColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AkashaSpacing.md),
              child: TextField(
                controller: controller,
                minLines: 3,
                maxLines: null,
                style: AkashaTypography.body,
                decoration: InputDecoration(
                  hintText: l10n?.hintQuotesEditor ?? '한 줄에 한 문장씩 입력하세요.',
                  hintStyle: AkashaTypography.bodySecondary,
                  filled: true,
                  fillColor: palette.workbenchEditor,
                  border: OutlineInputBorder(
                    borderRadius: AkashaRadius.smBorder,
                    borderSide: BorderSide(color: palette.borderSubtle(0.18)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AkashaRadius.smBorder,
                    borderSide: BorderSide(color: palette.borderSubtle(0.18)),
                  ),
                  contentPadding: const EdgeInsets.all(AkashaSpacing.md),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
