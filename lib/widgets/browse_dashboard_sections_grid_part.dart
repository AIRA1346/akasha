part of 'browse_dashboard_sections.dart';

List<Widget> _cardGridSlivers(
  BrowseDashboardSections section,
  List<BrowseCard> cards,
  BrowseGridMetrics metrics,
) {
  if (cards.isEmpty) return const [];

  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrowseGridMetrics.defaultHorizontalPadding,
        vertical: 8,
      ),
      sliver: SliverGrid(
        gridDelegate: metrics.gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (context, index) => KeyedSubtree(
            key: ValueKey(browseCardStableKey(cards[index])),
            child: section.posterCardBuilder(cards[index]),
          ),
          childCount: cards.length,
          findChildIndexCallback: (Key key) {
            if (key is! ValueKey<String>) return null;
            final index = cards.indexWhere(
              (card) => browseCardStableKey(card) == key.value,
            );
            return index >= 0 ? index : null;
          },
        ),
      ),
    ),
  ];
}
