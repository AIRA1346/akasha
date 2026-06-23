import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../core/archiving/record_link.dart';
import '../../core/archiving/entity_anchor.dart';
import '../../core/ports/record_link_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/entity_link_selection.dart';
import '../../models/browse_entity_scope.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../features/workbench/presentation/workbench_shell.dart';
import '../../models/akasha_item.dart';
import '../../models/collectible_browse_item.dart';
import '../../models/entity_browse_card.dart';
import '../../models/browse_card.dart';
import '../../models/dashboard_config.dart';
import '../../models/enums.dart';
import '../../models/library_theme.dart';
import '../../models/collectible_collection.dart';
import '../../models/personal_library_config.dart';
import '../../models/user_catalog_entity.dart';
import '../../models/registry_work.dart';
import '../../services/link_candidate_service.dart';
import '../../core/archiving/entity_journal_entry.dart';
import '../../models/work_drag_payload.dart';
import '../../services/file_service.dart';
import '../../services/personal_library_membership_service.dart';
import 'coordinators/home_shell_wiring.dart';
import '../../utils/recall_picker.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../widgets/filter_section.dart';
import '../../widgets/today_recall_card.dart';
import 'home_browse_filter_controller.dart';
import 'home_dashboard_controller.dart';
import 'home_collectible_collection_controller.dart';
import 'home_personal_library_controller.dart';
import 'home_section_preferences.dart';
import 'home_vault_banner.dart';
import 'views/catalog_entity_browse_view.dart';
import 'views/browse_view.dart';
import 'views/personal_library_view.dart';
import 'views/records_view.dart';
import 'views/dashboard_preview_panel.dart';
import 'views/entity_dashboard_preview_panel.dart';
import 'views/home_dashboard_view.dart';
import 'views/knowledge_graph_view.dart';

/// HomeShell Scaffold body — sidebar · 필터 · workbench browse 영역.
class HomeShellBody extends StatelessWidget {
  final bool isSidebarOpen;
  final bool isPersonalLibraryMode;
  final bool isCollectibleCollectionMode;
  final bool isTimelineMode;
  final bool isExploreBrowseMode;
  final bool isKnowledgeGraphMode;
  final bool isExploreModeActive;
  final bool isCuratedLibraryActive;
  final bool isCatalogLoading;
  final bool isCatalogLoadingMore;
  final bool catalogHasMore;
  final int catalogLoadedThrough;
  final int catalogTotalEntries;
  final VoidCallback? onLoadMoreCatalog;
  final bool canAddToLibrary;
  final LibraryTheme libraryTheme;
  final String displayName;
  final List<AkashaItem> items;
  final List<AkashaItem> recentExploreItems;
  final RecordLinkPort linkIndex;
  final List<BrowseCard> filteredCards;
  final HomeSectionPreferences sectionPrefs;
  final HomeBrowseFilterController filterCtrl;
  final HomeDashboardController dashboardCtrl;
  final HomePersonalLibraryController personalLibCtrl;
  final HomeCollectibleCollectionController collectionCtrl;
  final PersonalLibraryMembershipService libraryMembership;
  final WorkbenchController workbench;
  final Widget Function(BrowseCard) posterCardBuilder;
  final VoidCallback onStateChanged;
  final VoidCallback onAddDashboard;
  final Future<void> Function(String id) onSelectDashboard;
  final Future<void> Function() onGoHome;
  final Future<void> Function() onGoExplore;
  final Future<void> Function() onGoKnowledgeGraph;
  final Future<void> Function(BrowseEntityScope scope) onGoExploreEntities;
  final VoidCallback onVaultSettings;
  final void Function(DashboardConfig dash) onEditDashboard;
  final void Function(String id) onDeleteDashboard;
  final VoidCallback onAddPersonalLibrary;
  final VoidCallback onAddCollectibleCollection;
  final VoidCallback onSelectTimeline;
  final void Function(String id) onSelectPersonalLibrary;
  final void Function(String id) onSelectCollectibleCollection;
  final void Function(PersonalLibraryConfig lib) onEditPersonalLibrary;
  final void Function(String id) onDeletePersonalLibrary;
  final void Function(CollectibleCollection col) onEditCollectibleCollection;
  final void Function(String id) onDeleteCollectibleCollection;
  final Future<void> Function(String libraryId, WorkDragPayload payload)?
      onDropWorkToLibrary;
  final VoidCallback? onLibraryDragStarted;
  final VoidCallback onConnectVault;
  final void Function(AppDomain? domain) onDomainChanged;
  final void Function(MediaCategory category) onToggleCategory;
  final VoidCallback onClearCategories;
  final void Function(String label) onToggleWorkStatus;
  final void Function(String label) onToggleMyStatus;
  final void Function(AkashaItem item) onOpenBrowseItem;
  final void Function(AkashaItem item) onOpenRecentExplore;
  final Future<void> Function(UserCatalogEntity entity) onOpenEntity;
  final Future<void> Function(AkashaItem saved, {bool silent}) onWorkbenchWorkSaved;
  final Future<void> Function(String tabId, AkashaItem item) onWorkbenchWorkDeleted;
  final Future<void> Function(
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    bool silent,
  }) onWorkbenchEntitySaved;
  final Future<void> Function(String tabId) onWorkbenchEntityDeleted;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;
  final Future<void> Function(UserCatalogEntity entity)? onAddToLibraryForEntity;
  final Future<void> Function(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) onCuratedReorder;
  final Future<void> Function(
    List<EntityBrowseCard> visibleCards,
    int oldIndex,
    int newIndex,
  )? onEntityCollectionCuratedReorder;
  final Future<void> Function(
    List<CollectibleBrowseItem> visibleItems,
    int oldIndex,
    int newIndex,
  )? onCollectibleCollectionCuratedReorder;
  final VoidCallback onSearch;
  final VoidCallback onNewTimelineEntry;
  final VoidCallback onNewJournalEntry;
  final int timelineReloadToken;
  final UserCatalogPort userCatalog;
  final void Function(BrowseEntityScope scope) onEntityScopeChanged;
  final void Function(ParsedRecordLink link) onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  ) onRequestEntityLink;
  final void Function(EntityAnchorType? type)? onAddNewEntity;
  final VoidCallback? onToggleSidebar;
  final AkashaItem? workPreviewItem;
  final UserCatalogEntity? entityPreviewItem;
  final void Function(AkashaItem item) onPreviewWork;
  final void Function(UserCatalogEntity entity) onPreviewEntity;
  final void Function(AkashaItem item) onNavigateWorkPreview;
  final void Function(UserCatalogEntity entity) onNavigateEntityPreview;
  final void Function(AkashaItem item) onPreviewLinkedWork;
  final void Function(UserCatalogEntity entity) onPreviewLinkedEntity;
  final bool canPopPreview;
  final VoidCallback onPopPreview;
  final VoidCallback onCloseWorkPreview;
  final VoidCallback onCloseEntityPreview;
  final VoidCallback onOpenWorkFromPreview;
  final Future<void> Function() onOpenEntityFromPreview;
  final EntityAnchorType? pendingWorkEntityLinkType;
  final String? pendingWorkEntityLinkWorkId;
  final LinkCandidate? pendingWorkEntityLinkCandidate;
  final VoidCallback onClearPendingWorkEntityLink;
  final void Function(EntityAnchorType type) onConnectEntityFromPreview;
  final void Function(LinkCandidate candidate) onConnectSuggestedFromPreview;
  final void Function(LinkCandidate candidate, AkashaItem work)
      onConnectSuggestedFromHome;
  final VoidCallback onGraphOpenRecord;
  final void Function(RegistryWork work) onPreviewRegistryWork;
  final Future<void> Function() onArchiveRegistryWorkFromPreview;

  const HomeShellBody({
    super.key,
    required this.isSidebarOpen,
    required this.isPersonalLibraryMode,
    required this.isCollectibleCollectionMode,
    required this.isTimelineMode,
    required this.isExploreBrowseMode,
    required this.isKnowledgeGraphMode,
    required this.isExploreModeActive,
    required this.isCuratedLibraryActive,
    required this.isCatalogLoading,
    this.isCatalogLoadingMore = false,
    this.catalogHasMore = false,
    this.catalogLoadedThrough = 0,
    this.catalogTotalEntries = 0,
    this.onLoadMoreCatalog,
    required this.canAddToLibrary,
    required this.libraryTheme,
    required this.displayName,
    required this.items,
    required this.recentExploreItems,
    required this.linkIndex,
    required this.filteredCards,
    required this.sectionPrefs,
    required this.filterCtrl,
    required this.dashboardCtrl,
    required this.personalLibCtrl,
    required this.collectionCtrl,
    required this.libraryMembership,
    required this.workbench,
    required this.posterCardBuilder,
    required this.onStateChanged,
    required this.onAddDashboard,
    required this.onSelectDashboard,
    required this.onGoHome,
    required this.onGoExplore,
    required this.onGoKnowledgeGraph,
    required this.onGoExploreEntities,
    required this.onVaultSettings,
    required this.onEditDashboard,
    required this.onDeleteDashboard,
    required this.onAddPersonalLibrary,
    required this.onAddCollectibleCollection,
    required this.onSelectTimeline,
    required this.onSelectPersonalLibrary,
    required this.onSelectCollectibleCollection,
    required this.onEditPersonalLibrary,
    required this.onDeletePersonalLibrary,
    required this.onEditCollectibleCollection,
    required this.onDeleteCollectibleCollection,
    this.onDropWorkToLibrary,
    this.onLibraryDragStarted,
    required this.onConnectVault,
    required this.onDomainChanged,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.onOpenBrowseItem,
    required this.onOpenRecentExplore,
    required this.onOpenEntity,
    required this.onWorkbenchWorkSaved,
    required this.onWorkbenchWorkDeleted,
    required this.onWorkbenchEntitySaved,
    required this.onWorkbenchEntityDeleted,
    this.onAddToLibrary,
    this.onAddToLibraryForEntity,
    required this.onCuratedReorder,
    this.onEntityCollectionCuratedReorder,
    this.onCollectibleCollectionCuratedReorder,
    required this.onSearch,
    required this.onNewTimelineEntry,
    required this.onNewJournalEntry,
    required this.timelineReloadToken,
    required this.userCatalog,
    required this.onEntityScopeChanged,
    required this.onWikiLinkTap,
    required this.onRequestEntityLink,
    this.onAddNewEntity,
    this.onToggleSidebar,
    this.workPreviewItem,
    this.entityPreviewItem,
    required this.onPreviewWork,
    required this.onPreviewEntity,
    required this.onNavigateWorkPreview,
    required this.onNavigateEntityPreview,
    required this.onPreviewLinkedWork,
    required this.onPreviewLinkedEntity,
    required this.canPopPreview,
    required this.onPopPreview,
    required this.onCloseWorkPreview,
    required this.onCloseEntityPreview,
    required this.onOpenWorkFromPreview,
    required this.onOpenEntityFromPreview,
    this.pendingWorkEntityLinkType,
    this.pendingWorkEntityLinkWorkId,
    this.pendingWorkEntityLinkCandidate,
    required this.onClearPendingWorkEntityLink,
    required this.onConnectEntityFromPreview,
    required this.onConnectSuggestedFromPreview,
    required this.onConnectSuggestedFromHome,
    required this.onGraphOpenRecord,
    required this.onPreviewRegistryWork,
    required this.onArchiveRegistryWorkFromPreview,
  });

  @override
  Widget build(BuildContext context) {
    final hasNoFilters = filterCtrl.domain == null &&
        filterCtrl.categories.isEmpty &&
        filterCtrl.workStatuses.isEmpty &&
        filterCtrl.myStatuses.isEmpty &&
        filterCtrl.highlightEntityId == null;

    final dailyRecall = FeatureFlags.showRecallCard &&
            !isPersonalLibraryMode &&
            !isCollectibleCollectionMode &&
            !isTimelineMode
        ? RecallPicker.pickDailyRecall(items)
        : null;

    return Row(
      children: [
        DashboardSidebar(
          isOpen: isSidebarOpen,
          selectionMode: personalLibCtrl.sidebarMode,
          isExploreMode: isExploreModeActive,
          isKnowledgeGraphMode: isKnowledgeGraphMode,
          recentExploreItems: recentExploreItems,
          dashboards: dashboardCtrl.dashboards,
          activeDashboardId: dashboardCtrl.activeDashboardId,
          personalLibraries: personalLibCtrl.libraries,
          activePersonalLibraryId: personalLibCtrl.activeLibraryId,
          collectibleCollections: collectionCtrl.collections,
          activeCollectibleCollectionId: collectionCtrl.activeCollectionId,
          onAddDashboard: onAddDashboard,
          onSelectDashboard: (id) => onSelectDashboard(id),
          onGoHome: onGoHome,
          onGoExplore: onGoExplore,
          onGoKnowledgeGraph: onGoKnowledgeGraph,
          onOpenRecentExplore: onOpenRecentExplore,
          onEditDashboard: onEditDashboard,
          onDeleteDashboard: onDeleteDashboard,
          onAddPersonalLibrary: onAddPersonalLibrary,
          onAddCollectibleCollection: onAddCollectibleCollection,
          onSelectTimeline: onSelectTimeline,
          onSelectPersonalLibrary: onSelectPersonalLibrary,
          onSelectCollectibleCollection: onSelectCollectibleCollection,
          onEditPersonalLibrary: onEditPersonalLibrary,
          onDeletePersonalLibrary: onDeletePersonalLibrary,
          onEditCollectibleCollection: onEditCollectibleCollection,
          onDeleteCollectibleCollection: onDeleteCollectibleCollection,
          onDropWorkToLibrary: onDropWorkToLibrary,
          onLibraryDragStarted: onLibraryDragStarted,
          onToggleSidebar: onToggleSidebar,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
            children: [
              if (AkashaFileService().vaultPath == null)
                HomeVaultBanner(onConnectVault: onConnectVault),
              if (!workbench.hasOpenWork) ...[
                if (!isTimelineMode &&
                    !isCollectibleCollectionMode &&
                    (!hasNoFilters || isPersonalLibraryMode || isExploreBrowseMode))
                  FilterSection(
                    selectedDomain: filterCtrl.domain,
                    selectedCategories: filterCtrl.categories,
                    selectedWorkStatuses: filterCtrl.workStatuses,
                    selectedMyStatuses: filterCtrl.myStatuses,
                    onDomainChanged: onDomainChanged,
                    onToggleCategory: onToggleCategory,
                    onClearCategories: onClearCategories,
                    onToggleWorkStatus: onToggleWorkStatus,
                    onToggleMyStatus: onToggleMyStatus,
                    selectedEntityScope: filterCtrl.entityScope,
                    onEntityScopeChanged: onEntityScopeChanged,
                    onAddNewEntity: onAddNewEntity,
                  ),
                if (!isTimelineMode &&
                    !isCollectibleCollectionMode &&
                    (!hasNoFilters || isPersonalLibraryMode || isExploreBrowseMode))
                  const Divider(height: 1),
              ],
              if (!isPersonalLibraryMode &&
                  !isCollectibleCollectionMode &&
                  !isTimelineMode &&
                  !workbench.hasOpenWork &&
                  isCatalogLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: Column(
                  children: [
                    if (dailyRecall != null && !workbench.hasOpenWork)
                      TodayRecallCard(
                        recall: dailyRecall,
                        onTap: () => onPreviewWork(dailyRecall.item),
                      ),
                    Expanded(
                      child: WorkbenchShell(
                        controller: workbench,
                        userCatalog: userCatalog,
                        linkIndex: linkIndex,
                        vaultItems: items,
                        onWorkSaved: onWorkbenchWorkSaved,
                        onWorkDeleted: onWorkbenchWorkDeleted,
                        onEntitySaved: onWorkbenchEntitySaved,
                        onEntityDeleted: onWorkbenchEntityDeleted,
                        onAddToLibrary: onAddToLibrary,
                        onAddToLibraryForEntity: onAddToLibraryForEntity,
                        onWikiLinkTap: onWikiLinkTap,
                        onRequestEntityLink: onRequestEntityLink,
                        onGoKnowledgeGraph: () => onGoKnowledgeGraph(),
                        pendingWorkEntityLinkType: pendingWorkEntityLinkType,
                        pendingWorkEntityLinkWorkId: pendingWorkEntityLinkWorkId,
                        pendingWorkEntityLinkCandidate: pendingWorkEntityLinkCandidate,
                        onPendingWorkEntityLinkHandled:
                            onClearPendingWorkEntityLink,
                        onRecordOpenWork: onOpenBrowseItem,
                        onRecordOpenEntity: onOpenEntity,
                        browseContent: isTimelineMode
                            ? RecordsView(
                                vaultItems: items,
                                onOpenWork: onOpenBrowseItem,
                                onOpenEntity: onOpenEntity,
                                onNewTimelineEntry: onNewTimelineEntry,
                                onNewJournalEntry: onNewJournalEntry,
                                userCatalog: userCatalog,
                                linkIndex: linkIndex,
                                reloadToken: timelineReloadToken,
                              )
                            : isCollectibleCollectionMode
                            ? CatalogEntityBrowseView(
                                userCatalog: userCatalog,
                                linkIndex: linkIndex,
                                vaultItems: items,
                                onOpenWork: onPreviewWork,
                                onOpenEntity: onPreviewEntity,
                                scope: BrowseEntityScope.all,
                                posterCardBuilder: posterCardBuilder,
                                relatedWorksDiscoveryFactory: () =>
                                    HomeShellWiring
                                        .createEntityRelatedWorksDiscovery(
                                  linkIndex: linkIndex,
                                  vaultItems: items,
                                ),
                                collection: collectionCtrl.activeCollection,
                                highlightEntityId:
                                    filterCtrl.highlightEntityId,
                                entityGallerySort:
                                    sectionPrefs.entityGallerySort,
                                onEntityGallerySortChanged: (criteria) {
                                  sectionPrefs.setEntityGallerySort(
                                    criteria,
                                    onStateChanged,
                                  );
                                },
                                onCuratedReorder:
                                    collectionCtrl.activeCollection?.isCurated ==
                                            true
                                        ? onEntityCollectionCuratedReorder
                                        : null,
                                onCollectibleCuratedReorder:
                                    collectionCtrl.activeCollection?.isCurated ==
                                            true
                                        ? onCollectibleCollectionCuratedReorder
                                        : null,
                                onAddNewEntity: onAddNewEntity,
                              )
                            : isPersonalLibraryMode
                            ? _buildPersonalLibraryBrowseContent()
                            : _buildDashboardBrowseContent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
                ),
              ),
              if (workPreviewItem != null && !workbench.hasOpenDetail)
                DashboardPreviewPanel(
                  item: workPreviewItem!,
                  userCatalog: userCatalog,
                  linkIndex: linkIndex,
                  vaultItems: items,
                  canGoBack: canPopPreview,
                  onBack: onPopPreview,
                  onClose: onCloseWorkPreview,
                  onOpenDetail: onOpenWorkFromPreview,
                  onOpenEntity: onPreviewLinkedEntity,
                  onOpenWork: onPreviewLinkedWork,
                  onGoKnowledgeGraph: () => onGoKnowledgeGraph(),
                  onConnectEntityType: onConnectEntityFromPreview,
                  onConnectSuggested: onConnectSuggestedFromPreview,
                  onPreviewRegistryWork: onPreviewRegistryWork,
                  onArchiveRegistryWork: onArchiveRegistryWorkFromPreview,
                ),
              if (entityPreviewItem != null && !workbench.hasOpenDetail)
                EntityDashboardPreviewPanel(
                  entity: entityPreviewItem!,
                  userCatalog: userCatalog,
                  linkIndex: linkIndex,
                  vaultItems: items,
                  canGoBack: canPopPreview,
                  onBack: onPopPreview,
                  onClose: onCloseEntityPreview,
                  onOpenDetail: onOpenEntityFromPreview,
                  onOpenEntity: onPreviewLinkedEntity,
                  onOpenWork: onPreviewLinkedWork,
                  onGoKnowledgeGraph: () => onGoKnowledgeGraph(),
                  onPreviewRegistryWork: onPreviewRegistryWork,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardBrowseContent(BuildContext context) {
    final scope = filterCtrl.entityScope;

    final hasNoFilters = filterCtrl.domain == null &&
        filterCtrl.categories.isEmpty &&
        filterCtrl.workStatuses.isEmpty &&
        filterCtrl.myStatuses.isEmpty &&
        filterCtrl.highlightEntityId == null;

    if (isKnowledgeGraphMode) {
      return KnowledgeGraphView(
        vaultItems: items,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        onOpenWork: onNavigateWorkPreview,
        onOpenEntity: onNavigateEntityPreview,
        onOpenRecord: onGraphOpenRecord,
        onConnectEntity: onAddNewEntity == null
            ? null
            : () => onAddNewEntity!(null),
      );
    }

    if (hasNoFilters && !isExploreBrowseMode) {
      return HomeDashboardView(
        vaultItems: items,
        recentExploreItems: recentExploreItems,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        previewItem: workPreviewItem,
        entityPreviewItem: entityPreviewItem,
        onPreviewWork: onNavigateWorkPreview,
        onPreviewEntity: onNavigateEntityPreview,
        onSearch: onSearch,
        onVaultSettings: onVaultSettings,
        onGoExplore: onGoExplore,
        onGoExploreEntities: onGoExploreEntities,
        onGoKnowledgeGraph: onGoKnowledgeGraph,
        onTimeline: onSelectTimeline,
        onConnectSuggested: onConnectSuggestedFromHome,
        onPreviewRegistryWork: onPreviewRegistryWork,
        onOpenRecordFromHome: onOpenBrowseItem,
      );
    }

    if (!scope.showsWorkGrid) {
      return _buildCatalogEntityBrowse(scope);
    }

    final workGrid = BrowseView(
      filteredCards: filteredCards,
      sectionPrefs: sectionPrefs,
      filterCategories: filterCtrl.categories,
      isCatalogLoading: isCatalogLoading,
      isCatalogLoadingMore: isCatalogLoadingMore,
      catalogHasMore: catalogHasMore,
      catalogLoadedThrough: catalogLoadedThrough,
      catalogTotalEntries: catalogTotalEntries,
      onLoadMoreCatalog: onLoadMoreCatalog,
      displayName: displayName,
      posterCardBuilder: posterCardBuilder,
      onStateChanged: onStateChanged,
    );

    return _wrapWorkGridWithOptionalEntityStrip(scope, workGrid);
  }

  Widget _buildPersonalLibraryBrowseContent() {
    final scope = filterCtrl.entityScope;

    if (!scope.showsWorkGrid) {
      return _buildCatalogEntityBrowse(scope);
    }

    final workGrid = PersonalLibraryView(
      filteredCards: filteredCards,
      allItems: items,
      sectionPrefs: sectionPrefs,
      displayName: displayName,
      isCuratedLibraryActive: isCuratedLibraryActive,
      activeLibrary: personalLibCtrl.activeLibrary,
      posterCardBuilder: posterCardBuilder,
      onStateChanged: onStateChanged,
      onCuratedReorder: onCuratedReorder,
      onSearch: onSearch,
    );

    return _wrapWorkGridWithOptionalEntityStrip(scope, workGrid);
  }

  Widget _buildCatalogEntityBrowse(BrowseEntityScope scope) {
    return CatalogEntityBrowseView(
      userCatalog: userCatalog,
      linkIndex: linkIndex,
      vaultItems: items,
      onOpenWork: onPreviewWork,
      onOpenEntity: onPreviewEntity,
      scope: scope,
      highlightEntityId: filterCtrl.highlightEntityId,
      entityGallerySort: sectionPrefs.entityGallerySort,
      onEntityGallerySortChanged: (criteria) {
        sectionPrefs.setEntityGallerySort(criteria, onStateChanged);
      },
      onAddNewEntity: onAddNewEntity,
    );
  }

  Widget _wrapWorkGridWithOptionalEntityStrip(
    BrowseEntityScope scope,
    Widget workGrid,
  ) {
    if (!scope.showsEntityDiscoveryStrip) {
      return workGrid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _entityDiscoveryStrip(),
        Expanded(child: workGrid),
      ],
    );
  }

  Widget _entityDiscoveryStrip() {
    return CatalogEntityBrowseView(
      userCatalog: userCatalog,
      linkIndex: linkIndex,
      vaultItems: items,
      onOpenWork: onPreviewWork,
      onOpenEntity: onPreviewEntity,
      scope: BrowseEntityScope.all,
      compact: true,
      highlightEntityId: filterCtrl.highlightEntityId,
    );
  }
}
