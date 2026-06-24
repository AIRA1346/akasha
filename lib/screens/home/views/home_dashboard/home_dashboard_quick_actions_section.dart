import 'package:flutter/material.dart';

import '../../../../config/feature_flags.dart';
import '../../../../theme/akasha_colors.dart';
import 'home_dashboard_styles.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader('빠른 액션'),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: '작품 검색',
                    desc: '볼트·카탈로그에서 작품과 인물을 찾습니다.',
                    onTap: onSearch,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.person_search_outlined,
                    title: '인물 탐색',
                    desc: '등록된 인물 엔티티를 갤러리로 봅니다.',
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
                          title: '연결 맵',
                          desc: '볼트의 [[wiki]] 링크로 이어진 작품·인물 관계를 봅니다.',
                          onTap: onGoKnowledgeGraph,
                        )
                      : _ActionCard(
                          icon: Icons.explore_outlined,
                          title: '전체 탐색',
                          desc: '라이브러리 작품을 그리드로 탐색합니다.',
                          onTap: onGoExplore,
                        ),
                ),
                const SizedBox(width: 12),
                if (FeatureFlags.showTimeline)
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.access_time_outlined,
                      title: '기록',
                      desc: '타임라인과 일지에서 시간순 기록을 확인합니다.',
                      onTap: onTimeline,
                    ),
                  ),
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
    return Container(
      decoration: AkashaColors.surfaceCard(radius: 10),
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
                    color: AkashaColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: AkashaColors.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
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
