part of 'browse_dashboard_sections.dart';

List<Widget> _buildLibrarySectionSlivers(
  BrowseDashboardSections section,
  BrowseGridMetrics metrics,
) {
  final slivers = <Widget>[
    SliverToBoxAdapter(
      child: _sectionHeader(
        emoji: '📚',
        title: section.isPersonalLibraryMode
            ? '내 아카이브'
            : '작품 카탈로그 (사전 + 아카이브)',
        titleColor: section.isPersonalLibraryMode
            ? const Color(0xFFFFB74D)
            : const Color(0xFFF09819),
        subtitle: section.isPersonalLibraryMode
            ? '${section.libraryCards.length}개 아카이브 작품'
            : section.categoryGroups != null
                ? '${section.libraryCards.length}개 표시 · 매체별로 정렬 · 아카이브된 작품은 카드에 표시됩니다'
                : '${section.libraryCards.length}개 표시 · 엄선 아카이브는 사이드바 「나만의 서재」를 이용하세요.',
        expanded: section.libraryExpanded,
        onExpandedChanged: section.onLibraryExpandedChanged,
        sortCriteria: section.librarySortCriteria,
        onSortChanged: section.onLibrarySortChanged,
        sortOptions: section.curatedLibrarySort
            ? SortCriteria.curatedLibraryCriteria
            : SortCriteria.standardViewCriteria,
      ),
    ),
  ];

  if (section.libraryExpanded) {
    slivers.addAll(_buildLibrarySlivers(section, metrics));
    if (section.catalogFooter != null) {
      slivers.add(SliverToBoxAdapter(child: section.catalogFooter));
    }
  }

  slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
  return slivers;
}

List<Widget> _buildLibrarySlivers(
  BrowseDashboardSections section,
  BrowseGridMetrics metrics,
) {
  if (section.categoryGroups != null) {
    final slivers = <Widget>[];
    for (final category in section.categoryGroups!.orderedCategories) {
      slivers.add(
        SliverToBoxAdapter(child: _catalogCategoryHeader(section, category)),
      );
      if (_isCatalogCategoryExpanded(section, category)) {
        slivers.addAll(
          _cardGridSlivers(
            section,
            section.categoryGroups!.byCategory[category]!,
            metrics,
          ),
        );
      }
    }
    return slivers;
  }

  if (section.useCuratedLibraryReorder &&
      section.onCuratedLibraryReorder != null &&
      section.libraryCards.length > 1) {
    return [
      SliverToBoxAdapter(
        child: CuratedReorderGrid(
          cards: section.libraryCards,
          cardBuilder: section.posterCardBuilder,
          cardMinWidth: section.cardMinWidth,
          childAspectRatio: section.childAspectRatio,
          onReorder: section.onCuratedLibraryReorder!,
        ),
      ),
    ];
  }

  return _cardGridSlivers(section, section.libraryCards, metrics);
}

bool _isCatalogCategoryExpanded(
  BrowseDashboardSections section,
  MediaCategory category,
) {
  if (section.catalogCategoryExpanded == null) return true;
  return section.catalogCategoryExpanded!(category);
}

Widget _catalogCategoryHeader(
  BrowseDashboardSections section,
  MediaCategory category,
) {
  final expanded = _isCatalogCategoryExpanded(section, category);
  final count = section.categoryGroups!.byCategory[category]!.length;
  return GestureDetector(
    onTap: section.onCatalogCategoryExpandedChanged == null
        ? null
        : () => section.onCatalogCategoryExpandedChanged!(category, !expanded),
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
      child: Row(
        children: [
          if (section.onCatalogCategoryExpandedChanged != null) ...[
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              size: 20,
              color: AkashaColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            category.icon,
            size: 18,
            color: Colors.orangeAccent.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count개 작품)',
            style: TextStyle(fontSize: 12, color: AkashaColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
