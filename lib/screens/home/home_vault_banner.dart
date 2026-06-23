import 'package:flutter/material.dart';

/// 볼트 미연동 시 compact 안내 (R4-A3 — Hero 시선 우선).
class HomeVaultBanner extends StatelessWidget {
  final VoidCallback onConnectVault;

  const HomeVaultBanner({super.key, required this.onConnectVault});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onConnectVault,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber.withValues(alpha: 0.75),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '카탈로그로 탐험 중입니다. 기록을 저장하려면 로컬 폴더를 연결하세요.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.amber.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
