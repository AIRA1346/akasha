import 'package:flutter/material.dart';

import '../../theme/akasha_colors.dart';
import '../../theme/akasha_spacing.dart';
import '../../theme/akasha_typography.dart';
import '../../utils/app_l10n.dart';

/// 볼트 미연동 시 안내 배너 (R4-A3).
///
/// 이제 기본 아카이브 생성 단추(Vault Quick Start)와 기존 폴더 연결 보조 단추를 제공합니다.
class HomeVaultBanner extends StatefulWidget {
  final VoidCallback onConnectVault;
  final VoidCallback onCreateDefaultVault;

  const HomeVaultBanner({
    super.key,
    required this.onConnectVault,
    required this.onCreateDefaultVault,
  });

  @override
  State<HomeVaultBanner> createState() => _HomeVaultBannerState();
}

class _HomeVaultBannerState extends State<HomeVaultBanner> {
  bool _isCreating = false;

  Future<void> _handleCreateDefaultVault() async {
    if (_isCreating) return;
    setState(() {
      _isCreating = true;
    });
    try {
      widget.onCreateDefaultVault();
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final tint = AkashaColors.statusWarning;
    return Material(
      color: tint.withValues(alpha: 0.06),
      child: InkWell(
        onTap: _isCreating ? null : widget.onConnectVault,
        child: Padding(
          padding: AkashaSpacing.vaultBanner,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: tint.withValues(alpha: 0.75),
                    size: 14,
                  ),
                  SizedBox(width: AkashaSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n?.homeVaultBannerExploringCatalog ??
                          '카탈로그로 탐험 중입니다. 기록을 저장하려면 로컬 폴더를 연결하세요.',
                      style: AkashaTypography.caption.copyWith(
                        color: tint.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {}, // Intercept tap bubbling
                    child: TextButton(
                      onPressed: _isCreating ? null : widget.onConnectVault,
                      child: Text(
                        l10n?.homeVaultBannerConnectExisting ?? '기존 폴더 연결',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {}, // Intercept tap bubbling
                    child: FilledButton.tonal(
                      onPressed: _isCreating ? null : _handleCreateDefaultVault,
                      child: _isCreating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l10n?.homeVaultBannerCreateDefault ??
                                  '기본 아카이브 만들기',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
