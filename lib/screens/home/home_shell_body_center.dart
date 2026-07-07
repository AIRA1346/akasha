import 'package:flutter/material.dart';

import '../../core/archiving/entity_journal_entry.dart';
import '../../core/archiving/record_link.dart';
import '../../core/archiving/entity_anchor.dart';
import '../../core/ports/record_link_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../features/workbench/presentation/workbench_shell.dart';
import '../../models/akasha_item.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/entity_link_selection.dart';
import '../../models/browse_card.dart';
import '../../models/collectible_browse_item.dart';
import '../../models/entity_browse_card.dart';
import '../../models/enums.dart';
import '../../models/user_catalog_entity.dart';
import '../../services/link_candidate_service.dart';
import '../../utils/recall_picker.dart';
import '../../widgets/today_recall_card.dart';
import 'home_browse_search_chrome.dart';
import 'coordinators/home_shell_wiring.dart';
import 'home_browse_filter_controller.dart';
import 'home_collectible_collection_controller.dart';
import 'home_section_preferences.dart';
import 'home_shell_browse_content.dart';
import 'home_vault_banner.dart';
import 'views/catalog_entity_browse_view.dart';
import 'views/records_view.dart';

/// HomeShellBody — 필터 · recall · WorkbenchShell browse 영역.
class HomeShellBodyCenterColumn extends StatelessWidget {
  const HomeShellBodyCenterColumn({
    super.key,
    required this.vaultLinked,
    required this.vaultPath,
    required this.dailyRecall,
    required this.isPersonalLibraryMode,
    required this.isCollectibleCollectionMode,
    required this.isTimelineMode,
    required this.isExploreBrowseMode,
    required this.isKnowledgeGraphMode,
    required this.isHomeDashboardMode,
    required this.isCatalogLoading,
    required this.filterCtrl,
    required this.sectionPrefs,
    required this.workbench,
    required this.userCatalog,
    required this.linkIndex,
    required this.items,
    required this.timelineReloadToken,
    required this.collectionCtrl,
    required this.posterCardBuilder,
    required this.browse,
    required this.onConnectVault,
    required this.onSearch,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.onEntityScopeChanged,
    required this.onAddNewEntity,
    required this.onStateChanged,
    required this.onPreviewWork,
    required this.onPreviewEntity,
    required this.onOpenBrowseItem,
    required this.onOpenEntity,
    required this.onWorkbenchWorkSaved,
    required this.onWorkbenchWorkDeleted,
    required this.onWorkbenchEntitySaved,
    required this.onWorkbenchEntityDeleted,
    required this.onAddToLibrary,
    required this.onAddToLibraryForEntity,
    required this.onWikiLinkTap,
    required this.onRequestEntityLink,
    required this.onGoKnowledgeGraph,
    required this.pendingWorkEntityLinkType,
    required this.pendingWorkEntityLinkWorkId,
    required this.pendingWorkEntityLinkCandidate,
    required this.pendingWorkLinkPick,
    required this.onClearPendingWorkEntityLink,
    required this.pendingEntityEntityLinkType,
    required this.pendingEntityLinkEntityId,
    required this.pendingEntityWorkLinkPick,
    required this.onClearPendingEntityLink,
    required this.onNewTimelineEntry,
    required this.onNewJournalEntry,
    this.onEntityCollectionCuratedReorder,
    this.onCollectibleCollectionCuratedReorder,
  });

  final bool vaultLinked;
  final String? vaultPath;
  final DailyRecall? dailyRecall;
  final bool isPersonalLibraryMode;
  final bool isCollectibleCollectionMode;
  final bool isTimelineMode;
  final bool isExploreBrowseMode;
  final bool isKnowledgeGraphMode;
  final bool isHomeDashboardMode;
  final bool isCatalogLoading;
  final HomeBrowseFilterController filterCtrl;
  final HomeSectionPreferences sectionPrefs;
  final WorkbenchController workbench;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final List<AkashaItem> items;
  final int timelineReloadToken;
  final HomeCollectibleCollectionController collectionCtrl;
  final Widget Function(BrowseCard card) posterCardBuilder;
  final HomeShellBrowseContentBuilder browse;
  final VoidCallback onConnectVault;
  final VoidCallback onSearch;
  final void Function(MediaCategory category) onToggleCategory;
  final VoidCallback onClearCategories;
  final void Function(String label) onToggleWorkStatus;
  final void Function(String label) onToggleMyStatus;
  final void Function(BrowseEntityScope scope) onEntityScopeChanged;
  final void Function(EntityAnchorType? type)? onAddNewEntity;
  final VoidCallback onStateChanged;
  final void Function(AkashaItem item) onPreviewWork;
  final void Function(UserCatalogEntity entity) onPreviewEntity;
  final void Function(AkashaItem item) onOpenBrowseItem;
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
  final void Function(ParsedRecordLink link) onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  ) onRequestEntityLink;
  final Future<void> Function() onGoKnowledgeGraph;
  final EntityAnchorType? pendingWorkEntityLinkType;
  final String? pendingWorkEntityLinkWorkId;
  final LinkCandidate? pendingWorkEntityLinkCandidate;
  final bool pendingWorkLinkPick;
  final VoidCallback onClearPendingWorkEntityLink;
  final EntityAnchorType? pendingEntityEntityLinkType;
  final String? pendingEntityLinkEntityId;
  final bool pendingEntityWorkLinkPick;
  final VoidCallback onClearPendingEntityLink;
  final VoidCallback onNewTimelineEntry;
  final VoidCallback onNewJournalEntry;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!vaultLinked)
          HomeVaultBanner(onConnectVault: onConnectVault),
        if (!workbench.hasOpenDetail &&
            !isTimelineMode &&
            !isCollectibleCollectionMode)
          HomeBrowseSearchChrome(
            onSearch: onSearch,
            selectedCategories: filterCtrl.categories,
            selectedWorkStatuses: filterCtrl.workStatuses,
            selectedMyStatuses: filterCtrl.myStatuses,
            onToggleCategory: onToggleCategory,
            onClearCategories: onClearCategories,
            onToggleWorkStatus: onToggleWorkStatus,
            onToggleMyStatus: onToggleMyStatus,
            selectedEntityScope: filterCtrl.entityScope,
            onEntityScopeChanged: onEntityScopeChanged,
            onAddNewEntity: onAddNewEntity,
          ),
        if (!isPersonalLibraryMode &&
            !isCollectibleCollectionMode &&
            !isTimelineMode &&
            !workbench.hasOpenDetail &&
            isCatalogLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Column(
            children: [
              if (dailyRecall != null && !workbench.hasOpenDetail)
                TodayRecallCard(
                  recall: dailyRecall!,
                  onTap: () => onPreviewWork(dailyRecall!.item),
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
                  pendingWorkLinkPick: pendingWorkLinkPick,
                  onPendingWorkEntityLinkHandled: onClearPendingWorkEntityLink,
                  pendingEntityEntityLinkType: pendingEntityEntityLinkType,
                  pendingEntityLinkEntityId: pendingEntityLinkEntityId,
                  pendingEntityWorkLinkPick: pendingEntityWorkLinkPick,
                  onClearPendingEntityLink: onClearPendingEntityLink,
                  onRecordOpenWork: onOpenBrowseItem,
                  onRecordOpenEntity: onOpenEntity,
                  browseContent: _buildBrowseContent(),
                  vaultPath: vaultPath ?? '',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseContent() {
    if (isTimelineMode) {
      return RecordsView(
        vaultPath: vaultPath,
        vaultItems: items,
        onOpenWork: onOpenBrowseItem,
        onOpenEntity: onOpenEntity,
        onNewTimelineEntry: onNewTimelineEntry,
        onNewJournalEntry: onNewJournalEntry,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        reloadToken: timelineReloadToken,
      );
    }

    if (isCollectibleCollectionMode) {
      return CatalogEntityBrowseView(
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        vaultItems: items,
        vaultPath: vaultPath,
        onOpenWork: onPreviewWork,
        onOpenEntity: onPreviewEntity,
        scope: BrowseEntityScope.all,
        posterCardBuilder: posterCardBuilder,
        relatedWorksDiscoveryFactory: () =>
            HomeShellWiring.createEntityRelatedWorksDiscovery(
          linkIndex: linkIndex,
          vaultItems: items,
        ),
        collection: collectionCtrl.activeCollection,
        highlightEntityId: filterCtrl.highlightEntityId,
        entityGallerySort: sectionPrefs.entityGallerySort,
        onEntityGallerySortChanged: (criteria) {
          sectionPrefs.setEntityGallerySort(criteria, onStateChanged);
        },
        onCuratedReorder: collectionCtrl.activeCollection?.isCurated == true
            ? onEntityCollectionCuratedReorder
            : null,
        onCollectibleCuratedReorder:
            collectionCtrl.activeCollection?.isCurated == true
                ? onCollectibleCollectionCuratedReorder
                : null,
        onAddNewEntity: onAddNewEntity,
      );
    }

    if (isPersonalLibraryMode) {
      return browse.buildPersonalLibraryBrowseContent();
    }

    return browse.buildDashboardBrowseContent(
      isKnowledgeGraphMode: isKnowledgeGraphMode,
      isExploreBrowseMode: isExploreBrowseMode,
    );
  }
}
