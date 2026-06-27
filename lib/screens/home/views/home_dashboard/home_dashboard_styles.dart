import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_typography.dart';

/// 홈 대시보드 공통 스타일·헬퍼 (R14-B → `AkashaTypography` 위임).
abstract final class HomeDashboardStyles {
  static const sectionTitle = AkashaTypography.dashboardSectionTitle;
  static const panelTitle = AkashaTypography.dashboardPanelTitle;

  static Color categoryColor(AkashaItem item) => categoryColorFor(item.category.name);

  static Color categoryColorFor(String category) {
    switch (category) {
      case '인물':
        return AkashaColors.personAccent;
      case '개념':
        return AkashaColors.conceptAccent;
      case '장소':
        return AkashaColors.placeAccent;
      case '사건':
        return AkashaColors.eventAccent;
      default:
        return AkashaColors.accent;
    }
  }

  static Widget sectionHeader(String title) {
    return Text(title, style: sectionTitle);
  }
}
