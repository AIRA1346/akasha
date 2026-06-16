import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../data/adapters/works_registry_adapter.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../features/workbench/presentation/work_tab.dart';
import '../../models/akasha_item.dart';
import '../../models/browse_card.dart';
import '../../models/enums.dart';
import '../../models/library_theme.dart';
import '../../services/browse_pipeline.dart';
import '../../services/entitlement_service.dart';
import '../../services/file_service.dart';
import '../../services/library_theme_preferences.dart';
import '../../services/my_library_pipeline.dart';
import '../../services/personal_library_membership_service.dart';
import '../../services/registry_sync_service.dart';
import '../../services/user_preferences.dart';
import '../../services/user_registry_preferences.dart';
import 'coordinators/home_filter_coordinator.dart';
import 'coordinators/home_library_menu_builder.dart';
import 'coordinators/home_membership_coordinator.dart';
import 'coordinators/home_sidebar_coordinator.dart';
import 'dialogs/home_dialogs_facade.dart';
import 'home_auto_archive.dart';
import 'home_browse_filter_controller.dart';
import 'home_dashboard_controller.dart';
import 'home_dashboard_ui.dart';
import 'home_library_ui.dart';
import 'home_personal_library_controller.dart';
import 'home_personal_library_ui.dart';
import 'home_poster_card_factory.dart';
import 'home_registry_hide_actions.dart';
import 'home_registry_prefetch.dart';
import 'home_registry_sync.dart';
import 'home_registry_ui.dart';
import 'home_section_preferences.dart';
import 'home_shell_host.dart';
import 'home_sidebar_preferences.dart';
import 'home_vault_loader.dart';
import 'views/personal_library_view.dart';

/// Home 화면 상태·행동 오케스트레이션 (Wave 1.4).
class HomeShellController {
  HomeShellController(this.host);

  final HomeShellHost host;

  List<AkashaItem> items = [];
  bool isSyncing = false;
  bool isCatalogLoading = false;
  bool isCatalogLoadingMore = false;
  int catalogBrowseOffset = 0;
  int catalogTotalEntries = 0;
  DateTime? lastSyncTime;

  final HomeBrowseFilterController filterCtrl = HomeBrowseFilterController();
  final HomeDashboardController dashboardCtrl = HomeDashboardController();
  final HomePersonalLibraryController personalLibCtrl =
      HomePersonalLibraryController();
  late final PersonalLibraryMembershipService libraryMembership;
  late final BrowsePipeline browsePipeline;
  late final MyLibraryPipeline myLibraryPipeline;
  late final HomeMembershipCoordinator membershipCoordinator;
  late final HomeFilterCoordinator filterCoordinator;
  late final HomeSidebarCoordinator sidebarCoordinator;
  late final HomeLibraryMenuBuilder libraryMenuBuilder;
  late final HomeLibraryUi libraryUi;
  late final HomePersonalLibraryUi personalLibraryUi;
  late final HomeDashboardUi dashboardUi;
  final HomeRegistryUi registryUi = const HomeRegistryUi();
  HomeSectionPreferences sectionPrefs = HomeSectionPreferences();
  late final HomeRegistryHideActions hideActions;
  bool isSidebarOpen = true;
  int catalogContributionCount = 0;
  int timelineReloadToken = 0;

  String displayName = UserPreferences.defaultDisplayName;
  bool autoArchiveRegistry = false;
  StreamSubscription<void>? vaultUpdateSubscription;
  Timer? vaultReloadDebounce;
  Timer? _prefetchRebuildDebounce;
  bool _lastWorkbenchShowsWork = false;
  bool _lastWorkbenchHadTabs = false;
  late final HomeRegistrySync registrySync;
  LibraryTheme libraryTheme = LibraryTheme.classic;
  final WorkbenchController workbench = WorkbenchController();

  void wrapSetState(void Function() mutate) => host.scheduleRebuild(mutate);

  void rebuild() => host.scheduleRebuild();

  Future<void> init() async {
    hideActions = HomeRegistryHideActions(
      onStateChanged: rebuild,
      showMessage: (msg) {
        if (!host.mounted) return;
        ScaffoldMessenger.of(host.context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
    registrySync = HomeRegistrySync(
      isMounted: () => host.mounted,
      onSyncingChanged: (v) => host.scheduleRebuild(() => isSyncing = v),
      refreshLastSyncTime: refreshLastSyncTime,
      reloadItems: loadItems,
      autoArchiveWorks: autoArchiveRegistryWorks,
      showSuccess: (msg) {
        if (!host.mounted) return;
        ScaffoldMessenger.of(host.context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      showError: (msg) {
        if (!host.mounted) return;
        ScaffoldMessenger.of(host.context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );

    libraryMembership =
        PersonalLibraryMembershipService(personalLibCtrl, WorksRegistryAdapter());
    browsePipeline = BrowsePipeline(WorksRegistryAdapter());
    myLibraryPipeline = MyLibraryPipeline(WorksRegistryAdapter());

    membershipCoordinator = HomeMembershipCoordinator(
      personalLibraryController: personalLibCtrl,
      membership: libraryMembership,
      resolveItemForOpen: resolveItemForOpen,
      reloadItems: loadItems,
    );
    filterCoordinator = HomeFilterCoordinator(
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      personalLibCtrl: personalLibCtrl,
    );
    sidebarCoordinator = HomeSidebarCoordinator(
      personalLibCtrl: personalLibCtrl,
      dashboardCtrl: dashboardCtrl,
      sectionPrefs: sectionPrefs,
      filterCoordinator: filterCoordinator,
    );
    libraryMenuBuilder = HomeLibraryMenuBuilder(
      hideActions: hideActions,
      membership: libraryMembership,
    );
    libraryUi = HomeLibraryUi(
      membershipCoordinator: membershipCoordinator,
      libraryMenuBuilder: libraryMenuBuilder,
      filterCoordinator: filterCoordinator,
      personalLibCtrl: personalLibCtrl,
      hideActions: hideActions,
    );
    personalLibraryUi = HomePersonalLibraryUi(
      personalLibCtrl: personalLibCtrl,
      filterCoordinator: filterCoordinator,
      sectionPrefs: sectionPrefs,
    );
    dashboardUi = HomeDashboardUi(
      dashboardCtrl: dashboardCtrl,
      filterCoordinator: filterCoordinator,
    );

    workbench.addListener(onWorkbenchChanged);

    await initVault();
    if (FeatureFlags.catalogContributions) {
      await syncCatalogContributionCount();
    }
    await workbench.loadPrefs();
    _lastWorkbenchShowsWork = workbench.hasOpenWork;
    _lastWorkbenchHadTabs = workbench.hasTabs;
  }

  void dispose() {
    workbench.removeListener(onWorkbenchChanged);
    workbench.dispose();
    vaultReloadDebounce?.cancel();
    _prefetchRebuildDebounce?.cancel();
    vaultUpdateSubscription?.cancel();
  }

  void scheduleDebouncedPrefetchRebuild() {
    _prefetchRebuildDebounce?.cancel();
    _prefetchRebuildDebounce = Timer(const Duration(milliseconds: 300), () {
      if (host.mounted) rebuild();
    });
  }

  void onWorkbenchChanged() {
    if (!host.mounted) return;
    final showsWork = workbench.hasOpenWork;
    final hasTabs = workbench.hasTabs;
    if (showsWork == _lastWorkbenchShowsWork && hasTabs == _lastWorkbenchHadTabs) {
      return;
    }
    _lastWorkbenchShowsWork = showsWork;
    _lastWorkbenchHadTabs = hasTabs;
    rebuild();
  }

  Future<void> initVault() async {
    final service = AkashaFileService();
    await service.init();
    await loadSidebarState();
    await loadDashboards();
    await loadPersonalLibraries();
    sectionPrefs = await HomeSectionPreferences.load();
    displayName = await UserPreferences.getDisplayName();
    autoArchiveRegistry = await UserPreferences.isAutoArchiveRegistryEnabled();
    await UserRegistryPreferences.instance.load();
    await EntitlementService.instance.load();
    libraryTheme = await LibraryThemePreferences.load();
    await loadItems();

    if (service.vaultPath != null && autoArchiveRegistry) {
      await autoArchiveRegistryWorks();
    }

    await prefetchRegistryForCurrentFilters();
    await refreshLastSyncTime();

    vaultUpdateSubscription = service.onVaultUpdated.listen((_) {
      vaultReloadDebounce?.cancel();
      vaultReloadDebounce = Timer(const Duration(milliseconds: 400), () {
        if (host.mounted) {
          loadItems();
          host.scheduleRebuild(() => timelineReloadToken++);
        }
      });
    });

    registrySync.checkAutoSync();
  }

  Future<void> loadItems() async {
    final loadedItems = await HomeVaultLoader.loadItems();
    if (!host.mounted) return;
    host.scheduleRebuild(() => items = loadedItems);
    workbench.syncFromVaultItems(loadedItems);
  }

  Future<void> prefetchRegistryForCurrentFilters({bool append = false}) async {
    if (!append) {
      host.scheduleRebuild(() => catalogBrowseOffset = 0);
    }
    await prefetchRegistryForFilters(
      activeDashboardId: dashboardCtrl.activeDashboardId,
      filters: filterCtrl,
      onCatalogLoadingChanged: (v) =>
          host.scheduleRebuild(() => isCatalogLoading = v),
      isMounted: () => host.mounted,
      onDataChanged: scheduleDebouncedPrefetchRebuild,
      append: append,
      browseOffset: append ? catalogBrowseOffset : 0,
      onCatalogWindowState: (state) {
        host.scheduleRebuild(() {
          catalogBrowseOffset = state.browseOffset;
          catalogTotalEntries = state.totalEntries;
        });
      },
    );
  }

  Future<void> loadMoreCatalog() async {
    if (!catalogHasMore || isCatalogLoadingMore || isCatalogLoading) return;
    host.scheduleRebuild(() => isCatalogLoadingMore = true);
    await prefetchRegistryForCurrentFilters(append: true);
    if (host.mounted) {
      host.scheduleRebuild(() => isCatalogLoadingMore = false);
    }
  }

  Future<void> autoArchiveRegistryWorks({bool showFeedback = false}) async {
    final count = await HomeAutoArchive.run(
      prefetchFilters: prefetchRegistryForCurrentFilters,
      showFeedback: showFeedback,
      showMessage: showFeedback
          ? (msg) {
              if (!host.mounted) return;
              ScaffoldMessenger.of(host.context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            }
          : null,
    );
    if (count > 0) await loadItems();
  }

  List<BrowseCard> get filteredBrowseCards => browsePipeline.build(
        allUserItems: items,
        filters: filterCtrl.filterState,
      );

  bool get catalogUsesWindowedPrefetch =>
      dashboardCtrl.activeDashboardId == 'master_index' &&
      !isPersonalLibraryMode &&
      filterCtrl.domain == null &&
      filterCtrl.categories.isEmpty;

  bool get catalogHasMore =>
      catalogUsesWindowedPrefetch && catalogBrowseOffset < catalogTotalEntries;

  int get catalogLoadedThrough =>
      catalogBrowseOffset.clamp(0, catalogTotalEntries);

  Future<void> loadSidebarState() async {
    final open = await HomeSidebarPreferences.loadOpen();
    if (host.mounted) host.scheduleRebuild(() => isSidebarOpen = open);
  }

  Future<void> saveSidebarState(bool open) =>
      HomeSidebarPreferences.saveOpen(open);

  void toggleSidebar() {
    host.scheduleRebuild(() {
      isSidebarOpen = !isSidebarOpen;
      saveSidebarState(isSidebarOpen);
    });
  }

  Future<void> loadDashboards() async {
    final needsPrefetch = await sidebarCoordinator.loadDashboards();
    if (needsPrefetch) await prefetchRegistryForCurrentFilters();
    if (host.mounted) rebuild();
  }

  Future<void> loadPersonalLibraries() async {
    await sidebarCoordinator.loadPersonalLibraries();
    if (host.mounted) rebuild();
  }

  Future<void> selectDashboard(String id) async {
    host.scheduleRebuild(() {
      sidebarCoordinator.selectDashboard(id);
      workbench.showBrowse();
    });
    await prefetchRegistryForCurrentFilters();
  }

  void selectPersonalLibrary(String id) {
    host.scheduleRebuild(() {
      sidebarCoordinator.selectPersonalLibrary(id);
      workbench.showBrowse();
    });
  }

  bool get canAddToLibrary =>
      AkashaFileService().vaultPath != null &&
      personalLibCtrl.libraries.any((l) => l.isCurated);

  void onLibraryDragStarted() {
    if (!isSidebarOpen) {
      host.scheduleRebuild(() => isSidebarOpen = true);
      saveSidebarState(true);
    }
  }

  Future<void> syncCatalogContributionCount() async {
    await HomeDialogsFacade.refreshCatalogContributionCount(
      onCount: (count) {
        if (!host.mounted) return;
        host.scheduleRebuild(() => catalogContributionCount = count);
      },
    );
  }

  Future<void> openSearchDialog() async {
    await HomeDialogsFacade.showSearchDialog(
      context: host.context,
      localItems: items,
      onSelectLocal: openBrowseItem,
      onSelectRemote: (work) async {
        if (!host.mounted) return;
        openBrowseItem(HomeAutoArchive.itemFromRegistryWork(work));
      },
      onCustomAdd: (query) => HomeDialogsFacade.showAddDialog(
        context: host.context,
        initialTitle: query,
        onSavedToVault: (item) async {
          await AkashaFileService().saveItem(item);
          await loadItems();
        },
        onSavedInMemory: (item) =>
            host.scheduleRebuild(() => items.add(item)),
      ),
      onCatalogPropose: HomeDialogsFacade.catalogProposeCallback(
        context: host.context,
        refreshContributionCount: syncCatalogContributionCount,
        showMessage: (msg) {
          if (!host.mounted) return;
          ScaffoldMessenger.of(host.context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      ),
      onAddLocalToLibrary: canAddToLibrary
          ? (item) => libraryUi.showAddToLibraryForItem(
                host.context,
                item: item,
                isCuratedLibraryActive: isCuratedLibraryActive,
                items: items,
                resolveItemForOpen: resolveItemForOpen,
                setState: wrapSetState,
                onCreateLibrary: () => libraryUi.promptCreateCuratedLibrary(
                  host.context,
                  setState: wrapSetState,
                ),
              )
          : null,
      onAddRemoteToLibrary: canAddToLibrary
          ? (work) => libraryUi.addRegistryWorkToLibrary(
                host.context,
                work: work,
                isCuratedLibraryActive: isCuratedLibraryActive,
                items: items,
                resolveItemForOpen: resolveItemForOpen,
                setState: wrapSetState,
                onCreateLibrary: () => libraryUi.promptCreateCuratedLibrary(
                  host.context,
                  setState: wrapSetState,
                ),
              )
          : null,
    );
  }

  Future<void> onAddWorksFromLibraryEdit() async {
    await openSearchDialog();
    await loadItems();
  }

  void onDomainChanged(AppDomain? domain) {
    final needsPrefetch = filterCoordinator.onDomainChanged(domain);
    rebuild();
    if (needsPrefetch) prefetchRegistryForCurrentFilters();
  }

  void toggleCategory(MediaCategory category) {
    final needsPrefetch = filterCoordinator.toggleCategory(category);
    rebuild();
    if (needsPrefetch) prefetchRegistryForCurrentFilters();
  }

  void clearCategories() {
    final needsPrefetch = filterCoordinator.clearCategories();
    rebuild();
    if (needsPrefetch) prefetchRegistryForCurrentFilters();
  }

  void toggleWorkStatus(String label) {
    host.scheduleRebuild(() => filterCoordinator.toggleWorkStatus(label));
  }

  void toggleMyStatus(String label) {
    host.scheduleRebuild(() => filterCoordinator.toggleMyStatus(label));
  }

  AkashaItem resolveItemForOpen(AkashaItem item) {
    for (final existing in items) {
      if (item.workId.isNotEmpty && existing.workId == item.workId) {
        return existing;
      }
      if (existing.title == item.title &&
          existing.category == item.category) {
        return existing;
      }
    }
    return item;
  }

  void openBrowseItem(AkashaItem item) {
    workbench.openWork(resolveItemForOpen(item));
    if (host.mounted) rebuild();
  }

  Future<void> onWorkbenchWorkSaved(AkashaItem saved) async {
    await loadItems();
    if (!host.mounted) return;
    workbench.updateTabItem(WorkTab.idFor(saved), saved, dirty: false);
  }

  Future<void> onWorkbenchWorkDeleted(String tabId, AkashaItem item) async {
    workbench.closeTab(tabId);
    if (host.mounted) {
      host.scheduleRebuild(() {
        items.removeWhere((e) =>
            (item.workId.isNotEmpty && e.workId == item.workId) ||
            (e.title == item.title && e.category == item.category));
      });
    }
    await loadItems();
  }

  Widget buildPosterCard(BrowseCard card) => HomePosterCardFactory(
        allItems: items,
        libraryMembership: libraryMembership,
        hideActions: hideActions,
        isPersonalLibraryMode: isPersonalLibraryMode,
        canAddToLibrary: canAddToLibrary,
        onOpenItem: openBrowseItem,
        onOpenLibraryMenu: (c, pos) => libraryUi.openWorkLibraryMenu(
          host.context,
          card: c,
          anchor: pos,
          canAddToLibrary: canAddToLibrary,
          isCuratedLibraryActive: isCuratedLibraryActive,
          items: items,
          resolveItemForOpen: resolveItemForOpen,
          setState: wrapSetState,
          onCreateLibrary: () => libraryUi.promptCreateCuratedLibrary(
            host.context,
            setState: wrapSetState,
          ),
        ),
        onLibraryDragStarted: onLibraryDragStarted,
      ).build(card);

  Future<void> refreshLastSyncTime() async {
    await RegistrySyncService().init();
    if (!host.mounted) return;
    host.scheduleRebuild(
      () => lastSyncTime = RegistrySyncService().lastSyncTime,
    );
  }

  Future<void> syncRegistry() async {
    if (isSyncing) return;
    await registrySync.syncNow();
  }

  Future<void> clearRegistryCache() => registryUi.clearDiskCacheAndReload(
        host.context,
        dashboardCtrl: dashboardCtrl,
        filterCtrl: filterCtrl,
        onCatalogLoadingChanged: (v) => isCatalogLoading = v,
        isMounted: () => host.mounted,
        setState: wrapSetState,
        onDataChanged: rebuild,
      );

  Future<void> showCustomUrlDialog() async {
    await HomeDialogsFacade.showRegistrySync(
      context: host.context,
      isSyncing: isSyncing,
      lastSyncTime: lastSyncTime,
      onSyncNow: syncRegistry,
      onUrlSaved: refreshLastSyncTime,
    );
  }

  Future<void> showLibraryThemePicker() async {
    final picked = await HomeDialogsFacade.pickLibraryTheme(
      host.context,
      current: libraryTheme,
    );
    if (picked != null && host.mounted) {
      host.scheduleRebuild(() => libraryTheme = picked);
    }
  }

  bool get isPersonalLibraryMode => sidebarCoordinator.isPersonalLibraryMode;

  bool get isTimelineMode => filterCoordinator.isTimelineMode;

  void selectTimeline() {
    host.scheduleRebuild(() {
      sidebarCoordinator.selectTimeline();
      workbench.showBrowse();
    });
  }

  bool get isCuratedLibraryActive => sidebarCoordinator.isCuratedLibraryActive;

  List<BrowseCard> get personalBrowseCards {
    final library = personalLibCtrl.activeLibrary;
    if (library == null) return const [];
    return myLibraryPipeline.build(
      items,
      library: library,
      filters: filterCtrl.filterState,
    );
  }

  Future<void> openCatalogContributionsInbox() async {
    await HomeDialogsFacade.showCatalogContributionsInbox(host.context);
    await syncCatalogContributionCount();
  }

  Future<void> openVaultSettingsDialog() async {
    await HomeDialogsFacade.showVaultSettings(
      context: host.context,
      displayName: displayName,
      autoArchiveRegistry: autoArchiveRegistry,
      onDisplayNameSaved: (name) =>
          host.scheduleRebuild(() => displayName = name),
      onAutoArchiveChanged: (enabled) =>
          host.scheduleRebuild(() => autoArchiveRegistry = enabled),
      runAutoArchive: autoArchiveRegistryWorks,
      reloadItems: () async {
        await loadPersonalLibraries();
        await loadItems();
      },
      selectVaultFolder: selectVaultFolder,
      onRegistryVisibilityChanged: rebuild,
    );
  }

  Future<void> openClipboardImportDialog() async {
    await HomeDialogsFacade.showClipboardImport(
      context: host.context,
      existingItems: items,
      onItemImportedToVault: (_) async => loadItems(),
      onItemImportedInMemory: (item) =>
          host.scheduleRebuild(() => items.add(item)),
    );
  }

  Future<void> openTimelineQuickCapture() async {
    final saved = await HomeDialogsFacade.showTimelineQuickCapture(
      context: host.context,
      localItems: items,
      showMessage: (msg) {
        if (!host.mounted) return;
        ScaffoldMessenger.of(host.context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
    if (saved && host.mounted) {
      host.scheduleRebuild(() {
        timelineReloadToken++;
        sidebarCoordinator.selectTimeline();
        workbench.showBrowse();
      });
    }
  }

  Future<void> selectVaultFolder() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await AkashaFileService().setVaultPath(selectedDirectory);
        await loadPersonalLibraries();
        await loadItems();
        await autoArchiveRegistryWorks();
      }
    } catch (e) {
      if (host.mounted) {
        ScaffoldMessenger.of(host.context).showSnackBar(
          SnackBar(content: Text('볼트 연결에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> onCuratedReorder(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) async {
    await PersonalLibraryView.applyCuratedGridReorder(
      membership: libraryMembership,
      personalLibCtrl: personalLibCtrl,
      visibleCards: cards,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (host.mounted) rebuild();
  }
}
