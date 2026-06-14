import '../../../models/enums.dart';
import '../../../models/personal_library_config.dart';
import '../home_browse_filter_controller.dart';
import '../home_dashboard_controller.dart';
import '../home_personal_library_controller.dart';

/// 필터 스냅샷 동기화·변경 (대시보드 ↔ 나만의 서재).
class HomeFilterCoordinator {
  HomeFilterCoordinator({
    required this.filterCtrl,
    required this.dashboardCtrl,
    required this.personalLibCtrl,
  });

  final HomeBrowseFilterController filterCtrl;
  final HomeDashboardController dashboardCtrl;
  final HomePersonalLibraryController personalLibCtrl;

  bool get isPersonalLibraryMode =>
      personalLibCtrl.sidebarMode == SidebarSelectionMode.personalLibrary;

  bool get isTimelineMode =>
      personalLibCtrl.sidebarMode == SidebarSelectionMode.timeline;

  void applyDashboardFilters(DashboardFilterSnapshot snap) {
    filterCtrl.applySnapshot(snap);
  }

  void syncFiltersToActiveView() {
    if (isPersonalLibraryMode) {
      personalLibCtrl.syncActiveFromFilters(
        domain: filterCtrl.domain,
        categories: filterCtrl.categories,
        workStatuses: filterCtrl.workStatuses,
        myStatuses: filterCtrl.myStatuses,
      );
      personalLibCtrl.save();
      return;
    }
    filterCtrl.syncToDashboard(dashboardCtrl);
  }

  void applyPersonalLibraryFilterSnapshot(PersonalLibraryConfig? library) {
    applyDashboardFilters(personalLibCtrl.filterSnapshotFor(library));
  }

  /// registry prefetch가 필요하면 true
  bool onDomainChanged(AppDomain? domain) {
    filterCtrl.onDomainChanged(domain);
    syncFiltersToActiveView();
    return !isPersonalLibraryMode;
  }

  bool toggleCategory(MediaCategory category) {
    filterCtrl.toggleCategory(category);
    syncFiltersToActiveView();
    return !isPersonalLibraryMode;
  }

  bool clearCategories() {
    filterCtrl.clearCategories();
    syncFiltersToActiveView();
    return !isPersonalLibraryMode;
  }

  void toggleWorkStatus(String label) {
    filterCtrl.toggleWorkStatus(label);
    syncFiltersToActiveView();
  }

  void toggleMyStatus(String label) {
    filterCtrl.toggleMyStatus(label);
    syncFiltersToActiveView();
  }
}
