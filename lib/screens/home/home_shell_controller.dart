import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../core/archiving/record_link.dart';
import '../../core/archiving/entity_anchor.dart';
import '../../core/ports/record_link_port.dart';
import '../../core/ports/registry_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../data/adapters/user_catalog_store_adapter.dart';
import '../../core/ports/registry_sync_port.dart';
import '../../data/adapters/markdown_vault_adapter.dart';
import '../../data/adapters/registry_sync_adapter.dart';
import '../../data/adapters/works_registry_adapter.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../models/akasha_item.dart';
import '../../models/browse_card.dart';
import '../../models/collectible_browse_item.dart';
import '../../models/entity_browse_card.dart';
import '../../models/entity_link_selection.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/enums.dart';
import '../../models/library_theme.dart';
import '../../services/personal_library_membership_service.dart';
import '../../services/record_link_navigator.dart';
import 'coordinators/home_browse_coordinator.dart';
import 'coordinators/home_collection_reorder_ops.dart';
import 'coordinators/home_catalog_coordinator.dart';
import 'coordinators/home_dialogs_coordinator.dart';
import 'coordinators/home_entity_archive_ops.dart';
import 'coordinators/home_navigation_coordinator.dart';
import 'coordinators/home_preview_coordinator.dart';
import 'coordinators/home_recent_exploration_coordinator.dart';
import 'coordinators/home_shell_wiring.dart';
import 'coordinators/home_vault_coordinator.dart';
import 'coordinators/home_workbench_coordinator.dart';
import 'home_browse_filter_controller.dart';
import 'home_collectible_collection_controller.dart';
import 'home_collectible_collection_ui.dart';
import 'home_dashboard_controller.dart';
import 'home_dashboard_ui.dart';
import 'home_library_ui.dart';
import 'home_personal_library_controller.dart';
import 'home_personal_library_ui.dart';
import 'home_registry_ui.dart';
import 'home_section_preferences.dart';
import '../../core/archiving/entity_journal_entry.dart';
import '../../models/registry_work.dart';
import '../../models/user_catalog_entity.dart';
import '../../services/file_service.dart';
import '../../services/link_candidate_service.dart';
import 'dialogs/entity_link_picker_dialog.dart';
import 'home_shell_host.dart';

/// Home 화면 조립·위임 (Wave 1.4 + E2).
class HomeShellController {
  HomeShellController(this.host);

  final HomeShellHost host;

  final HomeBrowseFilterController filterCtrl = HomeBrowseFilterController();
  final HomeDashboardController dashboardCtrl = HomeDashboardController();
  final HomePersonalLibraryController personalLibCtrl =
      HomePersonalLibraryController();
  final HomeCollectibleCollectionController collectionCtrl =
      HomeCollectibleCollectionController();
  final WorkbenchController workbench = WorkbenchController();
  final HomeRegistryUi registryUi = const HomeRegistryUi();
  final RegistryPort registry = WorksRegistryAdapter();
  final UserCatalogPort userCatalog = UserCatalogStoreAdapter();
  final RegistrySyncPort registrySyncPort = RegistrySyncAdapter();

  late final HomeVaultCoordinator vault;
  late final HomeCatalogCoordinator catalog;
  late final HomeWorkbenchCoordinator workbenchCoord;
  late final HomeShellWiring wiring;
  late final HomeNavigationCoordinator navigation;
  late final HomeBrowseCoordinator browse;
  late final HomeDialogsCoordinator dialogs;
  late final HomeRecentExplorationCoordinator recentExplore;
  late final HomePreviewCoordinator preview;

  HomeSectionPreferences sectionPrefs = HomeSectionPreferences();

  EntityAnchorType? get pendingWorkEntityLinkType =>
      preview.pendingWorkEntityLinkType;
  String? get pendingWorkEntityLinkWorkId =>
      preview.pendingWorkEntityLinkWorkId;
  LinkCandidate? get pendingWorkEntityLinkCandidate =>
      preview.pendingWorkEntityLinkCandidate;
  bool get pendingWorkLinkPick => preview.pendingWorkLinkPick;
  EntityAnchorType? get pendingEntityEntityLinkType =>
      preview.pendingEntityEntityLinkType;
  String? get pendingEntityLinkEntityId => preview.pendingEntityLinkEntityId;
  bool get pendingEntityWorkLinkPick => preview.pendingEntityWorkLinkPick;

  List<AkashaItem> get recentExploreItems => recentExplore.items;

  void wrapSetState(void Function() mutate) => host.scheduleRebuild(mutate);

  void rebuild() => host.scheduleRebuild();

  void _showSnack(String msg) {
    if (!host.mounted) return;
    ScaffoldMessenger.of(host.context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _initCoordinators() {
    vault = HomeVaultCoordinator(
      vault: MarkdownVaultAdapter(),
      registry: registry,
      userCatalog: userCatalog,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      onVaultItemsSynced: workbench.syncFromVaultItems,
      prefetchRegistry: () => catalog.prefetchRegistryForCurrentFilters(),
    );

    workbenchCoord = HomeWorkbenchCoordinator(
      workbench: workbench,
      isMounted: () => host.mounted,
      rebuild: rebuild,
      getItems: () => vault.items,
      mutateItems: (m) => host.scheduleRebuild(() => m(vault.items)),
      reloadItems: () => vault.loadItems(),
    );

    recentExplore = HomeRecentExplorationCoordinator(
      isMounted: () => host.mounted,
      rebuild: rebuild,
      getVaultItems: () => vault.items,
      userCatalog: userCatalog,
    );

    preview = HomePreviewCoordinator(
      rebuild: rebuild,
      resolveItemForOpen: workbenchCoord.resolveItemForOpen,
      openBrowseItemInWorkbench: workbenchCoord.openBrowseItem,
      openEntityInWorkbench: workbenchCoord.openEntity,
      showBrowseInWorkbench: workbench.showBrowse,
      getVaultItems: () => vault.items,
      recordWorkExploration: recentExplore.store.recordWork,
      recordEntityExploration: recentExplore.store.recordEntity,
      showSnack: _showSnack,
      loadItems: () => vault.loadItems(),
      resolveEntity: userCatalog.getById,
    );

    wiring = HomeShellWiring.create(
      registry: registry,
      personalLibCtrl: personalLibCtrl,
      collectionCtrl: collectionCtrl,
      userCatalog: userCatalog,
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      sectionPrefs: sectionPrefs,
      workbenchCoord: workbenchCoord,
      reloadItems: () => vault.loadItems(),
      rebuild: rebuild,
      showMessage: _showSnack,
    );

    navigation = HomeNavigationCoordinator(
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      sidebarCoordinator: wiring.sidebarCoordinator,
      filterCoordinator: wiring.filterCoordinator,
      workbench: workbench,
      prefetchRegistry: () => catalog.prefetchRegistryForCurrentFilters(),
      rebuild: rebuild,
    );

    catalog = HomeCatalogCoordinator(
      registry: registry,
      registrySyncPort: registrySyncPort,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      isPersonalLibraryMode: () => navigation.isPersonalLibraryMode,
      showSuccess: _showSnack,
      showError: _showSnack,
      reloadItems: () => vault.loadItems(),
      autoArchiveWorks: ({bool showFeedback = false}) =>
          vault.autoArchiveRegistryWorks(
            showFeedback: showFeedback,
            showMessage: showFeedback ? _showSnack : null,
          ),
    );
    catalog.init();

    browse = HomeBrowseCoordinator(
      hostContext: () => host.context,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      rebuild: rebuild,
      wiring: wiring,
      navigation: navigation,
      workbenchCoord: workbenchCoord,
      filterCtrl: filterCtrl,
      personalLibCtrl: personalLibCtrl,
      getItems: () => vault.items,
      prefetchRegistry: () => catalog.prefetchRegistryForCurrentFilters(),
      wrapSetState: wrapSetState,
      onPreviewWork: openWorkPreview,
      onOpenWorkDetail: openWorkDetail,
    );

    dialogs = HomeDialogsCoordinator(
      hostContext: () => host.context,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      showMessage: _showSnack,
      wiring: wiring,
      vault: vault,
      catalog: catalog,
      navigation: navigation,
      workbenchCoord: workbenchCoord,
      getItems: () => vault.items,
      addItemInMemory: (item) => host.scheduleRebuild(() => vault.items.add(item)),
      loadItems: () => vault.loadItems(),
      loadPersonalLibraries: () => navigation.loadPersonalLibraries(),
      autoArchiveWorks: autoArchiveRegistryWorks,
      rebuild: rebuild,
      wrapSetState: wrapSetState,
      canAddToLibrary: () => browse.canAddToLibrary,
      userCatalog: userCatalog,
      onEntityArchived: onEntityArchived,
      getLinkIndex: () => vault.linkIndex,
      onPreviewLocalWork: openWorkPreview,
      onPreviewEntity: preview.openEntityPreview,
    );
  }

  Future<void> refreshRecentExploration() => recentExplore.refresh();

  Future<void> loadRecentExploration() => recentExplore.load();

  void onEntityArchived(UserCatalogEntity entity, EntityJournalEntry? entry) {
    HomeEntityArchiveOps.onEntityArchived(
      entity: entity,
      entry: entry,
      filterCtrl: filterCtrl,
      rebuild: rebuild,
      isMounted: () => host.mounted,
      showSnack: _showSnack,
    );
  }

  // —— Preview state (UI 호환) ——
  AkashaItem? get workPreviewItem => preview.workPreviewItem;
  UserCatalogEntity? get entityPreviewItem => preview.entityPreviewItem;
  bool get hasOpenPreview => preview.hasOpenPreview;
  bool get canPopPreview => preview.canPopPreview;

  // —— Vault / catalog state (UI 호환) ——
  List<AkashaItem> get items => vault.items;
  String get displayName => vault.displayName;
  bool get autoArchiveRegistry => vault.autoArchiveRegistry;
  LibraryTheme get libraryTheme => vault.libraryTheme;

  bool get isSyncing => catalog.isSyncing;
  bool get isCatalogLoading => catalog.isCatalogLoading;
  bool get isCatalogLoadingMore => catalog.isCatalogLoadingMore;
  int get catalogBrowseOffset => catalog.catalogBrowseOffset;
  int get catalogTotalEntries => catalog.catalogTotalEntries;
  DateTime? get lastSyncTime => catalog.lastSyncTime;
  int get catalogContributionCount => catalog.catalogContributionCount;
  bool get catalogUsesWindowedPrefetch => catalog.catalogUsesWindowedPrefetch;
  bool get catalogHasMore => catalog.catalogHasMore;
  int get catalogLoadedThrough => catalog.catalogLoadedThrough;

  bool get isSidebarOpen => navigation.isSidebarOpen;
  int get timelineReloadToken => navigation.timelineReloadToken;
  bool get isPersonalLibraryMode => navigation.isPersonalLibraryMode;
  bool get isCollectibleCollectionMode => navigation.isCollectibleCollectionMode;
  bool get isTimelineMode => navigation.isTimelineMode;
  bool get isRecordsMode => navigation.isRecordsMode;
  bool get isCuratedLibraryActive => navigation.isCuratedLibraryActive;
  bool get isHomeDashboardMode => navigation.isHomeDashboardMode;
  bool get isExploreBrowseMode => navigation.isExploreBrowseMode;
  bool get isKnowledgeGraphMode => navigation.isKnowledgeGraphMode;
  bool get isExploreModeActive => navigation.isExploreModeActive;
  bool get canAddToLibrary => browse.canAddToLibrary;

  PersonalLibraryMembershipService get libraryMembership =>
      browse.libraryMembership;

  RecordLinkPort get linkIndex => vault.linkIndex;
  int get linkIndexRevision => vault.linkIndexRevision;

  Future<void> handleWikiLinkTap(ParsedRecordLink link) async {
    if (!host.mounted) return;
    workbench.showBrowse();
    await RecordLinkNavigator.navigateLink(
      host.context,
      link: link,
      userCatalog: userCatalog,
      vaultItems: vault.items,
      onOpenWork: (item) {
        openWorkPreview(workbenchCoord.resolveItemForOpen(item));
      },
      onOpenEntity: (entity) async {
        openEntityPreview(entity);
      },
      linkIndex: vault.linkIndex,
    );
  }

  void clearPendingWorkEntityLinkType() => preview.clearPendingWork();

  void clearPendingEntityLink() => preview.clearPendingEntity();

  void openWorkFromPreviewToConnect(EntityAnchorType type) =>
      preview.openWorkFromPreviewToConnect(type);

  void openWorkFromPreviewToConnectWork() =>
      preview.openWorkFromPreviewToConnectWork();

  void openWorkFromPreviewToConnectSuggested(LinkCandidate candidate) =>
      preview.openWorkFromPreviewToConnectSuggested(candidate);

  void openEntityFromPreviewToConnect(EntityAnchorType type) =>
      preview.openEntityFromPreviewToConnect(type);

  void openEntityFromPreviewToConnectWork() =>
      preview.openEntityFromPreviewToConnectWork();

  void connectSuggestedForWork(LinkCandidate candidate, AkashaItem work) {
    preview.openWorkPreview(workbenchCoord.resolveItemForOpen(work));
    preview.openWorkFromPreviewToConnectSuggested(candidate);
  }

  void openMostRecentWorkForRecord() {
    final sorted = List<AkashaItem>.from(vault.items)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    if (sorted.isEmpty) return;
    openBrowseItem(sorted.first);
  }

  Future<EntityLinkSelection?> handleRequestEntityLink(
    BuildContext context,
    String selectedText,
  ) {
    return showEntityLinkPickerDialog(
      context,
      userCatalog: userCatalog,
      initialQuery: selectedText,
    );
  }

  // —— Wiring UI (scaffold) ——
  HomeDashboardUi get dashboardUi => wiring.dashboardUi;
  HomeLibraryUi get libraryUi => wiring.libraryUi;
  HomePersonalLibraryUi get personalLibraryUi => wiring.personalLibraryUi;
  HomeCollectibleCollectionUi get collectionUi => wiring.collectionUi;

  Future<void> init() async {
    _initCoordinators();
    workbenchCoord.attach();
    await initVault();
    if (FeatureFlags.catalogContributions) {
      await syncCatalogContributionCount();
    }
    await workbench.loadPrefs();
    workbenchCoord.captureWorkbenchLayout();
  }

  void dispose() {
    workbenchCoord.dispose();
    workbench.dispose();
    vault.dispose();
    catalog.dispose();
  }

  Future<void> initVault() async {
    await vault.initService();
    await navigation.loadSidebarState();
    await navigation.loadDashboards();
    await navigation.loadPersonalLibraries();
    await navigation.loadCollectibleCollections();
    sectionPrefs = await HomeSectionPreferences.load();
    await vault.loadPreferences();
    await loadItems();
    await loadRecentExploration();
    await vault.runStartupAutoArchiveIfNeeded();
    await prefetchRegistryForCurrentFilters();
    await refreshLastSyncTime();
    vault.bindVaultWatch(onVaultChanged: () async {
      await loadItems();
      await refreshRecentExploration();
      final vaultPath = AkashaFileService().vaultPath;
      if (vaultPath != null && vaultPath.isNotEmpty) {
        await workbench.syncEntityTabs(vaultPath);
      }
      host.scheduleRebuild(() => navigation.timelineReloadToken++);
    });
    catalog.registrySync.checkAutoSync();
  }

  Future<void> loadItems() => vault.loadItems();
  Future<void> prefetchRegistryForCurrentFilters({bool append = false}) =>
      catalog.prefetchRegistryForCurrentFilters(append: append);
  Future<void> loadMoreCatalog() => catalog.loadMoreCatalog();
  Future<void> autoArchiveRegistryWorks({bool showFeedback = false}) =>
      vault.autoArchiveRegistryWorks(
        showFeedback: showFeedback,
        showMessage: showFeedback ? _showSnack : null,
      );

  List<BrowseCard> get filteredBrowseCards => browse.filteredBrowseCards;
  List<BrowseCard> get personalBrowseCards => browse.personalBrowseCards;

  void toggleSidebar() => navigation.toggleSidebar();
  Future<void> loadDashboards() => navigation.loadDashboards();
  Future<void> loadPersonalLibraries() => navigation.loadPersonalLibraries();
  Future<void> loadCollectibleCollections() =>
      navigation.loadCollectibleCollections();
  Future<void> selectDashboard(String id) => navigation.selectDashboard(id);
  Future<void> goHome() => navigation.goHome();
  Future<void> goExplore() => navigation.goExplore();
  Future<void> goLibrary() => navigation.goLibrary();
  Future<void> goCollection() => navigation.goCollection();
  Future<void> goKnowledgeGraph() => navigation.goKnowledgeGraph();
  Future<void> goExploreEntities(BrowseEntityScope scope) =>
      navigation.goExploreEntities(scope);
  void selectPersonalLibrary(String id) => navigation.selectPersonalLibrary(id);
  void selectCollectibleCollection(String id) =>
      navigation.selectCollectibleCollection(id);
  void selectTimeline() => navigation.selectTimeline();
  void onLibraryDragStarted() => navigation.onLibraryDragStarted();

  Future<void> syncCatalogContributionCount() =>
      catalog.syncCatalogContributionCount();
  Future<void> openSearchDialog() => dialogs.openSearchDialog();
  Future<void> onAddWorksFromLibraryEdit() => dialogs.onAddWorksFromLibraryEdit();

  void toggleCategory(MediaCategory category) => browse.toggleCategory(category);
  void clearCategories() => browse.clearCategories();
  void toggleWorkStatus(String label) => browse.toggleWorkStatus(label);
  void toggleMyStatus(String label) => browse.toggleMyStatus(label);
  void onEntityScopeChanged(BrowseEntityScope scope) =>
      browse.onEntityScopeChanged(scope);

  AkashaItem resolveItemForOpen(AkashaItem item) =>
      workbenchCoord.resolveItemForOpen(item);
  void openBrowseItem(AkashaItem item) {
    preview.clearReturnSnapshot();
    preview.closeAllPreviews();
    workbenchCoord.openBrowseItem(item);
    recentExplore.store.recordWork(item.workId);
    rebuild();
  }

  Future<void> openWorkDetail(AkashaItem item) => preview.openWorkDetail(item);

  Future<void> openItemDetail(AkashaItem item) async {
    if (item is EntityItem) {
      final entity = userCatalog.getById(item.entityId) ??
          UserCatalogEntity.userLocal(
            entityId: item.entityId,
            type: item.entityType,
            title: item.title,
            subtype: item.category,
            addedAt: item.addedAt,
          );
      await openEntity(entity);
      return;
    }
    await openWorkDetail(item);
  }

  void openWorkPreview(AkashaItem item, {bool push = false}) =>
      preview.openWorkPreview(item, push: push);

  void closeAllPreviews() => preview.closeAllPreviews();

  void navigateWorkPreview(AkashaItem item) => preview.navigateWorkPreview(item);

  void navigateEntityPreview(UserCatalogEntity entity) =>
      preview.navigateEntityPreview(entity);

  void popPreview() => preview.popPreview();

  Future<void> openWorkFromPreview() => preview.openWorkFromPreview();

  void previewRegistryWork(RegistryWork work) =>
      preview.previewRegistryWork(work);

  Future<void> archiveRegistryWorkFromPreview() =>
      preview.archiveRegistryWorkFromPreview();

  void openEntityPreview(UserCatalogEntity entity, {bool push = false}) =>
      preview.openEntityPreview(entity, push: push);

  Future<void> openEntityFromPreview() => preview.openEntityFromPreview();

  void previewLinkedWork(AkashaItem work) => preview.previewLinkedWork(work);

  void previewLinkedEntity(UserCatalogEntity entity) =>
      preview.previewLinkedEntity(entity);

  Future<void> openEntity(UserCatalogEntity entity) async {
    preview.clearReturnSnapshot();
    preview.closeAllPreviews();
    await workbenchCoord.openEntity(entity);
    await recentExplore.store.recordEntity(entity.entityId);
    rebuild();
  }

  void openRecentExploreItem(AkashaItem item) {
    if (workbench.hasOpenDetail) {
      openItemDetail(item);
      return;
    }
    recentExplore.openItem(
      item,
      openEntityPreview: preview.openEntityPreview,
      openWorkPreview: preview.openWorkPreview,
    );
  }

  Future<void> onWorkbenchWorkSaved(AkashaItem saved, {bool silent = false}) async {
    await workbenchCoord.onWorkbenchWorkSaved(saved, silent: silent);
    if (!silent) {
      preview.maybeReturnAfterSave(workId: saved.workId);
    }
  }

  Future<void> onWorkbenchWorkDeleted(String tabId, AkashaItem item) async {
    preview.maybeClearReturnForWork(item.workId);
    await workbenchCoord.onWorkbenchWorkDeleted(tabId, item);
  }

  Future<void> onWorkbenchEntitySaved(
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    bool silent = false,
  }) async {
    await workbenchCoord.onWorkbenchEntitySaved(entity, journal);
    if (!silent) {
      preview.maybeReturnAfterSave(entityId: entity.entityId);
    }
  }

  Future<void> onWorkbenchEntityDeleted(String tabId) async {
    final tab = workbench.activeEntityTab;
    if (tab != null) {
      preview.maybeClearReturnForEntity(tab.entity.entityId);
    }
    await workbenchCoord.onWorkbenchEntityDeleted(tabId);
  }

  Widget buildPosterCard(BrowseCard card) => browse.buildPosterCard(card);

  Future<void> refreshLastSyncTime() => catalog.refreshLastSyncTime();
  Future<void> syncRegistry() => catalog.syncRegistry();
  Future<void> clearRegistryCache() => registryUi.clearDiskCacheAndReload(
        host.context,
        registry: registry,
        dashboardCtrl: dashboardCtrl,
        filterCtrl: filterCtrl,
        onCatalogLoadingChanged: (v) => catalog.isCatalogLoading = v,
        isMounted: () => host.mounted,
        setState: wrapSetState,
        onDataChanged: rebuild,
      );

  Future<void> showCustomUrlDialog() => dialogs.showCustomUrlDialog();
  Future<void> showLibraryThemePicker() => dialogs.showLibraryThemePicker();
  Future<void> openCatalogContributionsInbox() =>
      dialogs.openCatalogContributionsInbox();
  Future<void> openVaultSettingsDialog() => dialogs.openVaultSettingsDialog();
  Future<void> openClipboardImportDialog() => dialogs.openClipboardImportDialog();
  Future<void> openTimelineQuickCapture() => dialogs.openTimelineQuickCapture();
  Future<void> openJournalQuickCapture() => dialogs.openJournalQuickCapture();
  Future<void> selectVaultFolder() => dialogs.selectVaultFolder();
  Future<void> openAddEntityDialog(EntityAnchorType? forceType) =>
      dialogs.openAddEntityDialog(forceType);
  Future<void> onCuratedReorder(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) =>
      browse.onCuratedReorder(cards, oldIndex, newIndex);

  Future<void> onEntityCollectionCuratedReorder(
    List<EntityBrowseCard> visibleCards,
    int oldIndex,
    int newIndex,
  ) async {
    final changed = await HomeCollectionReorderOps.reorderEntityCollection(
      collectionCtrl: collectionCtrl,
      visibleCards: visibleCards,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (changed) rebuild();
  }

  Future<void> onCollectibleCollectionCuratedReorder(
    List<CollectibleBrowseItem> visibleItems,
    int oldIndex,
    int newIndex,
  ) async {
    final changed = await HomeCollectionReorderOps.reorderCollectibleCollection(
      collectionCtrl: collectionCtrl,
      visibleItems: visibleItems,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (changed) rebuild();
  }
}
