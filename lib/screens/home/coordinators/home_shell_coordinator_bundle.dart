import '../../../core/ports/registry_port.dart';
import '../../../core/ports/registry_sync_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/vault_port.dart';
import '../../../data/adapters/markdown_vault_adapter.dart';
import '../../../data/adapters/registry_sync_adapter.dart';
import '../../../data/adapters/user_catalog_store_adapter.dart';
import '../../../data/adapters/works_registry_adapter.dart';
import '../../../features/workbench/data/workbench_controller.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../home_browse_filter_controller.dart';
import '../home_collectible_collection_controller.dart';
import '../home_dashboard_controller.dart';
import '../home_personal_library_controller.dart';
import '../home_section_preferences.dart';
import '../home_shell_host.dart';
import 'home_browse_coordinator.dart';
import 'home_catalog_coordinator.dart';
import 'home_dialogs_coordinator.dart';
import 'home_navigation_coordinator.dart';
import 'home_preview_coordinator.dart';
import 'home_recent_exploration_coordinator.dart';
import 'home_shell_wiring.dart';
import 'home_vault_coordinator.dart';
import 'home_workbench_coordinator.dart';

/// Home shell coordinator graph — Wave 1.4 + E2 wiring.
class HomeShellCoordinatorBundle {
  HomeShellCoordinatorBundle._({
    required this.vault,
    required this.catalog,
    required this.workbenchCoord,
    required this.wiring,
    required this.navigation,
    required this.browse,
    required this.dialogs,
    required this.recentExplore,
    required this.preview,
  });

  final HomeVaultCoordinator vault;
  final HomeCatalogCoordinator catalog;
  final HomeWorkbenchCoordinator workbenchCoord;
  final HomeShellWiring wiring;
  final HomeNavigationCoordinator navigation;
  final HomeBrowseCoordinator browse;
  final HomeDialogsCoordinator dialogs;
  final HomeRecentExplorationCoordinator recentExplore;
  final HomePreviewCoordinator preview;

  factory HomeShellCoordinatorBundle.create({
    required HomeShellHost host,
    required HomeBrowseFilterController filterCtrl,
    required HomeDashboardController dashboardCtrl,
    required HomePersonalLibraryController personalLibCtrl,
    required HomeCollectibleCollectionController collectionCtrl,
    required WorkbenchController workbench,
    required HomeSectionPreferences sectionPrefs,
    required RegistryPort registry,
    required UserCatalogPort userCatalog,
    required RegistrySyncPort registrySyncPort,
    required void Function(String message) showSnack,
    required void Function() rebuild,
    required void Function(void Function()) wrapSetState,
    required void Function(UserCatalogEntity entity, EntityJournalEntry? entry)
        onEntityArchived,
    required void Function(AkashaItem item, {bool push}) onPreviewWork,
    required Future<void> Function(AkashaItem item) onOpenWorkDetail,
    required Future<void> Function({bool showFeedback}) autoArchiveRegistryWorks,
  }) {
    late final HomeCatalogCoordinator catalog;

    final vault = HomeVaultCoordinator(
      vault: MarkdownVaultAdapter(),
      registry: registry,
      userCatalog: userCatalog,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      onVaultItemsSynced: workbench.syncFromVaultItems,
      prefetchRegistry: () => catalog.prefetchRegistryForCurrentFilters(),
    );

    final workbenchCoord = HomeWorkbenchCoordinator(
      workbench: workbench,
      vault: vault.vault,
      isMounted: () => host.mounted,
      rebuild: rebuild,
      getItems: () => vault.items,
      mutateItems: (m) => host.scheduleRebuild(() => m(vault.items)),
      reloadItems: () => vault.loadItems(),
    );

    final recentExplore = HomeRecentExplorationCoordinator(
      isMounted: () => host.mounted,
      rebuild: rebuild,
      getVaultItems: () => vault.items,
      userCatalog: userCatalog,
    );

    final preview = HomePreviewCoordinator(
      vault: vault.vault,
      rebuild: rebuild,
      resolveItemForOpen: workbenchCoord.resolveItemForOpen,
      openBrowseItemInWorkbench: workbenchCoord.openBrowseItem,
      openEntityInWorkbench: workbenchCoord.openEntity,
      showBrowseInWorkbench: workbench.showBrowse,
      getVaultItems: () => vault.items,
      recordWorkExploration: recentExplore.store.recordWork,
      recordEntityExploration: recentExplore.store.recordEntity,
      showSnack: showSnack,
      loadItems: () => vault.loadItems(),
      resolveEntity: userCatalog.getById,
    );

    final wiring = HomeShellWiring.create(
      vault: vault.vault,
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
      showMessage: showSnack,
    );

    final navigation = HomeNavigationCoordinator(
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
      showSuccess: showSnack,
      showError: showSnack,
      reloadItems: () => vault.loadItems(),
      autoArchiveWorks: ({bool showFeedback = false}) =>
          vault.autoArchiveRegistryWorks(
            showFeedback: showFeedback,
            showMessage: showFeedback ? showSnack : null,
          ),
    );
    catalog.init();

    final browse = HomeBrowseCoordinator(
      hostContext: () => host.context,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      rebuild: rebuild,
      wiring: wiring,
      navigation: navigation,
      workbenchCoord: workbenchCoord,
      filterCtrl: filterCtrl,
      personalLibCtrl: personalLibCtrl,
      vault: vault.vault,
      getItems: () => vault.items,
      prefetchRegistry: () => catalog.prefetchRegistryForCurrentFilters(),
      wrapSetState: wrapSetState,
      onPreviewWork: onPreviewWork,
      onOpenWorkDetail: onOpenWorkDetail,
    );

    final dialogs = HomeDialogsCoordinator(
      hostContext: () => host.context,
      isMounted: () => host.mounted,
      scheduleRebuild: host.scheduleRebuild,
      showMessage: showSnack,
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
      onPreviewLocalWork: onPreviewWork,
      onPreviewEntity: preview.openEntityPreview,
    );

    return HomeShellCoordinatorBundle._(
      vault: vault,
      catalog: catalog,
      workbenchCoord: workbenchCoord,
      wiring: wiring,
      navigation: navigation,
      browse: browse,
      dialogs: dialogs,
      recentExplore: recentExplore,
      preview: preview,
    );
  }

  void dispose() {
    vault.dispose();
    catalog.dispose();
  }
}

/// Default ports for [HomeShellController].
abstract final class HomeShellDefaultPorts {
  static final RegistryPort registry = WorksRegistryAdapter();
  static final UserCatalogPort userCatalog = UserCatalogStoreAdapter();
  static final RegistrySyncPort registrySync = RegistrySyncAdapter();
  static final VaultPort vault = MarkdownVaultAdapter();
}
