import 'package:flutter/material.dart';

import '../../../services/works_registry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../utils/browse_category_groups.dart';
import '../../../utils/browse_section_filters.dart';
import '../../../utils/browse_year_groups.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/browse_dashboard_sections.dart';
import '../../../widgets/browse_poster_grid.dart';
import '../home_section_preferences.dart';
import '../../../models/browse_card.dart';

/// 비-개인서재(대시보드) browse 그리드·섹션 prefs 연동
class BrowseView extends StatelessWidget {
  const BrowseView({
    super.key,
    required this.filteredCards,
    required this.allItems,
    required this.sectionPrefs,
    required this.filterCategories,
    required this.isCatalogLoading,
    this.isCatalogLoadingMore = false,
    this.catalogHasMore = false,
    this.catalogLoadedThrough = 0,
    this.catalogTotalEntries = 0,
    this.onLoadMoreCatalog,
    required this.displayName,
    required this.posterCardBuilder,
    required this.onStateChanged,
  });

  final List<BrowseCard> filteredCards;
  final List<AkashaItem> allItems;
  final HomeSectionPreferences sectionPrefs;
  final Set<MediaCategory> filterCategories;
  final bool isCatalogLoading;
  final bool isCatalogLoadingMore;
  final bool catalogHasMore;
  final int catalogLoadedThrough;
  final int catalogTotalEntries;
  final VoidCallback? onLoadMoreCatalog;
  final String displayName;
  final Widget Function(BrowseCard card) posterCardBuilder;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    if (isCatalogLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              '글로벌 작품 사전 불러오는 중…',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (filteredCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text(
              '조건에 맞는 작품이 없습니다.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final catalogCards =
        sortBrowseCards(filteredCards, sectionPrefs.librarySort);
    final watchlistCards = sortBrowseCards(
      filterWatchlistCards(filteredCards, allItems),
      sectionPrefs.watchlistSort,
    );
    final categoryGroups = BrowseCategoryGroups.fromCards(
      catalogCards,
      sectionPrefs.librarySort,
      restrictToCategories: filterCategories,
    );
    final yearGroups = BrowseYearGroups.fromLibraryCards(
      filteredCards,
      sectionPrefs.yearlySort,
    );

    return BrowseDashboardSections(
      hofCards: const [],
      libraryCards: catalogCards,
      watchlistCards: watchlistCards,
      yearGroups: yearGroups,
      categoryGroups: categoryGroups,
      displayName: displayName,
      isPersonalLibraryMode: false,
      curatedLibrarySort: false,
      showHallOfFame: false,
      showWatchlist: false,
      hofExpanded: sectionPrefs.hofExpanded,
      libraryExpanded: sectionPrefs.libraryExpanded,
      yearlyExpanded: sectionPrefs.yearlyExpanded,
      watchlistExpanded: sectionPrefs.watchlistExpanded,
      hofSortCriteria: sectionPrefs.hofSort,
      librarySortCriteria: sectionPrefs.librarySort,
      yearlySortCriteria: sectionPrefs.yearlySort,
      watchlistSortCriteria: sectionPrefs.watchlistSort,
      onHofExpandedChanged: (v) =>
          sectionPrefs.setHofExpanded(v, onStateChanged),
      onLibraryExpandedChanged: (v) =>
          sectionPrefs.setLibraryExpanded(v, onStateChanged),
      onYearlyExpandedChanged: (v) =>
          sectionPrefs.setYearlyExpanded(v, onStateChanged),
      onWatchlistExpandedChanged: (v) =>
          sectionPrefs.setWatchlistExpanded(v, onStateChanged),
      onHofSortChanged: (val) => sectionPrefs.setHofSort(val, onStateChanged),
      onLibrarySortChanged: (val) =>
          sectionPrefs.setLibrarySort(val, onStateChanged),
      onYearlySortChanged: (val) =>
          sectionPrefs.setYearlySort(val, onStateChanged),
      onWatchlistSortChanged: (val) =>
          sectionPrefs.setWatchlistSort(val, onStateChanged),
      catalogCategoryExpanded: sectionPrefs.isCatalogCategoryExpanded,
      onCatalogCategoryExpandedChanged: (category, expanded) =>
          sectionPrefs.setCatalogCategoryExpanded(
            category,
            expanded,
            onStateChanged,
          ),
      posterCardBuilder: posterCardBuilder,
      gridBuilder: (cards) => BrowsePosterGrid(
        cards: cards,
        cardBuilder: posterCardBuilder,
        cardMinWidth: 176,
        childAspectRatio: 0.78,
      ),
      catalogFooter: catalogUsesWindowedFooter
          ? _CatalogWindowFooter(
              loadedThrough: catalogLoadedThrough,
              totalEntries: catalogTotalEntries,
              hasMore: catalogHasMore,
              isLoadingMore: isCatalogLoadingMore,
              onLoadMore: onLoadMoreCatalog,
            )
          : null,
    );
  }

  bool get catalogUsesWindowedFooter =>
      catalogTotalEntries > 0 && onLoadMoreCatalog != null;
}

class _CatalogWindowFooter extends StatelessWidget {
  const _CatalogWindowFooter({
    required this.loadedThrough,
    required this.totalEntries,
    required this.hasMore,
    required this.isLoadingMore,
    this.onLoadMore,
  });

  final int loadedThrough;
  final int totalEntries;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Text(
            '글로벌 사전 $loadedThrough / $totalEntries 작품 색인 로드됨',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: isLoadingMore ? null : onLoadMore,
              child: isLoadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '더 불러오기 (+${WorksRegistry.browsePrefetchWindowSize})',
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
