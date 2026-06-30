import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../core/archiving/record_link.dart';
import '../../core/archiving/entity_anchor.dart';
import '../../core/ports/record_link_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/entity_link_selection.dart';
import '../../models/browse_entity_scope.dart';
import '../../features/workbench/data/workbench_controller.dart';
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
import '../../services/personal_library_membership_service.dart';
import '../../utils/recall_picker.dart';
import '../../widgets/dashboard_sidebar.dart';
import 'home_browse_filter_controller.dart';
import 'home_dashboard_controller.dart';
import 'home_collectible_collection_controller.dart';
import 'home_personal_library_controller.dart';
import 'home_section_preferences.dart';
import 'home_shell_body_center.dart';
import 'home_shell_body_preview_rail.dart';
import 'home_shell_browse_content.dart';

/// HomeShell Scaffold body — sidebar · 필터 · workbench browse 영역.
class HomeShellBody extends StatelessWidget {
  final bool isSidebarOpen;
  final bool isPersonalLibraryMode;
  final bool isCollectibleCollectionMode;
  final bool isTimelineMode;
  final bool isExploreBrowseMode;
  final bool isKnowledgeGraphMode;
  final bool isExploreModeActive;
  final bool isHomeDashboardMode;
  final bool isCuratedLibraryActive;
  final bool isCatalogLoading;
  final bool isCatalogLoadingMore;
  final bool catalogHasMore;
  final int catalogLoadedThrough;
  final int catalogTotalEntries;
  final VoidCallback? onLoadMoreCatalog;
  final bool canAddToLibrary;
  final bool vaultLinked;
  final String? vaultPath;
  final LibraryTheme libraryTheme;
  final String displayName;
  final List<AkashaItem> items;
  final List<AkashaItem> recentExploreItems;
  final RecordLinkPort linkIndex;
  final int linkIndexRevision;
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
  final Future<void> Function() onGoLibrary;
  final Future<void> Function() onGoCollection;
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
  final void Function(MediaCategory category) onToggleCategory;
  final VoidCallback onClearCategories;
  final void Function(String label) onToggleWorkStatus;
  final void Function(String label) onToggleMyStatus;
  final void Function(AkashaItem item) onOpenBrowseItem;
  final void Function(AkashaItem item) onOpenItemDetail;
  final void Function(UserCatalogEntity entity) onOpenEntityDetail;
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
  final VoidCallback onCloseAllPreviews;
  final VoidCallback onOpenWorkFromPreview;
  final Future<void> Function() onOpenEntityFromPreview;
  final EntityAnchorType? pendingWorkEntityLinkType;
  final String? pendingWorkEntityLinkWorkId;
  final LinkCandidate? pendingWorkEntityLinkCandidate;
  final bool pendingWorkLinkPick;
  final VoidCallback onClearPendingWorkEntityLink;
  final void Function(EntityAnchorType type) onConnectEntityFromPreview;
  final VoidCallback onConnectWorkFromPreview;
  final EntityAnchorType? pendingEntityEntityLinkType;
  final String? pendingEntityLinkEntityId;
  final bool pendingEntityWorkLinkPick;
  final VoidCallback onClearPendingEntityLink;
  final void Function(EntityAnchorType type) onConnectEntityFromEntityPreview;
  final VoidCallback onConnectWorkFromEntityPreview;
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
    required this.isHomeDashboardMode,
    required this.isCuratedLibraryActive,
    required this.isCatalogLoading,
    this.isCatalogLoadingMore = false,
    this.catalogHasMore = false,
    this.catalogLoadedThrough = 0,
    this.catalogTotalEntries = 0,
    this.onLoadMoreCatalog,
    required this.canAddToLibrary,
    required this.vaultLinked,
    required this.vaultPath,
    required this.libraryTheme,
    required this.displayName,
    required this.items,
    required this.recentExploreItems,
    required this.linkIndex,
    required this.linkIndexRevision,
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
    required this.onGoLibrary,
    required this.onGoCollection,
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
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.onOpenBrowseItem,
    required this.onOpenItemDetail,
    required this.onOpenEntityDetail,
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
    required this.onCloseAllPreviews,
    required this.onOpenWorkFromPreview,
    required this.onOpenEntityFromPreview,
    this.pendingWorkEntityLinkType,
    this.pendingWorkEntityLinkWorkId,
    this.pendingWorkEntityLinkCandidate,
    this.pendingWorkLinkPick = false,
    required this.onClearPendingWorkEntityLink,
    required this.onConnectEntityFromPreview,
    required this.onConnectWorkFromPreview,
    this.pendingEntityEntityLinkType,
    this.pendingEntityLinkEntityId,
    this.pendingEntityWorkLinkPick = false,
    required this.onClearPendingEntityLink,
    required this.onConnectEntityFromEntityPreview,
    required this.onConnectWorkFromEntityPreview,
    required this.onConnectSuggestedFromPreview,
    required this.onConnectSuggestedFromHome,
    required this.onGraphOpenRecord,
    required this.onPreviewRegistryWork,
    required this.onArchiveRegistryWorkFromPreview,
  });

  @override
  Widget build(BuildContext context) {
    final hasNoFilters = filterCtrl.categories.isEmpty &&
        filterCtrl.workStatuses.isEmpty &&
        filterCtrl.myStatuses.isEmpty &&
        filterCtrl.highlightEntityId == null;

    final dailyRecall = FeatureFlags.showRecallCard &&
            !isPersonalLibraryMode &&
            !isCollectibleCollectionMode &&
            !isTimelineMode
        ? RecallPicker.pickDailyRecall(items)
        : null;

    final browse = HomeShellBrowseContentBuilder(
      filterCtrl: filterCtrl,
      sectionPrefs: sectionPrefs,
      items: items,
      recentExploreItems: recentExploreItems,
      userCatalog: userCatalog,
      linkIndex: linkIndex,
      linkIndexRevision: linkIndexRevision,
      filteredCards: filteredCards,
      displayName: displayName,
      posterCardBuilder: posterCardBuilder,
      onStateChanged: onStateChanged,
      isCatalogLoading: isCatalogLoading,
      isCatalogLoadingMore: isCatalogLoadingMore,
      catalogHasMore: catalogHasMore,
      catalogLoadedThrough: catalogLoadedThrough,
      catalogTotalEntries: catalogTotalEntries,
      onLoadMoreCatalog: onLoadMoreCatalog,
      isCuratedLibraryActive: isCuratedLibraryActive,
      personalLibCtrl: personalLibCtrl,
      vaultPath: vaultPath,
      vaultLinked: vaultLinked,
      workPreviewItem: workPreviewItem,
      entityPreviewItem: entityPreviewItem,
      onNavigateWorkPreview: onNavigateWorkPreview,
      onNavigateEntityPreview: onNavigateEntityPreview,
      onSearch: onSearch,
      onGoExplore: onGoExplore,
      onGoExploreEntities: onGoExploreEntities,
      onGoKnowledgeGraph: onGoKnowledgeGraph,
      onSelectTimeline: onSelectTimeline,
      onConnectSuggestedFromHome: onConnectSuggestedFromHome,
      onPreviewRegistryWork: onPreviewRegistryWork,
      onOpenBrowseItem: onOpenBrowseItem,
      onOpenItemDetail: onOpenItemDetail,
      onOpenEntityDetail: onOpenEntityDetail,
      onGraphOpenRecord: onGraphOpenRecord,
      onPreviewWork: onPreviewWork,
      onPreviewEntity: onPreviewEntity,
      onCuratedReorder: onCuratedReorder,
      onAddNewEntity: onAddNewEntity,
    );

    return Row(
      children: [
        DashboardSidebar(
          isOpen: isSidebarOpen,
          isHomeMode: isHomeDashboardMode,
          isExploreMode: isExploreModeActive,
          isPersonalLibraryMode: isPersonalLibraryMode,
          isCollectibleCollectionMode: isCollectibleCollectionMode,
          isKnowledgeGraphMode: isKnowledgeGraphMode,
          isTimelineMode: isTimelineMode,
          selectionMode: personalLibCtrl.sidebarMode,
          recentExploreItems: recentExploreItems,
          vaultItems: items,
          collectibleCollections: collectionCtrl.collections,
          activeCollectibleCollectionId: collectionCtrl.activeCollectionId,
          onGoHome: onGoHome,
          onGoExplore: onGoExplore,
          onGoLibrary: onGoLibrary,
          onGoCollection: onGoCollection,
          onGoKnowledgeGraph: onGoKnowledgeGraph,
          onOpenRecentExplore: onOpenRecentExplore,
          activeDetailWorkId: workbench.hasOpenDetail
              ? workbench.activeWorkTab?.item.workId
              : null,
          activeDetailEntityId: workbench.hasOpenDetail
              ? workbench.activeEntityTab?.entity.entityId
              : null,
          onSelectTimeline: onSelectTimeline,
          onSelectCollectibleCollection: onSelectCollectibleCollection,
          onToggleSidebar: onToggleSidebar,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeShellBodyCenterColumn(
                  hasNoFilters: hasNoFilters,
                  vaultLinked: vaultLinked,
                  vaultPath: vaultPath,
                  dailyRecall: dailyRecall,
                  isPersonalLibraryMode: isPersonalLibraryMode,
                  isCollectibleCollectionMode: isCollectibleCollectionMode,
                  isTimelineMode: isTimelineMode,
                  isExploreBrowseMode: isExploreBrowseMode,
                  isKnowledgeGraphMode: isKnowledgeGraphMode,
                  isHomeDashboardMode: isHomeDashboardMode,
                  isCatalogLoading: isCatalogLoading,
                  filterCtrl: filterCtrl,
                  sectionPrefs: sectionPrefs,
                  workbench: workbench,
                  userCatalog: userCatalog,
                  linkIndex: linkIndex,
                  items: items,
                  timelineReloadToken: timelineReloadToken,
                  collectionCtrl: collectionCtrl,
                  posterCardBuilder: posterCardBuilder,
                  browse: browse,
                  onConnectVault: onConnectVault,
                  onSearch: onSearch,
                  onToggleCategory: onToggleCategory,
                  onClearCategories: onClearCategories,
                  onToggleWorkStatus: onToggleWorkStatus,
                  onToggleMyStatus: onToggleMyStatus,
                  onEntityScopeChanged: onEntityScopeChanged,
                  onAddNewEntity: onAddNewEntity,
                  onStateChanged: onStateChanged,
                  onPreviewWork: onPreviewWork,
                  onPreviewEntity: onPreviewEntity,
                  onOpenBrowseItem: onOpenBrowseItem,
                  onOpenEntity: onOpenEntity,
                  onWorkbenchWorkSaved: onWorkbenchWorkSaved,
                  onWorkbenchWorkDeleted: onWorkbenchWorkDeleted,
                  onWorkbenchEntitySaved: onWorkbenchEntitySaved,
                  onWorkbenchEntityDeleted: onWorkbenchEntityDeleted,
                  onAddToLibrary: onAddToLibrary,
                  onAddToLibraryForEntity: onAddToLibraryForEntity,
                  onWikiLinkTap: onWikiLinkTap,
                  onRequestEntityLink: onRequestEntityLink,
                  onGoKnowledgeGraph: onGoKnowledgeGraph,
                  pendingWorkEntityLinkType: pendingWorkEntityLinkType,
                  pendingWorkEntityLinkWorkId: pendingWorkEntityLinkWorkId,
                  pendingWorkEntityLinkCandidate: pendingWorkEntityLinkCandidate,
                  pendingWorkLinkPick: pendingWorkLinkPick,
                  onClearPendingWorkEntityLink: onClearPendingWorkEntityLink,
                  pendingEntityEntityLinkType: pendingEntityEntityLinkType,
                  pendingEntityLinkEntityId: pendingEntityLinkEntityId,
                  pendingEntityWorkLinkPick: pendingEntityWorkLinkPick,
                  onClearPendingEntityLink: onClearPendingEntityLink,
                  onNewTimelineEntry: onNewTimelineEntry,
                  onNewJournalEntry: onNewJournalEntry,
                  onEntityCollectionCuratedReorder: onEntityCollectionCuratedReorder,
                  onCollectibleCollectionCuratedReorder:
                      onCollectibleCollectionCuratedReorder,
                ),
              ),
              ...buildHomeShellBodyPreviewPanels(
                workbenchHasOpenDetail: workbench.hasOpenDetail,
                workPreviewItem: workPreviewItem,
                entityPreviewItem: entityPreviewItem,
                userCatalog: userCatalog,
                linkIndex: linkIndex,
                linkIndexRevision: linkIndexRevision,
                vaultItems: items,
                canPopPreview: canPopPreview,
                onPopPreview: onPopPreview,
                onCloseAllPreviews: onCloseAllPreviews,
                onOpenWorkFromPreview: onOpenWorkFromPreview,
                onOpenEntityFromPreview: onOpenEntityFromPreview,
                onPreviewLinkedEntity: onPreviewLinkedEntity,
                onPreviewLinkedWork: onPreviewLinkedWork,
                onGoKnowledgeGraph: onGoKnowledgeGraph,
                onConnectEntityFromPreview: onConnectEntityFromPreview,
                onConnectWorkFromPreview: onConnectWorkFromPreview,
                onConnectEntityFromEntityPreview: onConnectEntityFromEntityPreview,
                onConnectWorkFromEntityPreview: onConnectWorkFromEntityPreview,
                onConnectSuggestedFromPreview: onConnectSuggestedFromPreview,
                onPreviewRegistryWork: onPreviewRegistryWork,
                onArchiveRegistryWorkFromPreview: onArchiveRegistryWorkFromPreview,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
