part of 'browse_dashboard_sections.dart';

List<Widget> _buildHofSlivers(
  BrowseDashboardSections section,
  BrowseGridMetrics metrics,
) {
  if (!section.showHallOfFame || section.hofCards.isEmpty) return const [];

  final slivers = <Widget>[
    SliverToBoxAdapter(
      child: _sectionHeader(
        emoji: '👑',
        title: 'S-Tier 인생 명작 컬렉션 (Hall of Fame)',
        titleColor: const Color(0xFFFFD700),
        expanded: section.hofExpanded,
        onExpandedChanged: section.onHofExpandedChanged,
        sortCriteria: section.hofSortCriteria,
        onSortChanged: section.onHofSortChanged,
      ),
    ),
  ];

  if (section.hofExpanded) {
    slivers.add(
      SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.hofCards.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 165,
                child: section.posterCardBuilder(section.hofCards[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
  return slivers;
}
