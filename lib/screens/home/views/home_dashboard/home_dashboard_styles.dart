import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_typography.dart';

/// 홈 대시보드 공통 스타일·헬퍼 (R14-B → `AkashaTypography` 위임).
abstract final class HomeDashboardStyles {
  static const sectionTitle = AkashaTypography.dashboardSectionTitle;
  static const panelTitle = AkashaTypography.dashboardPanelTitle;

  static Color categoryColor(AkashaItem item, AkashaPalette palette) {
    if (item is! EntityItem) return palette.accent;
    return switch (item.entityType.name) {
      'person' => palette.info,
      'concept' => palette.accent,
      'place' => palette.success,
      'event' => palette.warning,
      'organization' => Color.lerp(palette.accent, palette.info, 0.5)!,
      'object' => palette.textMuted,
      _ => palette.accent,
    };
  }

  static Widget sectionHeader(
    BuildContext context,
    String title, {
    String? countLabel,
  }) {
    final palette = context.akashaPalette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: sectionTitle.copyWith(color: palette.textPrimary)),
        if (countLabel != null) ...[
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                countLabel,
                style: AkashaTypography.micro.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
