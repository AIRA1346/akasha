import 'package:flutter/material.dart';

import '../../../../config/feature_flags.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_typography.dart';
import 'home_dashboard_styles.dart';
import '../../../../utils/app_l10n.dart';

class HomeDashboardQuickActionsSection extends StatelessWidget {
  const HomeDashboardQuickActionsSection({
    super.key,
    required this.onSearch,
    required this.onExploreEntities,
    required this.onGoExplore,
    required this.onGoKnowledgeGraph,
    required this.onTimeline,
  });

  final VoidCallback onSearch;
  final VoidCallback onExploreEntities;
  final VoidCallback onGoExplore;
  final VoidCallback onGoKnowledgeGraph;
  final VoidCallback onTimeline;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader(
          l10n?.labelDashboardQuickActions ?? '빠른 액션',
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: l10n?.labelDashboardSearchWorks ?? '작품 검색',
                    desc:
                        l10n?.descDashboardSearchWorks ??
                        '볼트·카탈로그에서 작품과 인물을 찾습니다.',
                    onTap: onSearch,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.person_search_outlined,
                    title: l10n?.labelDashboardExploreEntities ?? '인물 탐색',
                    desc:
                        l10n?.descDashboardExploreEntities ??
                        '등록된 인물 엔티티를 갤러리로 봅니다.',
                    onTap: onExploreEntities,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FeatureFlags.showKnowledgeGraph
                      ? _ActionCard(
                          icon: Icons.hub_outlined,
                          title: l10n?.labelDashboardConnectionMap ?? '연결 맵',
                          desc:
                              l10n?.descDashboardConnectionMap ??
                              '볼트의 [[wiki]] 링크로 이어진 작품·인물 관계를 봅니다.',
                          onTap: onGoKnowledgeGraph,
                        )
                      : _ActionCard(
                          icon: Icons.explore_outlined,
                          title: l10n?.labelDashboardAllBrowse ?? '전체 탐색',
                          desc:
                              l10n?.descDashboardAllBrowse ??
                              '라이브러리 작품을 그리드로 탐색합니다.',
                          onTap: onGoExplore,
                        ),
                ),
                if (FeatureFlags.showTimeline) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.access_time_outlined,
                      title: l10n?.labelDashboardWrite ?? '기록',
                      desc:
                          l10n?.descDashboardWrite ??
                          '타임라인과 일지에서 시간순 기록을 확인합니다.',
                      onTap: onTimeline,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    return Container(
      decoration: palette.surfaceCard(radius: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: palette.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AkashaTypography.buttonLabel.copyWith(
                          color: AkashaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: AkashaTypography.micro.copyWith(
                          color: AkashaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
