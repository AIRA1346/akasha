import 'package:flutter/material.dart';

import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';

/// 홈 최상단 — 30초 narrative + Primary CTA (R4-A1).
class HomeDashboardHero extends StatelessWidget {
  const HomeDashboardHero({
    super.key,
    required this.onStartExplore,
  });

  final VoidCallback onStartExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '기록하고, 연결하고, 발견하세요',
          style: AkashaTypography.dashboardHero.copyWith(height: 1.25),
        ),
        SizedBox(height: AkashaSpacing.sm),
        Text(
          '작품, 사람, 사건, 개념을 기록하면 연결이 생기고 새로운 발견으로 이어집니다.',
          style: AkashaTypography.body.copyWith(
            color: AkashaColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onStartExplore,
          style: FilledButton.styleFrom(
            backgroundColor: AkashaColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '탐험 시작하기',
            style: AkashaTypography.dashboardLead.copyWith(
              fontWeight: FontWeight.bold,
              color: AkashaColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
