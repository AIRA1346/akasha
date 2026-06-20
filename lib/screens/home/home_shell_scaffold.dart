import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/feature_flags.dart';
import '../../models/akasha_item.dart';
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
    final filtered = controller.isPersonalLibraryMode
        ? controller.personalBrowseCards
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
              onWorkbenchWorkSaved: controller.onWorkbenchWorkSaved,
              onWorkbenchWorkDeleted: controller.onWorkbenchWorkDeleted,
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
              onCuratedReorder: controller.onCuratedReorder,
              onSearch: controller.openSearchDialog,
            ),
          ),
        ),
      ),
    );
  }
}
