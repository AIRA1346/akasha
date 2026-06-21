import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/feature_flags.dart';
import '../../models/akasha_item.dart';
import '../../models/user_catalog_entity.dart';
import '../../models/browse_card.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/work_drag_payload.dart';
import 'dialogs/home_dialogs_facade.dart';
import 'home_app_bar.dart';
import 'home_shell_body.dart';
import 'home_shell_controller.dart';

/// CallbackShortcuts · Scaffold · AppBar · HomeShellBody (Wave 1.4).
class HomeShellScaffold extends StatelessWidget {
  const HomeShellScaffold({super.key, required this.controller});

  final HomeShellController controller;

  @override
  Widget build(BuildContext context) {
    final scope = controller.filterCtrl.entityScope;
    final filtered = controller.isPersonalLibraryMode
        ? (scope.showsWorkGrid
            ? controller.personalBrowseCards
            : const <BrowseCard>[])
        : controller.filteredBrowseCards;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.tab): () {
          if (ModalRoute.of(context)?.isCurrent == true) {
            controller.toggleSidebar();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Theme(
          data: controller.isPersonalLibraryMode
              ? Theme.of(context).copyWith(
                  scaffoldBackgroundColor:
                      controller.libraryTheme.backgroundColor,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        secondary: controller.libraryTheme.accentColor,
                      ),
                )
              : Theme.of(context),
          child: Scaffold(
            backgroundColor: controller.isPersonalLibraryMode
                ? controller.libraryTheme.backgroundColor
                : null,
            appBar: HomeAppBar(
              isSidebarOpen: controller.isSidebarOpen,
              isSyncing: controller.isSyncing,
              showLibraryThemeButton: controller.isPersonalLibraryMode,
              onLibraryTheme: controller.showLibraryThemePicker,
              libraryThemeAccent: controller.libraryTheme.accentColor,
              onToggleSidebar: controller.toggleSidebar,
              onSearch: controller.openSearchDialog,
              onTimelineCapture: controller.openTimelineQuickCapture,
              onClipboardImport: controller.openClipboardImportDialog,
              onSync: controller.syncRegistry,
              onSyncSettings: controller.showCustomUrlDialog,
              onPromptTemplates: () =>
                  HomeDialogsFacade.showPromptTemplates(context),
              onVaultSettings: controller.openVaultSettingsDialog,
              onClearRegistryCache: controller.clearRegistryCache,
              onCatalogInbox: FeatureFlags.catalogContributions
                  ? controller.openCatalogContributionsInbox
                  : null,
              catalogContributionCount: controller.catalogContributionCount,
            ),
            body: HomeShellBody(
              isSidebarOpen: controller.isSidebarOpen,
              isPersonalLibraryMode: controller.isPersonalLibraryMode,
              isCollectibleCollectionMode: controller.isCollectibleCollectionMode,
              isTimelineMode: controller.isTimelineMode,
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
              libraryTheme: controller.libraryTheme,
              displayName: controller.displayName,
              items: controller.items,
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
              onAddPersonalLibrary: () =>
                  controller.libraryUi.promptCreateCuratedLibrary(
                controller.host.context,
                setState: controller.wrapSetState,
              ),
              onAddCollectibleCollection: () =>
                  controller.collectionUi.promptCreate(
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
              linkIndex: controller.linkIndex,
              onEntityScopeChanged: controller.onEntityScopeChanged,
              onWikiLinkTap: controller.handleWikiLinkTap,
              onRequestEntityLink: controller.handleRequestEntityLink,
              onSelectPersonalLibrary: controller.selectPersonalLibrary,
              onSelectCollectibleCollection: controller.selectCollectibleCollection,
              onEditPersonalLibrary: (lib) =>
                  controller.personalLibraryUi.showEditDialog(
                controller.host.context,
                config: lib,
                vaultItems: controller.items,
                canAddToLibrary: controller.canAddToLibrary,
                onAddWorks: controller.onAddWorksFromLibraryEdit,
                setState: controller.wrapSetState,
              ),
              onDeletePersonalLibrary: (id) =>
                  controller.personalLibraryUi.confirmDelete(
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
              onLibraryDragStarted:
                  controller.canAddToLibrary ? controller.onLibraryDragStarted : null,
              onConnectVault: controller.selectVaultFolder,
              onDomainChanged: controller.onDomainChanged,
              onToggleCategory: controller.toggleCategory,
              onClearCategories: controller.clearCategories,
              onToggleWorkStatus: controller.toggleWorkStatus,
              onToggleMyStatus: controller.toggleMyStatus,
              onOpenBrowseItem: controller.openBrowseItem,
              onOpenEntity: controller.openEntity,
              onWorkbenchWorkSaved: controller.onWorkbenchWorkSaved,
              onWorkbenchWorkDeleted: controller.onWorkbenchWorkDeleted,
              onWorkbenchEntitySaved: controller.onWorkbenchEntitySaved,
              onWorkbenchEntityDeleted: controller.onWorkbenchEntityDeleted,
              onAddToLibrary: controller.canAddToLibrary
                  ? (AkashaItem item) =>
                      controller.libraryUi.showAddToLibraryForItem(
                        controller.host.context,
                        item: item,
                        isCuratedLibraryActive:
                            controller.isCuratedLibraryActive,
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
                        isCuratedLibraryActive:
                            controller.isCuratedLibraryActive,
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
            ),
            bottomNavigationBar: _buildBottomNavigationBar(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isHome = !controller.isPersonalLibraryMode &&
        !controller.isCollectibleCollectionMode &&
        !controller.isTimelineMode;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A), // 다크 블루
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomTabItem(
            icon: Icons.home_filled,
            label: '홈',
            isSelected: isHome,
            onTap: () {
              controller.filterCtrl.clearCategories();
              controller.filterCtrl.onDomainChanged(null);
              if (!isHome) {
                controller.selectDashboard('master_index');
              }
              controller.rebuild();
            },
          ),
          _buildBottomTabItem(
            icon: Icons.explore_outlined,
            label: '탐색',
            isSelected: false,
            onTap: () {
              controller.onEntityScopeChanged(BrowseEntityScope.all);
            },
          ),
          GestureDetector(
            onTap: controller.openSearchDialog,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF5D3FD3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5D3FD3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          _buildBottomTabItem(
            icon: Icons.book_outlined,
            label: '라이브러리',
            isSelected: controller.isPersonalLibraryMode,
            onTap: () {
              if (controller.personalLibCtrl.libraries.isNotEmpty) {
                controller.selectPersonalLibrary(
                  controller.personalLibCtrl.libraries.first.id,
                );
              } else {
                controller.showLibraryThemePicker();
              }
            },
          ),
          _buildBottomTabItem(
            icon: Icons.folder_open_outlined,
            label: '컬렉션',
            isSelected: controller.isCollectibleCollectionMode,
            onTap: () {
              if (controller.collectionCtrl.collections.isNotEmpty) {
                controller.selectCollectibleCollection(
                  controller.collectionCtrl.collections.first.id,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xFF6C63FF) : Colors.grey[500];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
