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
  });

  static const String homeDashboardId = 'master_index';

  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final HomeSidebarCoordinator sidebarCoordinator;
  final HomeFilterCoordinator filterCoordinator;
  final WorkbenchController workbench;
  final Future<void> Function() prefetchRegistry;
  final void Function() rebuild;

  bool isSidebarOpen = true;
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
  bool get isExploreModeActive =>
      isOnMasterDashboard && isExploreBrowseMode;

  bool get isKnowledgeGraphViewActive =>
      isOnMasterDashboard && isKnowledgeGraphMode;

  Future<void> loadSidebarState() async {
    if (isMounted()) scheduleRebuild(() => isSidebarOpen = true);
  }

  Future<void> saveSidebarState(bool open) =>
      HomeSidebarPreferences.saveOpen(open);

  void toggleSidebar() {}

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
    scheduleRebuild(() {
      sidebarCoordinator.selectDashboard(id);
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  /// 프리미엄 홈 대시보드로 이동.
  Future<void> goHome() async {
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.resetForHomeDashboard();
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  /// 작품 browse 그리드 탐색 모드.
  Future<void> goExplore() async {
    scheduleRebuild(() {
      isExploreBrowseMode = true;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(BrowseEntityScope.all);
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  /// 엔티티 갤러리 탐색 모드.
  Future<void> goExploreEntities(BrowseEntityScope scope) async {
    scheduleRebuild(() {
      isExploreBrowseMode = true;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(scope);
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  void selectPersonalLibrary(String id) {
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectPersonalLibrary(id);
      workbench.showBrowse();
    });
  }

  void selectCollectibleCollection(String id) {
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectCollectibleCollection(id);
      workbench.showBrowse();
    });
  }

  void selectTimeline() {
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      sidebarCoordinator.selectTimeline();
      workbench.showBrowse();
    });
  }

  /// 나만의 서재 뷰 (활성 서재 또는 master archive).
  Future<void> goLibrary() async {
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      final libId = sidebarCoordinator.personalLibCtrl.activeLibraryId ??
          PersonalLibraryConfig.masterArchiveId;
      sidebarCoordinator.selectPersonalLibrary(libId);
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  /// 컬렉션 뷰 (활성 컬렉션 또는 첫 번째).
  Future<void> goCollection() async {
    final cols = sidebarCoordinator.collectionCtrl.collections;
    if (cols.isEmpty) return;
    scheduleRebuild(() {
      isExploreBrowseMode = false;
      isKnowledgeGraphMode = false;
      final id = sidebarCoordinator.collectionCtrl.activeCollectionId ??
          cols.first.id;
      sidebarCoordinator.selectCollectibleCollection(id);
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  /// 지식 연결 맵 뷰.
  Future<void> goKnowledgeGraph() async {
    scheduleRebuild(() {
      isKnowledgeGraphMode = true;
      isExploreBrowseMode = false;
      sidebarCoordinator.selectDashboard(homeDashboardId);
      filterCoordinator.setEntityScope(BrowseEntityScope.all);
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  void onLibraryDragStarted() {
    if (!isSidebarOpen) {
      scheduleRebuild(() => isSidebarOpen = true);
      saveSidebarState(true);
    }
  }

  void onTimelineQuickCaptureSaved() {
    scheduleRebuild(() {
      timelineReloadToken++;
      sidebarCoordinator.selectTimeline();
      isExploreBrowseMode = false;
      workbench.showBrowse();
    });
  }

  void onJournalQuickCaptureSaved() {
    onTimelineQuickCaptureSaved();
  }
}
