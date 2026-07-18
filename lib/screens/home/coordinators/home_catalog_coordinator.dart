import 'dart:async';

import '../../../core/ports/registry_port.dart';
import '../dialogs/home_dialogs_facade.dart';
import '../home_browse_filter_controller.dart';
import '../home_dashboard_controller.dart';
import '../home_registry_prefetch.dart';

/// 글로벌 카탈로그 prefetch·기여함 카운트 (E2-1).
class HomeCatalogCoordinator {
  HomeCatalogCoordinator({
    required this.registry,
    required this.isMounted,
    required this.scheduleRebuild,
    required this.filterCtrl,
    required this.dashboardCtrl,
    required this.isPersonalLibraryMode,
    required this.showError,
  });

  final RegistryPort registry;
  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final HomeBrowseFilterController filterCtrl;
  final HomeDashboardController dashboardCtrl;
  final bool Function() isPersonalLibraryMode;
  final void Function(String message) showError;

  bool isCatalogLoading = false;
  bool isCatalogLoadingMore = false;
  int catalogBrowseOffset = 0;
  int catalogTotalEntries = 0;
  int catalogContributionCount = 0;

  Timer? _prefetchRebuildDebounce;

  void dispose() {
    _prefetchRebuildDebounce?.cancel();
  }

  void scheduleDebouncedPrefetchRebuild() {
    _prefetchRebuildDebounce?.cancel();
    _prefetchRebuildDebounce = Timer(const Duration(milliseconds: 300), () {
      if (isMounted()) scheduleRebuild(() {});
    });
  }

  bool get catalogUsesWindowedPrefetch =>
      dashboardCtrl.activeDashboardId == 'master_index' &&
      !isPersonalLibraryMode() &&
      filterCtrl.categories.isEmpty;

  bool get catalogHasMore =>
      catalogUsesWindowedPrefetch && catalogBrowseOffset < catalogTotalEntries;

  int get catalogLoadedThrough =>
      catalogBrowseOffset.clamp(0, catalogTotalEntries);

  Future<void> prefetchRegistryForCurrentFilters({bool append = false}) async {
    if (!append) {
      scheduleRebuild(() => catalogBrowseOffset = 0);
    }
    try {
      await prefetchRegistryForFilters(
        registry: registry,
        activeDashboardId: dashboardCtrl.activeDashboardId,
        filters: filterCtrl,
        onCatalogLoadingChanged: (v) =>
            scheduleRebuild(() => isCatalogLoading = v),
        isMounted: isMounted,
        onDataChanged: scheduleDebouncedPrefetchRebuild,
        append: append,
        browseOffset: append ? catalogBrowseOffset : 0,
        onCatalogWindowState: (state) {
          scheduleRebuild(() {
            catalogBrowseOffset = state.browseOffset;
            catalogTotalEntries = state.totalEntries;
          });
        },
      );
    } catch (error) {
      if (isMounted()) {
        scheduleRebuild(() => isCatalogLoading = false);
        showError('작품 레지스트리 bundle을 불러오지 못했습니다: $error');
      }
    }
  }

  Future<void> loadMoreCatalog() async {
    if (!catalogHasMore || isCatalogLoadingMore || isCatalogLoading) return;
    scheduleRebuild(() => isCatalogLoadingMore = true);
    try {
      await prefetchRegistryForCurrentFilters(append: true);
    } finally {
      if (isMounted()) {
        scheduleRebuild(() => isCatalogLoadingMore = false);
      }
    }
  }

  Future<void> syncCatalogContributionCount() async {
    await HomeDialogsFacade.refreshCatalogContributionCount(
      onCount: (count) {
        if (!isMounted()) return;
        scheduleRebuild(() => catalogContributionCount = count);
      },
    );
  }
}
