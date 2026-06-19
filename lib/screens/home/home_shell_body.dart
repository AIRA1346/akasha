import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../features/workbench/presentation/workbench_shell.dart';
import '../../models/akasha_item.dart';
import '../../models/browse_card.dart';
import '../../models/dashboard_config.dart';
import '../../models/enums.dart';
import '../../models/library_theme.dart';
import '../../models/personal_library_config.dart';
import '../../models/work_drag_payload.dart';
import '../../services/file_service.dart';
import '../../services/personal_library_membership_service.dart';
import '../../utils/recall_picker.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../widgets/filter_section.dart';
import '../../widgets/today_recall_card.dart';
import 'home_browse_filter_controller.dart';
import 'home_dashboard_controller.dart';
import 'home_personal_library_controller.dart';
import 'home_section_preferences.dart';
import 'home_vault_banner.dart';
import 'views/browse_view.dart';
import 'views/personal_library_view.dart';
import 'views/records_view.dart';

/// HomeShell Scaffold body — sidebar · 필터 · workbench browse 영역.
class HomeShellBody extends StatelessWidget {
  final bool isSidebarOpen;
  final bool isPersonalLibraryMode;
  final bool isTimelineMode;
  final bool isCuratedLibraryActive;
  final bool isCatalogLoading;
  final bool isCatalogLoadingMore;
  final bool catalogHasMore;
  final int catalogLoadedThrough;
  final int catalogTotalEntries;
  final VoidCallback? onLoadMoreCatalog;
  final bool canAddToLibrary;
  final LibraryTheme libraryTheme;
  final String displayName;
  final List<AkashaItem> items;
  final List<BrowseCard> filteredCards;
  final HomeSectionPreferences sectionPrefs;
  final HomeBrowseFilterController filterCtrl;
  final HomeDashboardController dashboardCtrl;
  final HomePersonalLibraryController personalLibCtrl;
  final PersonalLibraryMembershipService libraryMembership;
  final WorkbenchController workbench;
  final Widget Function(BrowseCard) posterCardBuilder;
  final VoidCallback onStateChanged;
  final VoidCallback onAddDashboard;
  final Future<void> Function(String id) onSelectDashboard;
  final void Function(DashboardConfig dash) onEditDashboard;
  final void Function(String id) onDeleteDashboard;
  final VoidCallback onAddPersonalLibrary;
  final VoidCallback onSelectTimeline;
  final void Function(String id) onSelectPersonalLibrary;
  final void Function(PersonalLibraryConfig lib) onEditPersonalLibrary;
  final void Function(String id) onDeletePersonalLibrary;
  final Future<void> Function(String libraryId, WorkDragPayload payload)?
      onDropWorkToLibrary;
  final VoidCallback? onLibraryDragStarted;
  final VoidCallback onConnectVault;
  final void Function(AppDomain? domain) onDomainChanged;
  final void Function(MediaCategory category) onToggleCategory;
  final VoidCallback onClearCategories;
  final void Function(String label) onToggleWorkStatus;
  final void Function(String label) onToggleMyStatus;
  final void Function(AkashaItem item) onOpenBrowseItem;
  final Future<void> Function(AkashaItem saved) onWorkbenchWorkSaved;
  final Future<void> Function(String tabId, AkashaItem item) onWorkbenchWorkDeleted;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;
  final Future<void> Function(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) onCuratedReorder;
  final VoidCallback onSearch;
  final VoidCallback onNewTimelineEntry;
  final VoidCallback onNewJournalEntry;
  final int timelineReloadToken;

  const HomeShellBody({
    super.key,
    required this.isSidebarOpen,
    required this.isPersonalLibraryMode,
    required this.isTimelineMode,
    required this.isCuratedLibraryActive,
    required this.isCatalogLoading,
    this.isCatalogLoadingMore = false,
    this.catalogHasMore = false,
    this.catalogLoadedThrough = 0,
    this.catalogTotalEntries = 0,
    this.onLoadMoreCatalog,
    required this.canAddToLibrary,
    required this.libraryTheme,
    required this.displayName,
    required this.items,
    required this.filteredCards,
    required this.sectionPrefs,
    required this.filterCtrl,
    required this.dashboardCtrl,
    required this.personalLibCtrl,
    required this.libraryMembership,
    required this.workbench,
    required this.posterCardBuilder,
    required this.onStateChanged,
    required this.onAddDashboard,
    required this.onSelectDashboard,
    required this.onEditDashboard,
    required this.onDeleteDashboard,
    required this.onAddPersonalLibrary,
    required this.onSelectTimeline,
    required this.onSelectPersonalLibrary,
    required this.onEditPersonalLibrary,
    required this.onDeletePersonalLibrary,
    this.onDropWorkToLibrary,
    this.onLibraryDragStarted,
    required this.onConnectVault,
    required this.onDomainChanged,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.onOpenBrowseItem,
    required this.onWorkbenchWorkSaved,
    required this.onWorkbenchWorkDeleted,
    this.onAddToLibrary,
    required this.onCuratedReorder,
    required this.onSearch,
    required this.onNewTimelineEntry,
    required this.onNewJournalEntry,
    required this.timelineReloadToken,
  });

  @override
  Widget build(BuildContext context) {
    final dailyRecall = FeatureFlags.showRecallCard &&
            !isPersonalLibraryMode &&
            !isTimelineMode
        ? RecallPicker.pickDailyRecall(items)
        : null;

    return Row(
      children: [
        DashboardSidebar(
          isOpen: isSidebarOpen,
          selectionMode: personalLibCtrl.sidebarMode,
          dashboards: dashboardCtrl.dashboards,
          activeDashboardId: dashboardCtrl.activeDashboardId,
          personalLibraries: personalLibCtrl.libraries,
          activePersonalLibraryId: personalLibCtrl.activeLibraryId,
          onAddDashboard: onAddDashboard,
          onSelectDashboard: (id) => onSelectDashboard(id),
          onEditDashboard: onEditDashboard,
          onDeleteDashboard: onDeleteDashboard,
          onAddPersonalLibrary: onAddPersonalLibrary,
          onSelectTimeline: onSelectTimeline,
          onSelectPersonalLibrary: onSelectPersonalLibrary,
          onEditPersonalLibrary: onEditPersonalLibrary,
          onDeletePersonalLibrary: onDeletePersonalLibrary,
          onDropWorkToLibrary: onDropWorkToLibrary,
          onLibraryDragStarted: onLibraryDragStarted,
        ),
        Expanded(
          child: Column(
            children: [
              if (AkashaFileService().vaultPath == null)
                HomeVaultBanner(onConnectVault: onConnectVault),
              if (!workbench.hasOpenWork) ...[
                if (!isTimelineMode)
                  FilterSection(
                    selectedDomain: filterCtrl.domain,
                    selectedCategories: filterCtrl.categories,
                    selectedWorkStatuses: filterCtrl.workStatuses,
                    selectedMyStatuses: filterCtrl.myStatuses,
                    onDomainChanged: onDomainChanged,
                    onToggleCategory: onToggleCategory,
                    onClearCategories: onClearCategories,
                    onToggleWorkStatus: onToggleWorkStatus,
                    onToggleMyStatus: onToggleMyStatus,
                  ),
                if (!isTimelineMode) const Divider(height: 1),
              ],
              if (!isPersonalLibraryMode &&
                  !isTimelineMode &&
                  !workbench.hasOpenWork &&
                  isCatalogLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: Column(
                  children: [
                    if (dailyRecall != null && !workbench.hasOpenWork)
                      TodayRecallCard(
                        recall: dailyRecall,
                        onTap: () => onOpenBrowseItem(dailyRecall.item),
                      ),
                    Expanded(
                      child: WorkbenchShell(
                        controller: workbench,
                        onWorkSaved: onWorkbenchWorkSaved,
                        onWorkDeleted: onWorkbenchWorkDeleted,
                        onAddToLibrary: onAddToLibrary,
                        browseContent: isTimelineMode
                            ? RecordsView(
                                vaultItems: items,
                                onOpenWork: onOpenBrowseItem,
                                onNewTimelineEntry: onNewTimelineEntry,
                                onNewJournalEntry: onNewJournalEntry,
                                reloadToken: timelineReloadToken,
                              )
                            : isPersonalLibraryMode
                            ? PersonalLibraryView(
                                filteredCards: filteredCards,
                                allItems: items,
                                sectionPrefs: sectionPrefs,
                                displayName: displayName,
                                isCuratedLibraryActive: isCuratedLibraryActive,
                                activeLibrary: personalLibCtrl.activeLibrary,
                                posterCardBuilder: posterCardBuilder,
                                onStateChanged: onStateChanged,
                                onCuratedReorder: onCuratedReorder,
                                onSearch: onSearch,
                              )
                            : BrowseView(
                                filteredCards: filteredCards,
                                sectionPrefs: sectionPrefs,
                                filterCategories: filterCtrl.categories,
                                isCatalogLoading: isCatalogLoading,
                                isCatalogLoadingMore: isCatalogLoadingMore,
                                catalogHasMore: catalogHasMore,
                                catalogLoadedThrough: catalogLoadedThrough,
                                catalogTotalEntries: catalogTotalEntries,
                                onLoadMoreCatalog: onLoadMoreCatalog,
                                displayName: displayName,
                                posterCardBuilder: posterCardBuilder,
                                onStateChanged: onStateChanged,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
