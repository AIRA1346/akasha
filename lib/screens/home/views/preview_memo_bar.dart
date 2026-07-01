import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

/// 프리뷰 하단 빠른 메모 진입. v1: [FeatureFlags.showPreviewMemoBar].
class PreviewMemoBar extends StatelessWidget {
  const PreviewMemoBar({super.key, required this.onOpenDetail});

  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AkashaColors.sidebar,
        border: Border(top: BorderSide(color: AkashaColors.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AkashaSpacing.md,
          AkashaSpacing.sm,
          AkashaSpacing.sm,
          10,
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onOpenDetail,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkashaSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AkashaColors.borderSubtle(0.04),
                    borderRadius: AkashaRadius.mdBorder,
                    border: Border.all(color: AkashaColors.borderSubtle(0.06)),
                  ),
                  child: Text(
                    l10n?.hintMemoBar ?? '메모를 추가하세요…',
                    style: AkashaTypography.bodySecondary,
                  ),
                ),
              ),
            ),
            SizedBox(width: AkashaSpacing.xs + 2),
            IconButton(
              onPressed: onOpenDetail,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: AkashaColors.accent,
              tooltip: l10n?.actionWrite ?? '기록하기',
            ),
          ],
        ),
      ),
    );
  }
}
