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
    required this.onTimeline,
  });

  final VoidCallback onSearch;
  final VoidCallback onExploreEntities;
  final VoidCallback onGoExplore;
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
                    desc: '새로운 이세계 지식을 검색하고 라이브러리에 등록하세요.',
                    onTap: onSearch,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.person_search_outlined,
                    title: '인물 탐색',
                    desc: '이세계에 존재하는 매력적인 주인공들과 그 관계를 분석합니다.',
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
                          title: '그래프 탐색 [Beta]',
                          desc: '연결된 사건과 지식의 성운을 입체적인 망으로 보여줍니다.',
                          onTap: onGoExplore,
                        )
                      : _ActionCard(
                          icon: Icons.explore_outlined,
                          title: '전체 탐색',
                          desc: '라이브러리의 모든 작품을 그리드로 탐색합니다.',
                          onTap: onGoExplore,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.access_time_outlined,
                    title: '타임라인',
                    desc: '각 작품과 사건이 발생한 역사적 순서의 궤적을 확인합니다.',
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
