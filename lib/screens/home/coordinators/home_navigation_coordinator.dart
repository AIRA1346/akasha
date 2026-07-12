import '../../../config/feature_flags.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/personal_library_config.dart';
import '../../../features/workbench/data/workbench_controller.dart';
import '../home_sidebar_preferences.dart';
import 'home_filter_coordinator.dart';
import 'home_sidebar_coordinator.dart';

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

  bool isSidebarOpen = false;
  int timelineReloadToken = 0;

  /// master_index에서 browse 그리드를 보여줄 때 true (프리미엄 홈 대시보드 대신).
  bool isExploreBrowseMode = false;

  /// 지식 그래프 뷰 모드.
  bool isKnowledgeGraphMode = false;

  bool get isPersonalLibraryMode => sidebarCoordinator.isPersonalLibraryMode;
  bool get isCollectibleCollectionMode =>
      sidebarCoordinator.isCollectibleCollectionMode;
  bool get isTimelineMode => filterCoordinator.isTimelineMode;

  /// Wave 3 alias — 「기록」축 (timeline + journal).
  bool get isRecordsMode => isTimelineMode;
  bool get isCuratedLibraryActive => sidebarCoordinator.isCuratedLibraryActive;

  bool get isOnMasterDashboard =>
      sidebarCoordinator.dashboardCtrl.activeDashboardId == homeDashboardId &&
      !isPersonalLibraryMode &&
      !isCollectibleCollectionMode &&
      !isTimelineMode;

  /// 프리미엄 홈 대시보드(환영·계속 탐험하기) 표시 조건.
  bool get isHomeDashboardMode =>
      isOnMasterDashboard &&
      !isExploreBrowseMode &&
      !isKnowledgeGraphMode &&
      !filterCoordinator.filterCtrl.hasAnyFilters;

  /// browse 그리드 탐색 모드.
  bool get isExploreModeActive => isOnMasterDashboard && isExploreBrowseMode;

  bool get isKnowledgeGraphViewActive =>
      isOnMasterDashboard && isKnowledgeGraphMode;

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
    if (isMounted()) rebuild();
  }

  Future<void> loadCollectibleCollections() async {
    await sidebarCoordinator.loadCollectibleCollections();
    if (isMounted()) rebuild();
  }

  Future<void> selectDashboard(String id) async {
    await _ensureLegacyItemsForHomeSurfaces();
    await workbench.showBrowse();
    scheduleRebuild(() {
      sidebarCoordinator.selectDashboard(id);
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
    });
    await prefetchRegistry();
  }

  /// 프리미엄 홈 대시보드로 이동.
  Future<void> goHome() async {
    // Premium Home still reads vault.items for continue-explore / discovery.
    await _ensureLegacyItemsForHomeSurfaces();
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.resetForHomeDashboard();
    });
    await prefetchRegistry();
  }

  /// 작품 browse 그리드 탐색 모드.
  Future<void> goExplore() async {
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = true;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(BrowseEntityScope.all);
    });
    await prefetchRegistry();
  }

  /// 엔티티 갤러리 탐색 모드.
  Future<void> goExploreEntities(BrowseEntityScope scope) async {
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = true;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(scope);
    });
    await prefetchRegistry();
  }

  Future<void> selectPersonalLibrary(String id) async {
    await _ensureLegacyItemsForHomeSurfaces();
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectPersonalLibrary(id);
    });
  }

  Future<void> selectCollectibleCollection(String id) async {
    await _ensureLegacyItemsForHomeSurfaces();
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectCollectibleCollection(id);
    });
  }

  Future<void> selectTimeline() async {
    if (!FeatureFlags.showTimeline) return;
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectTimeline();
    });
  }

  /// 나만의 서재 뷰 (활성 서재 또는 master archive).
  Future<void> goLibrary() async {
    await _ensureLegacyItemsForHomeSurfaces();
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      final libId =
          sidebarCoordinator.personalLibCtrl.activeLibraryId ??
          PersonalLibraryConfig.masterArchiveId;
      sidebarCoordinator.selectPersonalLibrary(libId);
    });
    await prefetchRegistry();
  }

  /// 컬렉션 뷰 (활성 컬렉션 또는 첫 번째).
  Future<void> goCollection() async {
    final cols = sidebarCoordinator.collectionCtrl.collections;
    if (cols.isEmpty) return;
    await _ensureLegacyItemsForHomeSurfaces();
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      final id =
          sidebarCoordinator.collectionCtrl.activeCollectionId ?? cols.first.id;
      sidebarCoordinator.selectCollectibleCollection(id);
    });
    await prefetchRegistry();
  }

  Future<void> _ensureLegacyItemsForHomeSurfaces() async {
    await ensureLegacyItemsLoaded?.call();
  }

  /// 지식 연결 맵 뷰 — Steam v1 비활성 (C-04).
  Future<void> goKnowledgeGraph() async {
    if (!FeatureFlags.showKnowledgeGraph) return;
    await workbench.showBrowse();
    scheduleRebuild(() {
      isKnowledgeGraphMode = true;
      isExploreBrowseMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(BrowseEntityScope.all);
    });
    await prefetchRegistry();
  }

  void onLibraryDragStarted() {
    if (!isSidebarOpen) {
      scheduleRebuild(() => isSidebarOpen = true);
      saveSidebarState(true);
    }
  }

  Future<void> onTimelineQuickCaptureSaved() async {
    // Explicit Timeline transition — does not acquire the legacy Work list.
    await workbench.showBrowse();
    scheduleRebuild(() {
      timelineReloadToken++;
      sidebarCoordinator.selectTimeline();
      isExploreBrowseMode = false;
    });
  }

  Future<void> onJournalQuickCaptureSaved() => onTimelineQuickCaptureSaved();

  /// Starts the bounded Work archive without requesting the legacy item list.
  Future<void> enterWorkArchiveBrowse() async {
    await workbench.showBrowse();
    scheduleRebuild(() {
      isExploreBrowseMode = true;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(BrowseEntityScope.work);
    });
    await prefetchRegistry();
  }
}
