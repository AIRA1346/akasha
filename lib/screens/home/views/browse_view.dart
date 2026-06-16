import 'package:flutter/material.dart';

import '../../../services/works_registry.dart';
import '../../../models/enums.dart';
import '../../../utils/browse_category_groups.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/browse_dashboard_sections.dart';
import '../home_section_preferences.dart';
import '../../../models/browse_card.dart';

/// 비-개인서재(대시보드) browse 그리드·섹션 prefs 연동
class BrowseView extends StatefulWidget {
  const BrowseView({
    super.key,
    required this.filteredCards,
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
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCatalogLoading) {
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

    if (widget.filteredCards.isEmpty) {
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

    final sectionPrefs = widget.sectionPrefs;
    final catalogCards =
        sortBrowseCards(widget.filteredCards, sectionPrefs.librarySort);
    final categoryGroups = BrowseCategoryGroups.fromCards(
      catalogCards,
      sectionPrefs.librarySort,
      restrictToCategories: widget.filterCategories,
    );

    return BrowseDashboardSections(
      scrollController: _scrollController,
      cardMinWidth: 176,
      childAspectRatio: 0.78,
      hofCards: const [],
      libraryCards: catalogCards,
      watchlistCards: const [],
      categoryGroups: categoryGroups,
      displayName: widget.displayName,
      isPersonalLibraryMode: false,
      showHallOfFame: false,
      showWatchlist: false,
      showYearlySection: false,
      hofExpanded: sectionPrefs.hofExpanded,
      libraryExpanded: sectionPrefs.libraryExpanded,
      yearlyExpanded: false,
      watchlistExpanded: false,
      hofSortCriteria: sectionPrefs.hofSort,
      librarySortCriteria: sectionPrefs.librarySort,
      yearlySortCriteria: sectionPrefs.yearlySort,
      watchlistSortCriteria: sectionPrefs.watchlistSort,
      onHofExpandedChanged: (v) =>
          sectionPrefs.setHofExpanded(v, widget.onStateChanged),
      onLibraryExpandedChanged: (v) =>
          sectionPrefs.setLibraryExpanded(v, widget.onStateChanged),
      onWatchlistExpandedChanged: (_) {},
      onHofSortChanged: (val) =>
          sectionPrefs.setHofSort(val, widget.onStateChanged),
      onLibrarySortChanged: (val) =>
          sectionPrefs.setLibrarySort(val, widget.onStateChanged),
      onWatchlistSortChanged: (_) {},
      catalogCategoryExpanded: sectionPrefs.isCatalogCategoryExpanded,
      onCatalogCategoryExpandedChanged: (category, expanded) =>
          sectionPrefs.setCatalogCategoryExpanded(
            category,
            expanded,
            widget.onStateChanged,
          ),
      posterCardBuilder: widget.posterCardBuilder,
      catalogFooter: _catalogUsesWindowedFooter
          ? _CatalogWindowFooter(
              loadedThrough: widget.catalogLoadedThrough,
              totalEntries: widget.catalogTotalEntries,
              hasMore: widget.catalogHasMore,
              isLoadingMore: widget.isCatalogLoadingMore,
              onLoadMore: widget.onLoadMoreCatalog,
            )
          : null,
    );
  }

  bool get _catalogUsesWindowedFooter =>
      widget.catalogTotalEntries > 0 && widget.onLoadMoreCatalog != null;
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
