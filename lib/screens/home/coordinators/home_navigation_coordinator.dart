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

  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final HomeSidebarCoordinator sidebarCoordinator;
  final HomeFilterCoordinator filterCoordinator;
  final WorkbenchController workbench;
  final Future<void> Function() prefetchRegistry;
  final void Function() rebuild;

  bool isSidebarOpen = true;
  int timelineReloadToken = 0;

  bool get isPersonalLibraryMode => sidebarCoordinator.isPersonalLibraryMode;
  bool get isCollectibleCollectionMode =>
      sidebarCoordinator.isCollectibleCollectionMode;
  bool get isTimelineMode => filterCoordinator.isTimelineMode;

  /// Wave 3 alias — 「기록」축 (timeline + journal).
  bool get isRecordsMode => isTimelineMode;
  bool get isCuratedLibraryActive => sidebarCoordinator.isCuratedLibraryActive;

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
    scheduleRebuild(() {
      sidebarCoordinator.selectDashboard(id);
      workbench.showBrowse();
    });
    await prefetchRegistry();
  }

  void selectPersonalLibrary(String id) {
    scheduleRebuild(() {
      sidebarCoordinator.selectPersonalLibrary(id);
      workbench.showBrowse();
    });
  }

  void selectCollectibleCollection(String id) {
    scheduleRebuild(() {
      sidebarCoordinator.selectCollectibleCollection(id);
      workbench.showBrowse();
    });
  }

  void selectTimeline() {
    scheduleRebuild(() {
      sidebarCoordinator.selectTimeline();
      workbench.showBrowse();
    });
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
      workbench.showBrowse();
    });
  }

  void onJournalQuickCaptureSaved() {
    onTimelineQuickCaptureSaved();
  }
}
