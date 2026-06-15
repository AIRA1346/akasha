import 'package:flutter/material.dart';

import '../screens/home/dialogs/work_library_menu.dart';
import '../models/browse_card.dart';
import '../models/enums.dart';
import '../utils/browse_category_groups.dart';
import '../utils/browse_year_groups.dart';
import '../utils/helpers.dart';
import 'section_header.dart';
import 'section_sort_dropdown.dart';

/// 홈 대시보드 browse 섹션 (카탈로그 · 연도별 · watchlist)
class BrowseDashboardSections extends StatelessWidget {
  final List<BrowseCard> hofCards;
  final List<BrowseCard> libraryCards;
  final List<BrowseCard> watchlistCards;
  final BrowseYearGroups yearGroups;
  final BrowseCategoryGroups? categoryGroups;
  final String displayName;

  final bool showHallOfFame;
  final bool showWatchlist;
  final bool hofExpanded;
  final bool libraryExpanded;
  final bool yearlyExpanded;
  final bool watchlistExpanded;

  final SortCriteria hofSortCriteria;
  final SortCriteria librarySortCriteria;
  final SortCriteria yearlySortCriteria;
  final SortCriteria watchlistSortCriteria;

  final ValueChanged<bool> onHofExpandedChanged;
  final ValueChanged<bool> onLibraryExpandedChanged;
  final ValueChanged<bool> onYearlyExpandedChanged;
  final ValueChanged<bool> onWatchlistExpandedChanged;

  final ValueChanged<SortCriteria> onHofSortChanged;
  final ValueChanged<SortCriteria> onLibrarySortChanged;
  final ValueChanged<SortCriteria> onYearlySortChanged;
  final ValueChanged<SortCriteria> onWatchlistSortChanged;

  final Widget Function(BrowseCard card) posterCardBuilder;
  final Widget Function(List<BrowseCard> cards) gridBuilder;
  final bool isPersonalLibraryMode;
  final bool curatedLibrarySort;
  final Widget? catalogFooter;
  final bool Function(MediaCategory category)? catalogCategoryExpanded;
  final void Function(MediaCategory category, bool expanded)?
      onCatalogCategoryExpandedChanged;

  const BrowseDashboardSections({
    super.key,
    required this.hofCards,
    required this.libraryCards,
    required this.watchlistCards,
    required this.yearGroups,
    this.categoryGroups,
    required this.displayName,
    this.showHallOfFame = true,
    this.showWatchlist = true,
    required this.hofExpanded,
    required this.libraryExpanded,
    required this.yearlyExpanded,
    required this.watchlistExpanded,
    required this.hofSortCriteria,
    required this.librarySortCriteria,
    required this.yearlySortCriteria,
    required this.watchlistSortCriteria,
    required this.onHofExpandedChanged,
    required this.onLibraryExpandedChanged,
    required this.onYearlyExpandedChanged,
    required this.onWatchlistExpandedChanged,
    required this.onHofSortChanged,
    required this.onLibrarySortChanged,
    required this.onYearlySortChanged,
    required this.onWatchlistSortChanged,
    required this.posterCardBuilder,
    required this.gridBuilder,
    this.isPersonalLibraryMode = false,
    this.curatedLibrarySort = false,
    this.catalogFooter,
    this.catalogCategoryExpanded,
    this.onCatalogCategoryExpandedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isWorkLibraryMenuOpen && notification is UserScrollNotification) {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
        return false;
      },
      child: ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (showHallOfFame && hofCards.isNotEmpty) ...[
          _sectionHeader(
            emoji: '👑',
            title: 'S-Tier 인생 명작 컬렉션 (Hall of Fame)',
            titleColor: const Color(0xFFFFD700),
            expanded: hofExpanded,
            onExpandedChanged: onHofExpandedChanged,
            sortCriteria: hofSortCriteria,
            onSortChanged: onHofSortChanged,
          ),
          if (hofExpanded)
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hofCards.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 165,
                    child: posterCardBuilder(hofCards[i]),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (libraryCards.isNotEmpty) ...[
          _sectionHeader(
            emoji: '📚',
            title: isPersonalLibraryMode
                ? '내 아카이브'
                : '작품 카탈로그 (사전 + 아카이브)',
            titleColor: isPersonalLibraryMode
                ? const Color(0xFFFFB74D)
                : const Color(0xFFF09819),
            subtitle: isPersonalLibraryMode
                ? '${libraryCards.length}개 아카이브 작품'
                : categoryGroups != null
                    ? '${libraryCards.length}개 표시 · 매체별로 정렬 · 아카이브된 작품은 카드에 표시됩니다'
                    : '${libraryCards.length}개 표시 · 엄선 아카이브는 사이드바 「나만의 서재」를 이용하세요.',
            expanded: libraryExpanded,
            onExpandedChanged: onLibraryExpandedChanged,
            sortCriteria: librarySortCriteria,
            onSortChanged: onLibrarySortChanged,
            sortOptions: curatedLibrarySort
                ? SortCriteria.curatedLibraryCriteria
                : SortCriteria.standardViewCriteria,
          ),
          if (libraryExpanded) ...[
            if (categoryGroups != null)
              for (final category in categoryGroups!.orderedCategories) ...[
                _catalogCategoryHeader(category),
                if (_isCatalogCategoryExpanded(category))
                  gridBuilder(categoryGroups!.byCategory[category]!),
              ]
            else
              gridBuilder(libraryCards),
            ?catalogFooter,
          ],
          const SizedBox(height: 16),
        ],
        if (libraryCards.isNotEmpty) ...[
          _sectionHeader(
            emoji: '🗓️',
            title: '연도별 라이브러리 (Yearly Chronological Library)',
            titleColor: const Color(0xFFF09819),
            subtitle: '출시 연도별로 크로놀로지컬하게 정렬된 라이브러리입니다.',
            expanded: yearlyExpanded,
            onExpandedChanged: onYearlyExpandedChanged,
            sortCriteria: yearlySortCriteria,
            onSortChanged: onYearlySortChanged,
          ),
          if (yearlyExpanded) ...[
            for (final year in yearGroups.sortedYears) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '🗓️ $year년',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${yearGroups.byYear[year]!.length}개 작품)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              gridBuilder(yearGroups.byYear[year]!),
            ],
            if (yearGroups.noYear.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
                child: Row(
                  children: [
                    const Text(
                      '🗓️ 연도 미지정',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${yearGroups.noYear.length}개 작품)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              gridBuilder(yearGroups.noYear),
            ],
          ],
          const SizedBox(height: 16),
        ],
        if (showWatchlist) ...[
          _sectionHeader(
            emoji: '⌛',
            title: '감상 예정 보관함 (Watchlist)',
            titleColor: const Color(0xFFF09819),
            subtitle:
                '$displayName 님이 감상하기 위해 아껴두었거나, 나중에 꼭 감상하여 아카이빙할 예정인 작품 리스트입니다. 작품 문서 내에 status: "볼 예정"으로 설정하시면 자동으로 이 리스트에 꽂히게 됩니다.',
            expanded: watchlistExpanded,
            onExpandedChanged: onWatchlistExpandedChanged,
            sortCriteria: watchlistSortCriteria,
            onSortChanged: onWatchlistSortChanged,
          ),
          if (watchlistExpanded) ...[
            if (watchlistCards.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            else
              gridBuilder(watchlistCards),
          ],
        ],
      ],
    ),
    );
  }

  bool _isCatalogCategoryExpanded(MediaCategory category) {
    if (catalogCategoryExpanded == null) return true;
    return catalogCategoryExpanded!(category);
  }

  Widget _catalogCategoryHeader(MediaCategory category) {
    final expanded = _isCatalogCategoryExpanded(category);
    final count = categoryGroups!.byCategory[category]!.length;
    return GestureDetector(
      onTap: onCatalogCategoryExpandedChanged == null
          ? null
          : () => onCatalogCategoryExpandedChanged!(category, !expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
        child: Row(
          children: [
            if (onCatalogCategoryExpandedChanged != null) ...[
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
                color: Colors.grey[400],
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
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String emoji,
    required String title,
    required Color titleColor,
    String? subtitle,
    required bool expanded,
    required ValueChanged<bool> onExpandedChanged,
    required SortCriteria sortCriteria,
    required ValueChanged<SortCriteria> onSortChanged,
    List<SortCriteria> sortOptions = SortCriteria.standardViewCriteria,
  }) {
    return GestureDetector(
      onTap: () => onExpandedChanged(!expanded),
      child: SectionHeader(
        emoji: emoji,
        title: title,
        titleColor: titleColor,
        subtitle: subtitle,
        isExpanded: expanded,
        trailing: SectionSortDropdown(
          currentCriteria: sortOptions.contains(sortCriteria)
              ? sortCriteria
              : sortOptions.first,
          onChanged: onSortChanged,
          options: sortOptions,
        ),
      ),
    );
  }
}
