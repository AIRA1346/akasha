part of 'home_shell_scaffold.dart';

Widget _homeShellScaffoldBody(
  BuildContext context,
  HomeShellController controller,
  List<BrowseCard> filtered,
  ShellLayoutSpec layoutSpec,
) {
  return HomeShellBody(
    layoutSpec: layoutSpec,
    onToggleSidebar: controller.toggleSidebar,
    isSidebarOpen: controller.isSidebarOpen,
    isInspectorOpen: controller.isInspectorOpen,
    destination: controller.currentDestination,
    activeUtilitySurface: controller.activeUtilitySurface,
    onCloseUtilitySurface: controller.closeUtilitySurface,
    isCuratedLibraryActive: controller.isCuratedLibraryActive,
    isCatalogLoading: controller.isCatalogLoading,
    isCatalogLoadingMore: controller.isCatalogLoadingMore,
    catalogHasMore: controller.catalogHasMore,
    catalogLoadedThrough: controller.catalogLoadedThrough,
    catalogTotalEntries: controller.catalogTotalEntries,
    onLoadMoreCatalog: controller.catalogUsesWindowedPrefetch
        ? controller.loadMoreCatalog
        : null,
    canAddToLibrary: controller.canAddToLibrary,
    vaultLinked: controller.vaultLinked,
    vaultPath: controller.vaultPath,
    displayName: controller.displayName,
    items: controller.items,
    recentExploreItems: controller.recentExploreItems,
    linkIndex: controller.linkIndex,
    linkIndexRevision: controller.linkIndexRevision,
    filteredCards: filtered,
    sectionPrefs: controller.sectionPrefs,
    filterCtrl: controller.filterCtrl,
    dashboardCtrl: controller.dashboardCtrl,
    personalLibCtrl: controller.personalLibCtrl,
    collectionCtrl: controller.collectionCtrl,
    libraryMembership: controller.libraryMembership,
    workbench: controller.workbench,
    posterCardBuilder: controller.buildPosterCard,
    onStateChanged: controller.rebuild,
    onAddDashboard: () => controller.dashboardUi.showEditDialog(
      controller.host.context,
      config: null,
      setState: controller.wrapSetState,
    ),
    onGoExplore: controller.goExplore,
    onGoKnowledgeGraph: controller.goKnowledgeGraph,
    onSelectDestination: controller.selectDestination,
    onGoExploreEntities: controller.goExploreEntities,
    onVaultSettings: controller.openVaultSettingsDialog,
    onSelectDashboard: controller.selectDashboard,
    onEditDashboard: (dash) => controller.dashboardUi.showEditDialog(
      controller.host.context,
      config: dash,
      setState: controller.wrapSetState,
    ),
    onDeleteDashboard: (id) => controller.dashboardUi.confirmDelete(
      controller.host.context,
      id: id,
      setState: controller.wrapSetState,
    ),
    onAddPersonalLibrary: () => controller.libraryUi.promptCreateCuratedLibrary(
      controller.host.context,
      setState: controller.wrapSetState,
    ),
    onAddCollectibleCollection: () => controller.collectionUi.promptCreate(
      controller.host.context,
      personalLibCtrl: controller.personalLibCtrl,
      setState: controller.wrapSetState,
      vaultItems: controller.items,
    ),
    onSelectTimeline: controller.selectTimeline,
    onNewTimelineEntry: controller.openTimelineQuickCapture,
    onNewJournalEntry: controller.openJournalQuickCapture,
    timelineReloadToken: controller.timelineReloadToken,
    userCatalog: controller.userCatalog,
    onEntityScopeChanged: controller.onEntityScopeChanged,
    onWikiLinkTap: controller.handleWikiLinkTap,
    onRequestEntityLink: controller.handleRequestEntityLink,
    onSelectPersonalLibrary: controller.selectPersonalLibrary,
    onSelectCollectibleCollection: controller.selectCollectibleCollection,
    onEditPersonalLibrary: (lib) => controller.personalLibraryUi.showEditDialog(
      controller.host.context,
      config: lib,
      vaultItems: controller.items,
      canAddToLibrary: controller.canAddToLibrary,
      onAddWorks: controller.onAddWorksFromLibraryEdit,
      setState: controller.wrapSetState,
    ),
    onDeletePersonalLibrary: (id) => controller.personalLibraryUi.confirmDelete(
      controller.host.context,
      id: id,
      setState: controller.wrapSetState,
    ),
    onEditCollectibleCollection: (col) =>
        controller.collectionUi.showEditDialog(
          controller.host.context,
          config: col,
          setState: controller.wrapSetState,
          vaultItems: controller.items,
        ),
    onDeleteCollectibleCollection: (id) =>
        controller.collectionUi.confirmDelete(
          controller.host.context,
          id: id,
          setState: controller.wrapSetState,
        ),
    onDropWorkToLibrary: controller.canAddToLibrary
        ? (String libraryId, WorkDragPayload payload) =>
              controller.libraryUi.onDropWorkToLibrary(
                controller.host.context,
                libraryId: libraryId,
                payload: payload,
                setState: controller.wrapSetState,
                selectPersonalLibrary: controller.selectPersonalLibrary,
              )
        : null,
    onLibraryDragStarted: controller.canAddToLibrary
        ? controller.onLibraryDragStarted
        : null,
    onConnectVault: controller.selectVaultFolder,
    onCreateDefaultVault: controller.createDefaultVault,
    onToggleCategory: controller.toggleCategory,
    onClearCategories: controller.clearCategories,
    onToggleWorkStatus: controller.toggleWorkStatus,
    onToggleMyStatus: controller.toggleMyStatus,
    onOpenBrowseItem: controller.openBrowseItem,
    onOpenWorkFromCanvas: controller.openWorkFromCanvas,
    onOpenEntityFromCanvas: controller.openEntityFromCanvas,
    onOpenItemDetail: controller.openItemDetail,
    onOpenEntityDetail: controller.openEntity,
    onOpenRecentExplore: controller.openRecentExploreItem,
    onOpenEntity: controller.openEntity,
    onOpenCanvas: (canvas) =>
        controller.openCanvas(canvas.canvasId, canvas.title),
    previewTarget: controller.previewTarget,
    onPreviewWork: controller.openWorkPreview,
    onPreviewEntity: controller.openEntityPreview,
    onNavigateWorkPreview: controller.navigateWorkPreview,
    onNavigateEntityPreview: controller.navigateEntityPreview,
    onPreviewLinkedWork: controller.previewLinkedWork,
    onPreviewLinkedEntity: controller.previewLinkedEntity,
    canPopPreview: controller.canPopPreview,
    onPopPreview: controller.popPreview,
    onCloseAllPreviews: controller.closeAllPreviews,
    onOpenWorkFromPreview: controller.openWorkFromPreview,
    onOpenEntityFromPreview: controller.openEntityFromPreview,
    pendingWorkEntityLinkType: controller.pendingWorkEntityLinkType,
    pendingWorkEntityLinkWorkId: controller.pendingWorkEntityLinkWorkId,
    pendingWorkEntityLinkCandidate: controller.pendingWorkEntityLinkCandidate,
    pendingWorkLinkPick: controller.pendingWorkLinkPick,
    onClearPendingWorkEntityLink: controller.clearPendingWorkEntityLinkType,
    onConnectEntityFromPreview: controller.openWorkFromPreviewToConnect,
    onConnectWorkFromPreview: controller.openWorkFromPreviewToConnectWork,
    pendingEntityEntityLinkType: controller.pendingEntityEntityLinkType,
    pendingEntityLinkEntityId: controller.pendingEntityLinkEntityId,
    pendingEntityWorkLinkPick: controller.pendingEntityWorkLinkPick,
    onClearPendingEntityLink: controller.clearPendingEntityLink,
    onConnectEntityFromEntityPreview: controller.openEntityFromPreviewToConnect,
    onConnectWorkFromEntityPreview:
        controller.openEntityFromPreviewToConnectWork,
    onConnectSuggestedFromPreview:
        controller.openWorkFromPreviewToConnectSuggested,
    onConnectSuggestedFromHome: controller.connectSuggestedForWork,
    onGraphOpenRecord: controller.openMostRecentWorkForRecord,
    onPreviewRegistryWork: controller.previewRegistryWork,
    onArchiveRegistryWorkFromPreview: controller.archiveRegistryWorkFromPreview,
    onWorkbenchWorkSaved: controller.onWorkbenchWorkSaved,
    onWorkbenchWorkDeleted: controller.onWorkbenchWorkDeleted,
    onWorkbenchEntitySaved: controller.onWorkbenchEntitySaved,
    onWorkbenchEntityDeleted: controller.onWorkbenchEntityDeleted,
    onAddToLibrary: controller.canAddToLibrary
        ? (AkashaItem item) => controller.libraryUi.showAddToLibraryForItem(
            controller.host.context,
            item: item,
            isCuratedLibraryActive: controller.isCuratedLibraryActive,
            items: controller.items,
            resolveItemForOpen: controller.resolveItemForOpen,
            setState: controller.wrapSetState,
            onCreateLibrary: () =>
                controller.libraryUi.promptCreateCuratedLibrary(
                  controller.host.context,
                  setState: controller.wrapSetState,
                ),
          )
        : null,
    onAddToLibraryForEntity: controller.canAddToLibrary
        ? (UserCatalogEntity entity) =>
              controller.libraryUi.showAddToLibraryForEntity(
                controller.host.context,
                entity: entity,
                isCuratedLibraryActive: controller.isCuratedLibraryActive,
                items: controller.items,
                setState: controller.wrapSetState,
                onCreateLibrary: () =>
                    controller.libraryUi.promptCreateCuratedLibrary(
                      controller.host.context,
                      setState: controller.wrapSetState,
                    ),
              )
        : null,
    onCuratedReorder: controller.onCuratedReorder,
    onEntityCollectionCuratedReorder:
        controller.onEntityCollectionCuratedReorder,
    onCollectibleCollectionCuratedReorder:
        controller.onCollectibleCollectionCuratedReorder,
    onSearch: controller.openSearchDialog,
    onAddNewEntity: controller.openAddEntityDialog,
  );
}
