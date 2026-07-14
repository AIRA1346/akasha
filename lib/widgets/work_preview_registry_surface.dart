import 'package:flutter/material.dart';

import '../theme/akasha_palette.dart';
import '../theme/akasha_radius.dart';
import '../theme/akasha_spacing.dart';
import '../theme/akasha_typography.dart';
import '../utils/app_l10n.dart';

/// Registry-only Work Preview 배너 · 아카이브 CTA (R11 P2).
class WorkPreviewRegistrySurface extends StatelessWidget {
  const WorkPreviewRegistrySurface({
    super.key,
    required this.onArchive,
    this.archiving = false,
  });

  final VoidCallback? onArchive;
  final bool archiving;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: AkashaSpacing.md),
      padding: const EdgeInsets.all(AkashaSpacing.md),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: AkashaRadius.lgBorder,
        border: Border.all(color: palette.borderSubtle(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                size: 16,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AkashaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.previewCatalogWorkTitle ?? '사전 작품',
                      style: AkashaTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.previewCatalogWorkDescription ??
                          '아직 내 볼트에 없습니다. 아카이브하면 기록과 연결을 시작할 수 있습니다.',
                      style: AkashaTypography.micro.copyWith(
                        color: palette.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onArchive != null) ...[
            const SizedBox(height: AkashaSpacing.sm + 2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: archiving ? null : onArchive,
                icon: archiving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.archive_outlined, size: 14),
                label: Text(l10n?.actionArchive ?? '아카이브'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: palette.borderSubtle(0.42)),
                  foregroundColor: palette.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
