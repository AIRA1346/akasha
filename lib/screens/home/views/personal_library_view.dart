import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/personal_library_config.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/personal_library_membership_service.dart';
import '../../../utils/browse_section_filters.dart';
import '../../../utils/browse_year_groups.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/browse_dashboard_sections.dart';
import '../home_personal_library_controller.dart';
import '../home_section_preferences.dart';
import '../../../models/browse_card.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

/// 개인 서재 그리드·curated reorder·섹션 prefs 연동
class PersonalLibraryView extends StatefulWidget {
  const PersonalLibraryView({
    super.key,
    required this.filteredCards,
    required this.allItems,
    required this.vaultLinked,
    required this.sectionPrefs,
    required this.displayName,
    required this.isCuratedLibraryActive,
    required this.activeLibrary,
    required this.posterCardBuilder,
    required this.onStateChanged,
    required this.onCuratedReorder,
    required this.onSearch,
  });

  final List<BrowseCard> filteredCards;
  final List<AkashaItem> allItems;
  final bool vaultLinked;
  final HomeSectionPreferences sectionPrefs;
  final String displayName;
  final bool isCuratedLibraryActive;
  final PersonalLibraryConfig? activeLibrary;
  final Widget Function(BrowseCard card) posterCardBuilder;
  final VoidCallback onStateChanged;
  final Future<void> Function(
    List<BrowseCard> visibleCards,
    int oldIndex,
    int newIndex,
  ) onCuratedReorder;
  final VoidCallback onSearch;

  @override
  State<PersonalLibraryView> createState() => _PersonalLibraryViewState();

  static Future<void> applyCuratedGridReorder({
    required PersonalLibraryMembershipService membership,
    required HomePersonalLibraryController personalLibCtrl,
    required List<BrowseCard> visibleCards,
    required int oldIndex,
    required int newIndex,
  }) async {
    final lib = personalLibCtrl.activeLibrary;
    if (lib == null || !lib.isCurated) return;

    final visibleIds = visibleCards
        .map((c) => c.item.workId.isNotEmpty
            ? c.item.workId
            : MarkdownParser.ensureWorkId(c.item))
        .toList();

    final newOrder = membership.reorderVisibleInOrder(
      fullOrder: List<String>.from(lib.memberOrder),
      visibleWorkIds: visibleIds,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );

    await membership.setMemberOrder(lib.id, newOrder);
  }
}

class _PersonalLibraryViewState extends State<PersonalLibraryView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildEmptyContent() {
    final l10n = lookupAppL10n(context);
    final vaultLinked = widget.vaultLinked;
    final library = widget.activeLibrary;
    final fallbackLibName = l10n?.libraryFallbackName ?? '나만의 서재';
    final libName = library?.name ?? fallbackLibName;
    final isCuratedEmpty =
        library != null && library.isCurated && library.memberOrder.isEmpty;
    final isFilterEmpty = library != null && !library.isCurated;
    final hasMembersButFiltered = library != null &&
        library.isCurated &&
        library.memberOrder.isNotEmpty &&
        vaultLinked;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vaultLinked
                  ? (isCuratedEmpty
                      ? Icons.collections_bookmark_outlined
                      : Icons.inventory_2_outlined)
                  : Icons.folder_off_outlined,
              size: 48,
              color: AkashaColors.textCaption,
            ),
            const SizedBox(height: 12),
            Text(
              !vaultLinked
                  ? (l10n?.libraryEmptyVaultTitle ?? '볼트를 연동하면 나만의 서재가 열립니다')
                  : isCuratedEmpty
                      ? (l10n?.libraryEmptyCuratedTitle ?? '작품을 담아 서재를 채워 보세요')
                      : hasMembersButFiltered
                          ? (l10n?.libraryEmptyFilterTitle ?? '필터 조건에 맞는 작품이 없습니다')
                          : isFilterEmpty
                              ? (l10n != null ? l10n.libraryEmptyArchiveDesc(libName) : '$libName에 표시할 아카이브 작품이 없습니다')
                              : (l10n != null ? l10n.libraryEmptyNoWorksDesc(libName) : '$libName에 표시할 작품이 없습니다'),
              style: AkashaTypography.dashboardSectionTitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              !vaultLinked
                  ? (l10n?.libraryEmptyVaultHelp ?? '홈 상단에서 Sanctum 볼트 폴더를 연동해 주세요.')
                  : isCuratedEmpty
                      ? (l10n?.libraryEmptyCuratedHelp ?? '검색으로 작품을 추가하거나, 카드 ⠿ 핸들을 서재로 끌어다 놓으세요.')
                      : hasMembersButFiltered
                          ? (l10n?.libraryEmptyFilterHelp ?? '상단 필터를 조정해 보세요.')
                          : (l10n?.libraryEmptyGeneralHelp ?? '검색으로 작품을 추가해 보세요.'),
              style: TextStyle(color: AkashaColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (vaultLinked && isCuratedEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.onSearch,
                icon: const Icon(Icons.search, size: 18),
                label: Text(l10n?.libraryBtnSearch ?? '작품 검색'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filteredCards.isEmpty) {
      return _buildEmptyContent();
    }

    final sectionPrefs = widget.sectionPrefs;
    final libraryFiltered =
        filterLibraryCards(widget.filteredCards, widget.allItems);
    final catalogCards = widget.isCuratedLibraryActive &&
            sectionPrefs.librarySort.isManualOrder
        ? libraryFiltered
        : sortBrowseCards(libraryFiltered, sectionPrefs.librarySort);
    final hofCards = sortBrowseCards(
      widget.filteredCards.where((c) => c.item.isHallOfFame).toList(),
      sectionPrefs.hofSort,
    );
    final watchlistCards = sortBrowseCards(
      filterWatchlistCards(widget.filteredCards, widget.allItems),
      sectionPrefs.watchlistSort,
    );
    final yearGroups = BrowseYearGroups.fromLibraryCards(
      catalogCards,
      sectionPrefs.yearlySort,
    );

    final useCuratedReorder = widget.isCuratedLibraryActive &&
        sectionPrefs.librarySort.isManualOrder &&
        catalogCards.length > 1;

    return BrowseDashboardSections(
      scrollController: _scrollController,
      cardMinWidth: 170,
      childAspectRatio: 0.48,
      hofCards: hofCards,
      libraryCards: catalogCards,
      watchlistCards: watchlistCards,
      yearGroups: yearGroups,
      categoryGroups: null,
      displayName: widget.displayName,
      isPersonalLibraryMode: true,
      curatedLibrarySort: widget.isCuratedLibraryActive,
      useCuratedLibraryReorder: useCuratedReorder,
      onCuratedLibraryReorder: useCuratedReorder
          ? (oldIndex, newIndex) =>
              widget.onCuratedReorder(catalogCards, oldIndex, newIndex)
          : null,
      showHallOfFame: true,
      showWatchlist: true,
      showYearlySection: true,
      hofExpanded: sectionPrefs.hofExpanded,
      libraryExpanded: sectionPrefs.libraryExpanded,
      yearlyExpanded: sectionPrefs.yearlyExpanded,
      watchlistExpanded: sectionPrefs.watchlistExpanded,
      hofSortCriteria: sectionPrefs.hofSort,
      librarySortCriteria: sectionPrefs.librarySort,
      yearlySortCriteria: sectionPrefs.yearlySort,
      watchlistSortCriteria: sectionPrefs.watchlistSort,
      onHofExpandedChanged: (v) =>
          sectionPrefs.setHofExpanded(v, widget.onStateChanged),
      onLibraryExpandedChanged: (v) =>
          sectionPrefs.setLibraryExpanded(v, widget.onStateChanged),
      onYearlyExpandedChanged: (v) =>
          sectionPrefs.setYearlyExpanded(v, widget.onStateChanged),
      onWatchlistExpandedChanged: (v) =>
          sectionPrefs.setWatchlistExpanded(v, widget.onStateChanged),
      onHofSortChanged: (val) =>
          sectionPrefs.setHofSort(val, widget.onStateChanged),
      onLibrarySortChanged: (val) =>
          sectionPrefs.setLibrarySort(val, widget.onStateChanged),
      onYearlySortChanged: (val) =>
          sectionPrefs.setYearlySort(val, widget.onStateChanged),
      onWatchlistSortChanged: (val) =>
          sectionPrefs.setWatchlistSort(val, widget.onStateChanged),
      posterCardBuilder: widget.posterCardBuilder,
    );
  }
}
