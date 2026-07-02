import 'package:flutter/material.dart';

import '../screens/home/dialogs/work_library_menu.dart';
import '../models/browse_card.dart';
import '../models/enums.dart';
import '../utils/browse_category_groups.dart';
import '../utils/browse_grid_metrics.dart';
import '../utils/browse_year_groups.dart';
import '../utils/app_l10n.dart';
import '../utils/helpers.dart';
import 'curated_reorder_grid.dart';
import 'section_header.dart';
import 'section_sort_dropdown.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_palette.dart';

part 'browse_dashboard_sections_header_part.dart';
part 'browse_dashboard_sections_grid_part.dart';
part 'browse_dashboard_sections_hof_part.dart';
part 'browse_dashboard_sections_library_part.dart';
part 'browse_dashboard_sections_yearly_part.dart';
part 'browse_dashboard_sections_watchlist_part.dart';

/// 홈 browse 섹션 — CustomScrollView + Sliver (대시보드 · 개인 서재 공용)
class BrowseDashboardSections extends StatelessWidget {
  final ScrollController scrollController;
  final double cardMinWidth;
  final double childAspectRatio;

  final List<BrowseCard> hofCards;
  final List<BrowseCard> libraryCards;
  final List<BrowseCard> watchlistCards;
  final BrowseYearGroups? yearGroups;
  final BrowseCategoryGroups? categoryGroups;
  final String displayName;

  final bool showHallOfFame;
  final bool showWatchlist;
  final bool showYearlySection;
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
  final ValueChanged<bool>? onYearlyExpandedChanged;
  final ValueChanged<bool> onWatchlistExpandedChanged;

  final ValueChanged<SortCriteria> onHofSortChanged;
  final ValueChanged<SortCriteria> onLibrarySortChanged;
  final ValueChanged<SortCriteria>? onYearlySortChanged;
  final ValueChanged<SortCriteria> onWatchlistSortChanged;

  final Widget Function(BrowseCard card) posterCardBuilder;
  final bool isPersonalLibraryMode;
  final bool curatedLibrarySort;
  final bool useCuratedLibraryReorder;
  final void Function(int oldIndex, int newIndex)? onCuratedLibraryReorder;
  final Widget? catalogFooter;
  final bool Function(MediaCategory category)? catalogCategoryExpanded;
  final void Function(MediaCategory category, bool expanded)?
  onCatalogCategoryExpandedChanged;

  const BrowseDashboardSections({
    super.key,
    required this.scrollController,
    required this.cardMinWidth,
    required this.childAspectRatio,
    required this.hofCards,
    required this.libraryCards,
    required this.watchlistCards,
    this.yearGroups,
    this.categoryGroups,
    required this.displayName,
    this.showHallOfFame = true,
    this.showWatchlist = true,
    this.showYearlySection = true,
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
    this.onYearlyExpandedChanged,
    required this.onWatchlistExpandedChanged,
    required this.onHofSortChanged,
    required this.onLibrarySortChanged,
    this.onYearlySortChanged,
    required this.onWatchlistSortChanged,
    required this.posterCardBuilder,
    this.isPersonalLibraryMode = false,
    this.curatedLibrarySort = false,
    this.useCuratedLibraryReorder = false,
    this.onCuratedLibraryReorder,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = BrowseGridMetrics.resolve(
            maxWidth: constraints.maxWidth,
            cardMinWidth: cardMinWidth,
            childAspectRatio: childAspectRatio,
          );

          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: CustomScrollView(
              controller: scrollController,
              primary: false,
              slivers: [
                ..._buildSlivers(context, metrics),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context, BrowseGridMetrics metrics) {
    final slivers = <Widget>[];

    slivers.addAll(_buildHofSlivers(context, this, metrics));

    if (libraryCards.isNotEmpty) {
      slivers.addAll(_buildLibrarySectionSlivers(context, this, metrics));
    }

    if (showYearlySection &&
        yearGroups != null &&
        libraryCards.isNotEmpty &&
        onYearlyExpandedChanged != null &&
        onYearlySortChanged != null) {
      slivers.addAll(_buildYearlySlivers(context, this, metrics));
    }

    if (showWatchlist) {
      slivers.addAll(_buildWatchlistSlivers(context, this, metrics));
    }

    return slivers;
  }
}
