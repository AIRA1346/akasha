import 'dart:async';

import '../../../core/ports/registry_port.dart';
import '../../../core/ports/registry_sync_port.dart';
import '../dialogs/home_dialogs_facade.dart';
import '../home_browse_filter_controller.dart';
import '../home_dashboard_controller.dart';
import '../home_registry_prefetch.dart';
import '../home_registry_sync.dart';

/// 글로벌 카탈로그 prefetch·동기화·기여함 카운트 (E2-1).
class HomeCatalogCoordinator {
  HomeCatalogCoordinator({
    required this.registry,
    required this.registrySyncPort,
    required this.isMounted,
    required this.scheduleRebuild,
    required this.filterCtrl,
    required this.dashboardCtrl,
    required this.isPersonalLibraryMode,
    required this.showSuccess,
    required this.showError,
    required this.reloadItems,
    required this.autoArchiveWorks,
  });

  final RegistryPort registry;
  final RegistrySyncPort registrySyncPort;
  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final HomeBrowseFilterController filterCtrl;
  final HomeDashboardController dashboardCtrl;
  final bool Function() isPersonalLibraryMode;
  final void Function(String message) showSuccess;
  final void Function(String message) showError;
  final Future<void> Function() reloadItems;
  final Future<void> Function({bool showFeedback}) autoArchiveWorks;

  bool isSyncing = false;
  bool isCatalogLoading = false;
  bool isCatalogLoadingMore = false;
  int catalogBrowseOffset = 0;
  int catalogTotalEntries = 0;
  DateTime? lastSyncTime;
  int catalogContributionCount = 0;

  late final HomeRegistrySync registrySync;
  Timer? _prefetchRebuildDebounce;

  void init() {
    registrySync = HomeRegistrySync(
      registry: registry,
      sync: registrySyncPort,
      isMounted: isMounted,
      onSyncingChanged: (v) => scheduleRebuild(() => isSyncing = v),
      refreshLastSyncTime: refreshLastSyncTime,
      reloadItems: reloadItems,
      autoArchiveWorks: autoArchiveWorks,
      showSuccess: showSuccess,
      showError: showError,
    );
  }

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
      filterCtrl.domain == null &&
      filterCtrl.categories.isEmpty;

  bool get catalogHasMore =>
      catalogUsesWindowedPrefetch && catalogBrowseOffset < catalogTotalEntries;

  int get catalogLoadedThrough =>
      catalogBrowseOffset.clamp(0, catalogTotalEntries);

  Future<void> prefetchRegistryForCurrentFilters({bool append = false}) async {
    if (!append) {
      scheduleRebuild(() => catalogBrowseOffset = 0);
    }
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
  }

  Future<void> loadMoreCatalog() async {
    if (!catalogHasMore || isCatalogLoadingMore || isCatalogLoading) return;
    scheduleRebuild(() => isCatalogLoadingMore = true);
    await prefetchRegistryForCurrentFilters(append: true);
    if (isMounted()) {
      scheduleRebuild(() => isCatalogLoadingMore = false);
    }
  }

  Future<void> refreshLastSyncTime() async {
    await registrySyncPort.init();
    if (!isMounted()) return;
    scheduleRebuild(
      () => lastSyncTime = registrySyncPort.lastSyncTime,
    );
  }

  Future<void> syncRegistry() async {
    if (isSyncing) return;
    await registrySync.syncNow();
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
