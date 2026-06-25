import 'package:flutter/material.dart';

import '../../../../theme/akasha_colors.dart';

class HomeDashboardTopBar extends StatelessWidget {
  const HomeDashboardTopBar({
    super.key,
    required this.onSearch,
    required this.onVaultSettings,
  });

  final VoidCallback onSearch;
  final VoidCallback onVaultSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSearch,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AkashaColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AkashaColors.borderSubtle(0.06)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: AkashaColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '작품, 인물, 사건, 장소, 개념을 검색하세요...',
                      style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AkashaColors.borderSubtle(0.06)),
                    ),
                    child: Text(
                      'Ctrl K',
                      style: TextStyle(
                        fontSize: 9,
                        color: AkashaColors.textMuted,
                        fontFamily: 'Consolas',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: onVaultSettings,
          tooltip: '볼트 설정',
          icon: Icon(Icons.settings_outlined, size: 18, color: AkashaColors.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'https://images.justwatch.com/poster/8734024/s592/re-jeborobuteo-sijaghaneun-isegye-saenghwal.jpg',
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
