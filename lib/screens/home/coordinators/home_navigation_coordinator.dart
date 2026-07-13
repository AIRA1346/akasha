import '../../../models/browse_entity_scope.dart';
import '../../../models/personal_library_config.dart';
import '../../../features/workbench/data/workbench_controller.dart';
import '../app_destination.dart';
import '../home_personal_library_controller.dart';
import '../home_sidebar_preferences.dart';
import 'home_filter_coordinator.dart';
import 'home_sidebar_coordinator.dart';

enum WorkbenchNavigationDecision { save, discard, cancel }

typedef WorkbenchNavigationGuardPrompt =
    Future<WorkbenchNavigationDecision> Function({
      required String title,
      required bool canSave,
    });

/// 사이드바·대시보드·서재·타임라인 네비게이션 (E2-4).
class HomeNavigationCoordinator {
  HomeNavigationCoordinator({
    required this.isMounted,
    required this.scheduleRebuild,
    required this.sidebarCoordinator,
    required this.filterCoordinator,
    required this.workbench,
    required this.prefetchRegistry,
    required this.rebuild,
    this.ensureLegacyItemsLoaded,
    this.requestWorkbenchNavigationDecision,
  });

  static const String homeDashboardId = 'master_index';

  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final HomeSidebarCoordinator sidebarCoordinator;
  final HomeFilterCoordinator filterCoordinator;
  final WorkbenchController workbench;
  final Future<void> Function() prefetchRegistry;
  final void Function() rebuild;
  final Future<void> Function()? ensureLegacyItemsLoaded;
  final WorkbenchNavigationGuardPrompt? requestWorkbenchNavigationDecision;

  bool isSidebarOpen = false;
  int timelineReloadToken = 0;
  int _navigationGeneration = 0;
  Future<bool>? _workbenchGuardInFlight;

  /// Sidebar와 Bottom dock이 공유하는 전역 목적지 선택 SSOT.
  AppDestination _currentDestination = AppDestination.home;
  AppDestination get currentDestination => _currentDestination;

  bool get isPersonalLibraryMode =>
      currentDestination == AppDestination.library;
  bool get isCollectibleCollectionMode =>
      currentDestination == AppDestination.collections;
  bool get isTimelineMode => currentDestination == AppDestination.timeline;
  bool get isExploreBrowseMode => currentDestination == AppDestination.explore;
  bool get isKnowledgeGraphMode => currentDestination == AppDestination.graph;

  /// Wave 3 alias — 「기록」축 (timeline + journal).
  bool get isRecordsMode => isTimelineMode;
  bool get isCuratedLibraryActive => sidebarCoordinator.isCuratedLibraryActive;

  bool get isOnMasterDashboard =>
      sidebarCoordinator.dashboardCtrl.activeDashboardId == homeDashboardId &&
      (currentDestination == AppDestination.home ||
          currentDestination == AppDestination.explore ||
          currentDestination == AppDestination.graph);

  /// 프리미엄 홈 대시보드(환영·계속 탐험하기) 표시 조건.
  bool get isHomeDashboardMode =>
      currentDestination == AppDestination.home &&
      isOnMasterDashboard &&
      !filterCoordinator.filterCtrl.hasAnyFilters;

  /// browse 그리드 탐색 모드.
  bool get isExploreModeActive =>
      isOnMasterDashboard && currentDestination == AppDestination.explore;

  bool get isKnowledgeGraphViewActive =>
      isOnMasterDashboard && currentDestination == AppDestination.graph;

  Future<void> selectDestination(AppDestination destination) {
    return switch (destination) {
      AppDestination.home => goHome(),
      AppDestination.explore => goExplore(),
      AppDestination.library => goLibrary(),
      AppDestination.collections => goCollection(),
      AppDestination.graph => goKnowledgeGraph(),
      AppDestination.timeline => selectTimeline(),
    };
  }

  Future<void> loadSidebarState() async {
    final open = await HomeSidebarPreferences.loadOpen();
    if (isMounted()) scheduleRebuild(() => isSidebarOpen = open);
  }

  Future<void> saveSidebarState(bool open) =>
      HomeSidebarPreferences.saveOpen(open);

  void toggleSidebar() {
    scheduleRebuild(() {
      isSidebarOpen = !isSidebarOpen;
      saveSidebarState(isSidebarOpen);
    });
  }

  Future<void> loadDashboards() async {
    final needsPrefetch = await sidebarCoordinator.loadDashboards();
    if (needsPrefetch) await prefetchRegistry();
    if (isMounted()) rebuild();
  }

  Future<void> loadPersonalLibraries() async {
    await sidebarCoordinator.loadPersonalLibraries();
    _currentDestination = switch (sidebarCoordinator
        .personalLibCtrl
        .sidebarMode) {
      SidebarSelectionMode.personalLibrary => AppDestination.library,
      SidebarSelectionMode.timeline => AppDestination.timeline,
      SidebarSelectionMode.collectibleCollection => AppDestination.collections,
      SidebarSelectionMode.dashboard => AppDestination.home,
    };
    if (isMounted()) rebuild();
  }

  Future<void> loadCollectibleCollections() async {
    await sidebarCoordinator.loadCollectibleCollections();
    if (isMounted()) rebuild();
  }

  /// Applies the default Home setup without overwriting a restored legacy
  /// SidebarSelectionMode destination.
  Future<void> finalizeInitialDestination({required bool vaultLinked}) async {
    if (!vaultLinked || currentDestination != AppDestination.home) return;
    await goHome();
  }

  Future<void> selectDashboard(String id) async {
    await _navigate(
      prepare: _ensureLegacyItemsForHomeSurfaces,
      commit: () {
        sidebarCoordinator.selectDashboard(id);
        _currentDestination = AppDestination.home;
      },
      prefetch: true,
    );
  }

  /// 프리미엄 홈 대시보드로 이동.
  Future<void> goHome() async {
    // Premium Home still reads vault.items for continue-explore / discovery.
    await _navigate(
      prepare: _ensureLegacyItemsForHomeSurfaces,
      commit: () {
        _currentDestination = AppDestination.home;
        sidebarCoordinator.selectDashboard(homeDashboardId);
        filterCoordinator.resetForHomeDashboard();
      },
      prefetch: true,
    );
  }

  /// 작품 browse 그리드 탐색 모드.
  Future<void> goExplore() async {
    await _navigate(
      commit: () {
        _currentDestination = AppDestination.explore;
        sidebarCoordinator.selectDashboard(homeDashboardId);
        filterCoordinator.setEntityScope(BrowseEntityScope.all);
      },
      prefetch: true,
    );
  }

  /// 엔티티 갤러리 탐색 모드.
  Future<void> goExploreEntities(BrowseEntityScope scope) async {
    await _navigate(
      commit: () {
        _currentDestination = AppDestination.explore;
        sidebarCoordinator.selectDashboard(homeDashboardId);
        filterCoordinator.setEntityScope(scope);
      },
      prefetch: true,
    );
  }

  Future<void> selectPersonalLibrary(String id) async {
    await _navigate(
      prepare: _ensureLegacyItemsForHomeSurfaces,
      commit: () {
        _currentDestination = AppDestination.library;
        sidebarCoordinator.selectPersonalLibrary(id);
      },
    );
  }

  Future<void> selectCollectibleCollection(String id) async {
    await _navigate(
      prepare: _ensureLegacyItemsForHomeSurfaces,
      commit: () {
        _currentDestination = AppDestination.collections;
        sidebarCoordinator.selectCollectibleCollection(id);
      },
    );
  }

  Future<void> selectTimeline() async {
    await _navigate(
      commit: () {
        _currentDestination = AppDestination.timeline;
        sidebarCoordinator.selectTimeline();
      },
    );
  }

  /// 나만의 서재 뷰 (활성 서재 또는 master archive).
  Future<void> goLibrary() async {
    await _navigate(
      prepare: _ensureLegacyItemsForHomeSurfaces,
      commit: () {
        _currentDestination = AppDestination.library;
        final libId =
            sidebarCoordinator.personalLibCtrl.activeLibraryId ??
            PersonalLibraryConfig.masterArchiveId;
        sidebarCoordinator.selectPersonalLibrary(libId);
      },
      prefetch: true,
    );
  }

  /// 컬렉션 뷰 (활성 컬렉션 또는 첫 번째).
  Future<void> goCollection() async {
    final cols = sidebarCoordinator.collectionCtrl.collections;
    await _navigate(
      prepare: _ensureLegacyItemsForHomeSurfaces,
      commit: () {
        _currentDestination = AppDestination.collections;
        if (cols.isEmpty) {
          sidebarCoordinator.personalLibCtrl.selectCollectibleCollectionMode();
          return;
        }
        final id =
            sidebarCoordinator.collectionCtrl.activeCollectionId ??
            cols.first.id;
        sidebarCoordinator.selectCollectibleCollection(id);
      },
      prefetch: true,
    );
  }

  Future<void> _ensureLegacyItemsForHomeSurfaces() async {
    await ensureLegacyItemsLoaded?.call();
  }

  /// Existing Graph surface. Experimental Graph CTAs/expansion remain flagged off.
  Future<void> goKnowledgeGraph() async {
    await _navigate(
      commit: () {
        _currentDestination = AppDestination.graph;
        sidebarCoordinator.selectDashboard(homeDashboardId);
        filterCoordinator.setEntityScope(BrowseEntityScope.all);
      },
      prefetch: true,
    );
  }

  void onLibraryDragStarted() {
    if (!isSidebarOpen) {
      scheduleRebuild(() => isSidebarOpen = true);
      saveSidebarState(true);
    }
  }

  Future<void> onTimelineQuickCaptureSaved() async {
    // Explicit Timeline transition — does not acquire the legacy Work list.
    await _navigate(
      commit: () {
        timelineReloadToken++;
        sidebarCoordinator.selectTimeline();
        _currentDestination = AppDestination.timeline;
      },
    );
  }

  Future<void> onJournalQuickCaptureSaved() => onTimelineQuickCaptureSaved();

  /// Starts the bounded Work archive without requesting the legacy item list.
  Future<void> enterWorkArchiveBrowse() async {
    await _navigate(
      commit: () {
        _currentDestination = AppDestination.explore;
        sidebarCoordinator.selectDashboard(homeDashboardId);
        filterCoordinator.setEntityScope(BrowseEntityScope.work);
      },
      prefetch: true,
    );
  }

  Future<void> _navigate({
    Future<void> Function()? prepare,
    required void Function() commit,
    bool prefetch = false,
  }) async {
    final requestGeneration = ++_navigationGeneration;
    final canLeaveWorkbench = await _guardWorkbenchNavigation();
    if (!canLeaveWorkbench || requestGeneration != _navigationGeneration) {
      return;
    }

    if (prepare != null) {
      await prepare();
      if (requestGeneration != _navigationGeneration) return;
    }

    await workbench.showBrowse();
    if (requestGeneration != _navigationGeneration) return;

    scheduleRebuild(commit);
    if (prefetch) await prefetchRegistry();
  }

  Future<bool> _guardWorkbenchNavigation() {
    final inFlight = _workbenchGuardInFlight;
    if (inFlight != null) return inFlight;

    late final Future<bool> guard;
    guard = _evaluateWorkbenchNavigationGuard().whenComplete(() {
      if (identical(_workbenchGuardInFlight, guard)) {
        _workbenchGuardInFlight = null;
      }
    });
    _workbenchGuardInFlight = guard;
    return guard;
  }

  Future<bool> _evaluateWorkbenchNavigationGuard() async {
    if (!workbench.tabs.any((tab) => tab.isDirty)) return true;

    final prompt = requestWorkbenchNavigationDecision;
    if (prompt == null) return false;

    final explicitlyDiscarded = <String>{};
    while (true) {
      final pendingDirtyTabs = workbench.tabs
          .where((tab) => tab.isDirty && !explicitlyDiscarded.contains(tab.id))
          .toList();
      if (pendingDirtyTabs.isEmpty) return true;

      final activeTab = workbench.activeTab;
      final dirtyTab =
          activeTab != null &&
              activeTab.isDirty &&
              !explicitlyDiscarded.contains(activeTab.id)
          ? activeTab
          : pendingDirtyTabs.first;
      final save = workbench.saveActiveTab;
      final canSave = activeTab?.id == dirtyTab.id && save != null;
      final decision = await prompt(title: dirtyTab.title, canSave: canSave);

      switch (decision) {
        case WorkbenchNavigationDecision.cancel:
          return false;
        case WorkbenchNavigationDecision.discard:
          explicitlyDiscarded.add(dirtyTab.id);
          continue;
        case WorkbenchNavigationDecision.save:
          if (!canSave) return false;
          try {
            await save();
          } catch (_) {
            return false;
          }
          final remainsDirty = workbench.tabs.any(
            (tab) => tab.id == dirtyTab.id && tab.isDirty,
          );
          if (remainsDirty) return false;
          continue;
      }
    }
  }
}
