part of 'browse_dashboard_sections.dart';

List<Widget> _buildWatchlistSlivers(
  BrowseDashboardSections section,
  BrowseGridMetrics metrics,
) {
  return [
    SliverToBoxAdapter(
      child: _sectionHeader(
        emoji: '⌛',
        title: '감상 예정 보관함 (Watchlist)',
        titleColor: const Color(0xFFF09819),
        subtitle:
            '${section.displayName} 님이 감상하기 위해 아껴두었거나, 나중에 꼭 감상하여 아카이빙할 예정인 작품 리스트입니다. 작품 문서 내에 status: "볼 예정"으로 설정하시면 자동으로 이 리스트에 꽂히게 됩니다.',
        expanded: section.watchlistExpanded,
        onExpandedChanged: section.onWatchlistExpandedChanged,
        sortCriteria: section.watchlistSortCriteria,
        onSortChanged: section.onWatchlistSortChanged,
      ),
    ),
    if (section.watchlistExpanded) ...[
      if (section.watchlistCards.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 44,
                    color: Colors.amber.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '아직 감상 예정 보관함이 비어 있습니다.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '새로운 작품을 추가하거나 작품 편집에서 나의 상태를 "볼 예정"으로 설정하면 자동으로 이곳에 정렬됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AkashaColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        ..._cardGridSlivers(section, section.watchlistCards, metrics),
    ],
  ];
}
