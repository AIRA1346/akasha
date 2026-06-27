import 'package:flutter/material.dart';

import '../../theme/akasha_colors.dart';
import '../../theme/akasha_spacing.dart';
import '../../theme/akasha_typography.dart';

/// 볼트 미연동 시 compact 안내 (R4-A3 — Hero 시선 우선).
class HomeVaultBanner extends StatelessWidget {
  final VoidCallback onConnectVault;

  const HomeVaultBanner({super.key, required this.onConnectVault});

  @override
  Widget build(BuildContext context) {
    final tint = AkashaColors.statusWarning;
    return Material(
      color: tint.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onConnectVault,
        child: Padding(
          padding: AkashaSpacing.vaultBanner,
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: tint.withValues(alpha: 0.75),
                size: 14,
              ),
              SizedBox(width: AkashaSpacing.sm),
              Expanded(
                child: Text(
                  '카탈로그로 탐험 중입니다. 기록을 저장하려면 로컬 폴더를 연결하세요.',
                  style: AkashaTypography.caption.copyWith(
                    color: tint.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AkashaSpacing.lg,
                color: tint.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
