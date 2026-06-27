import 'package:flutter/material.dart';

import '../../core/archiving/entity_anchor.dart';
import '../../core/ports/record_link_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/akasha_item.dart';
import '../../models/browse_card.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/registry_work.dart';
import '../../models/user_catalog_entity.dart';
import '../../services/link_candidate_service.dart';
import 'home_browse_filter_controller.dart';
import 'home_personal_library_controller.dart';
import 'home_section_preferences.dart';
import 'views/browse_view.dart';
import 'views/catalog_entity_browse_view.dart';
import 'views/home_dashboard_view.dart';
import 'views/knowledge_graph_view.dart';
import 'views/personal_library_view.dart';

/// HomeShellBody — 대시보드·라이브러리·엔티티 browse 라우팅.
class HomeShellBrowseContentBuilder {
  const HomeShellBrowseContentBuilder({
    required this.filterCtrl,
    required this.sectionPrefs,
    required this.items,
    required this.recentExploreItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.linkIndexRevision,
    required this.filteredCards,
    required this.displayName,
    required this.posterCardBuilder,
    required this.onStateChanged,
    required this.isCatalogLoading,
    this.isCatalogLoadingMore = false,
    this.catalogHasMore = false,
    this.catalogLoadedThrough = 0,
    this.catalogTotalEntries = 0,
    this.onLoadMoreCatalog,
    required this.isCuratedLibraryActive,
    required this.personalLibCtrl,
    required this.vaultPath,
    required this.vaultLinked,
    required this.workPreviewItem,
    required this.entityPreviewItem,
    required this.onNavigateWorkPreview,
    required this.onNavigateEntityPreview,
    required this.onSearch,
    required this.onGoExplore,
    required this.onGoExploreEntities,
    required this.onGoKnowledgeGraph,
    required this.onSelectTimeline,
    required this.onConnectSuggestedFromHome,
    required this.onPreviewRegistryWork,
    required this.onOpenBrowseItem,
    required this.onOpenItemDetail,
    required this.onOpenEntityDetail,
    required this.onGraphOpenRecord,
    required this.onPreviewWork,
    required this.onPreviewEntity,
    required this.onCuratedReorder,
    this.onAddNewEntity,
  });

  final HomeBrowseFilterController filterCtrl;
  final HomeSectionPreferences sectionPrefs;
  final List<AkashaItem> items;
  final List<AkashaItem> recentExploreItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final int linkIndexRevision;
  final List<BrowseCard> filteredCards;
  final String displayName;
  final Widget Function(BrowseCard) posterCardBuilder;
  final VoidCallback onStateChanged;
  final bool isCatalogLoading;
  final bool isCatalogLoadingMore;
  final bool catalogHasMore;
  final int catalogLoadedThrough;
  final int catalogTotalEntries;
  final VoidCallback? onLoadMoreCatalog;
  final bool isCuratedLibraryActive;
  final HomePersonalLibraryController personalLibCtrl;
  final String? vaultPath;
  final bool vaultLinked;
  final AkashaItem? workPreviewItem;
  final UserCatalogEntity? entityPreviewItem;
  final void Function(AkashaItem item) onNavigateWorkPreview;
  final void Function(UserCatalogEntity entity) onNavigateEntityPreview;
  final VoidCallback onSearch;
  final Future<void> Function() onGoExplore;
  final Future<void> Function(BrowseEntityScope scope) onGoExploreEntities;
  final Future<void> Function() onGoKnowledgeGraph;
  final VoidCallback onSelectTimeline;
  final void Function(LinkCandidate candidate, AkashaItem work)
      onConnectSuggestedFromHome;
  final void Function(RegistryWork work) onPreviewRegistryWork;
  final void Function(AkashaItem item) onOpenBrowseItem;
  final void Function(AkashaItem item) onOpenItemDetail;
  final void Function(UserCatalogEntity entity) onOpenEntityDetail;
  final VoidCallback onGraphOpenRecord;
  final void Function(AkashaItem item) onPreviewWork;
  final void Function(UserCatalogEntity entity) onPreviewEntity;
  final Future<void> Function(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) onCuratedReorder;
  final void Function(EntityAnchorType? type)? onAddNewEntity;

  Widget buildDashboardBrowseContent({
    required bool isKnowledgeGraphMode,
    required bool isExploreBrowseMode,
  }) {
    final scope = filterCtrl.entityScope;

    final hasNoFilters = filterCtrl.categories.isEmpty &&
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
        onConnectEntity:
            onAddNewEntity == null ? null : () => onAddNewEntity!(null),
      );
    }

    final showHomeDashboard =
        hasNoFilters && !isExploreBrowseMode && scope.showsWorkGrid;

    if (showHomeDashboard) {
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
        onGoExplore: onGoExplore,
        onGoExploreEntities: onGoExploreEntities,
        onGoKnowledgeGraph: onGoKnowledgeGraph,
        onTimeline: onSelectTimeline,
        onConnectSuggested: onConnectSuggestedFromHome,
        onPreviewRegistryWork: onPreviewRegistryWork,
        onOpenRecordFromHome: onOpenBrowseItem,
        onOpenItemDetail: onOpenItemDetail,
        onOpenEntityDetail: onOpenEntityDetail,
      );
    }

    if (!scope.showsWorkGrid) {
      return buildCatalogEntityBrowse(scope);
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

    return wrapWorkGridWithOptionalEntityStrip(scope, workGrid);
  }

  Widget buildPersonalLibraryBrowseContent() {
    final scope = filterCtrl.entityScope;

    if (!scope.showsWorkGrid) {
      return buildCatalogEntityBrowse(scope);
    }

    final workGrid = PersonalLibraryView(
      filteredCards: filteredCards,
      allItems: items,
      vaultLinked: vaultLinked,
      sectionPrefs: sectionPrefs,
      displayName: displayName,
      isCuratedLibraryActive: isCuratedLibraryActive,
      activeLibrary: personalLibCtrl.activeLibrary,
      posterCardBuilder: posterCardBuilder,
      onStateChanged: onStateChanged,
      onCuratedReorder: onCuratedReorder,
      onSearch: onSearch,
    );

    return wrapWorkGridWithOptionalEntityStrip(scope, workGrid);
  }

  Widget buildCatalogEntityBrowse(BrowseEntityScope scope) {
    return CatalogEntityBrowseView(
      userCatalog: userCatalog,
      linkIndex: linkIndex,
      vaultItems: items,
      vaultPath: vaultPath,
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

  Widget wrapWorkGridWithOptionalEntityStrip(
    BrowseEntityScope scope,
    Widget workGrid,
  ) {
    if (!scope.showsEntityDiscoveryStrip) {
      return workGrid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildEntityDiscoveryStrip(),
        Expanded(child: workGrid),
      ],
    );
  }

  Widget buildEntityDiscoveryStrip() {
    return CatalogEntityBrowseView(
      userCatalog: userCatalog,
      linkIndex: linkIndex,
      vaultItems: items,
      vaultPath: vaultPath,
      onOpenWork: onPreviewWork,
      onOpenEntity: onPreviewEntity,
      scope: BrowseEntityScope.all,
      compact: true,
      highlightEntityId: filterCtrl.highlightEntityId,
    );
  }
}
