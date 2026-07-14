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
import '../../theme/akasha_palette.dart';
import '../../utils/app_l10n.dart';
import '../../utils/recall_picker.dart';
import '../../widgets/today_recall_card.dart';
import 'home_browse_search_chrome.dart';
import 'coordinators/home_shell_wiring.dart';
import 'app_destination.dart';
import 'home_browse_filter_controller.dart';
import 'home_collectible_collection_controller.dart';
import 'home_section_preferences.dart';
import 'home_shell_browse_content.dart';
import 'home_vault_banner.dart';
import 'views/catalog_entity_browse_view.dart';
import 'views/destination_context_header.dart';
import 'views/records_view.dart';

@visibleForTesting
bool shouldShowEmptyCollections({
  required AppDestination destination,
  required int collectionCount,
}) {
  return destination == AppDestination.collections && collectionCount == 0;
}

@visibleForTesting
Widget buildHomeShellEmptyCollectionsView({
  required VoidCallback onAddCollection,
}) {
  return _EmptyCollectionsView(onAddCollection: onAddCollection);
}

/// HomeShellBody — 필터 · recall · WorkbenchShell browse 영역.
class HomeShellBodyCenterColumn extends StatelessWidget {
  const HomeShellBodyCenterColumn({
    super.key,
    required this.vaultLinked,
    required this.vaultPath,
    required this.dailyRecall,
    required this.destination,
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
    required this.onCreateDefaultVault,
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
    this.onOpenWorkFromCanvas,
    this.onOpenEntityFromCanvas,
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
    required this.onAddCollectibleCollection,
    this.onEntityCollectionCuratedReorder,
    this.onCollectibleCollectionCuratedReorder,
  });

  final bool vaultLinked;
  final String? vaultPath;
  final DailyRecall? dailyRecall;
  final AppDestination destination;
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
  final VoidCallback onCreateDefaultVault;
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
  final void Function(AkashaItem item)? onOpenWorkFromCanvas;
  final Future<bool> Function(String entityId)? onOpenEntityFromCanvas;
  final Future<void> Function(AkashaItem saved, {bool silent})
  onWorkbenchWorkSaved;
  final Future<void> Function(String tabId, AkashaItem item)
  onWorkbenchWorkDeleted;
  final Future<void> Function(
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    bool silent,
  })
  onWorkbenchEntitySaved;
  final Future<void> Function(String tabId) onWorkbenchEntityDeleted;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;
  final Future<void> Function(UserCatalogEntity entity)?
  onAddToLibraryForEntity;
  final void Function(ParsedRecordLink link) onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )
  onRequestEntityLink;
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
  final VoidCallback onAddCollectibleCollection;
  final Future<void> Function(
    List<EntityBrowseCard> visibleCards,
    int oldIndex,
    int newIndex,
  )?
  onEntityCollectionCuratedReorder;
  final Future<void> Function(
    List<CollectibleBrowseItem> visibleItems,
    int oldIndex,
    int newIndex,
  )?
  onCollectibleCollectionCuratedReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!vaultLinked)
          HomeVaultBanner(
            onConnectVault: onConnectVault,
            onCreateDefaultVault: onCreateDefaultVault,
          ),
        if (!workbench.hasOpenDetail &&
            destination != AppDestination.timeline &&
            destination != AppDestination.collections)
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
        if (destination != AppDestination.library &&
            destination != AppDestination.collections &&
            destination != AppDestination.timeline &&
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
                  pendingWorkEntityLinkCandidate:
                      pendingWorkEntityLinkCandidate,
                  pendingWorkLinkPick: pendingWorkLinkPick,
                  onPendingWorkEntityLinkHandled: onClearPendingWorkEntityLink,
                  pendingEntityEntityLinkType: pendingEntityEntityLinkType,
                  pendingEntityLinkEntityId: pendingEntityLinkEntityId,
                  pendingEntityWorkLinkPick: pendingEntityWorkLinkPick,
                  onClearPendingEntityLink: onClearPendingEntityLink,
                  onRecordOpenWork: onOpenBrowseItem,
                  onRecordOpenEntity: onOpenEntity,
                  onCanvasOpenWork: onOpenWorkFromCanvas,
                  onCanvasOpenEntity: onOpenEntityFromCanvas,
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
    return DestinationContextFrame(
      destination: destination,
      child: _buildDestinationContent(),
    );
  }

  Widget _buildDestinationContent() {
    if (shouldShowEmptyCollections(
      destination: destination,
      collectionCount: collectionCtrl.collections.length,
    )) {
      return buildHomeShellEmptyCollectionsView(
        onAddCollection: onAddCollectibleCollection,
      );
    }

    if (destination == AppDestination.timeline) {
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

    if (destination == AppDestination.collections) {
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

    if (destination == AppDestination.library) {
      return browse.buildPersonalLibraryBrowseContent();
    }

    return browse.buildDashboardBrowseContent(destination: destination);
  }
}

class _EmptyCollectionsView extends StatelessWidget {
  const _EmptyCollectionsView({required this.onAddCollection});

  final VoidCallback onAddCollection;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 48,
            color: palette.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.sidebarNoCollections ?? 'No Collections',
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('empty-collections-add'),
            onPressed: onAddCollection,
            icon: const Icon(Icons.add),
            label: Text(l10n?.collectionAddTitle ?? 'Add Collection'),
          ),
        ],
      ),
    );
  }
}
