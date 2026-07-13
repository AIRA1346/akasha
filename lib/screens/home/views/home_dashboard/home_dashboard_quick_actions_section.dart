import 'package:flutter/material.dart';

import '../../../../config/feature_flags.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/app_l10n.dart';
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

  static const panelKey = ValueKey('home-dashboard-quick-actions-panel');
  static const gridKey = ValueKey('home-dashboard-quick-actions-grid');
  static ValueKey<String> actionKey(String id) =>
      ValueKey<String>('home-dashboard-quick-action-$id');

  final VoidCallback onSearch;
  final VoidCallback onExploreEntities;
  final VoidCallback onGoExplore;
  final VoidCallback onGoKnowledgeGraph;
  final VoidCallback onTimeline;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final actions = [
      (
        id: 'search',
        icon: Icons.search_rounded,
        title: l10n?.labelDashboardSearchWorks ?? '작품 검색',
        description:
            l10n?.descDashboardSearchWorks ?? '볼트·카탈로그에서 작품과 인물을 찾습니다.',
        onTap: onSearch,
      ),
      (
        id: 'entities',
        icon: Icons.person_search_outlined,
        title: l10n?.labelDashboardExploreEntities ?? '인물 탐색',
        description:
            l10n?.descDashboardExploreEntities ?? '등록된 인물 엔티티를 갤러리로 봅니다.',
        onTap: onExploreEntities,
      ),
      if (FeatureFlags.showKnowledgeGraph)
        (
          id: 'graph',
          icon: Icons.hub_outlined,
          title: l10n?.labelDashboardConnectionMap ?? '연결 맵',
          description:
              l10n?.descDashboardConnectionMap ??
              '볼트의 [[wiki]] 링크로 이어진 작품·인물 관계를 봅니다.',
          onTap: onGoKnowledgeGraph,
        )
      else
        (
          id: 'explore',
          icon: Icons.explore_outlined,
          title: l10n?.labelDashboardAllBrowse ?? '전체 탐색',
          description: l10n?.descDashboardAllBrowse ?? '라이브러리 작품을 그리드로 탐색합니다.',
          onTap: onGoExplore,
        ),
      if (FeatureFlags.showTimeline)
        (
          id: 'timeline',
          icon: Icons.access_time_outlined,
          title: l10n?.labelDashboardWrite ?? '기록',
          description: l10n?.descDashboardWrite ?? '타임라인과 일지에서 시간순 기록을 확인합니다.',
          onTap: onTimeline,
        ),
    ];

    return DecoratedBox(
      key: panelKey,
      decoration: palette.surfaceCard(radius: AkashaRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeDashboardStyles.sectionHeader(
              context,
              l10n?.labelDashboardQuickActions ?? '빠른 액션',
            ),
            const SizedBox(height: AkashaSpacing.md),
            LayoutBuilder(
              key: gridKey,
              builder: (context, constraints) {
                final int columns = constraints.maxWidth >= 920
                    ? actions.length
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                const gap = AkashaSpacing.md;
                final tileWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var index = 0; index < actions.length; index++)
                      SizedBox(
                        key: actionKey(actions[index].id),
                        width: tileWidth,
                        height: 96,
                        child: FocusTraversalOrder(
                          order: NumericFocusOrder(index.toDouble()),
                          child: _ActionCard(
                            icon: actions[index].icon,
                            title: actions[index].title,
                            description: actions[index].description,
                            onTap: actions[index].onTap,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  var _focused = false;
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final highlighted = _focused || _hovered;

    return Semantics(
      button: true,
      label: widget.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: highlighted ? palette.hoverSurface : palette.surfaceElevated,
          borderRadius: AkashaRadius.lgBorder,
          border: Border.all(
            color: _focused
                ? palette.focusRing
                : highlighted
                ? palette.borderSubtle(0.58)
                : palette.borderSubtle(0.28),
            width: _focused ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AkashaRadius.lgBorder,
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            onHover: (value) => setState(() => _hovered = value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AkashaSpacing.md,
                vertical: AkashaSpacing.md,
              ),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: AkashaRadius.mdBorder,
                    ),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(widget.icon, size: 20, color: palette.accent),
                    ),
                  ),
                  const SizedBox(width: AkashaSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AkashaTypography.buttonLabel.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AkashaSpacing.xs),
                        Text(
                          widget.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AkashaTypography.micro.copyWith(
                            color: palette.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AkashaSpacing.sm),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: highlighted ? palette.accent : palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
