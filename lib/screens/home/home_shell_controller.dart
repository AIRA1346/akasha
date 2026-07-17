import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../core/archiving/entity_journal_entry.dart';
import '../../core/ports/registry_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../models/user_catalog_entity.dart';
import 'coordinators/home_browse_coordinator.dart';
import 'coordinators/home_catalog_coordinator.dart';
import 'coordinators/home_dialogs_coordinator.dart';
import 'coordinators/home_entity_archive_ops.dart';
import 'coordinators/home_navigation_coordinator.dart';
import 'coordinators/home_preview_coordinator.dart';
import 'coordinators/home_recent_exploration_coordinator.dart';
import 'coordinators/home_shell_coordinator_bundle.dart';
import 'coordinators/home_shell_wiring.dart';
import 'coordinators/home_vault_coordinator.dart';
import 'coordinators/home_vault_watch_reactor.dart';
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
import 'home_shell_controller_base.dart';
import 'home_shell_controller_browse_mixin.dart';
import 'home_shell_controller_navigation_mixin.dart';
import 'home_shell_controller_preview_mixin.dart';
import 'home_shell_controller_state_mixin.dart';
import 'home_shell_controller_vault_mixin.dart';
import 'home_shell_controller_workbench_mixin.dart';
import 'home_shell_host.dart';
import 'home_utility_surface.dart';

/// Home 화면 조립·위임 (Wave 1.4 + E2).
class HomeShellController extends HomeShellControllerBase
    with
        HomeShellControllerStateMixin,
        HomeShellControllerVaultMixin,
        HomeShellControllerNavigationMixin,
        HomeShellControllerPreviewMixin,
        HomeShellControllerWorkbenchMixin,
        HomeShellControllerBrowseMixin {
  HomeShellController(this.host);

  HomeUtilitySurface? _activeUtilitySurface;

  HomeUtilitySurface? get activeUtilitySurface => _activeUtilitySurface;
  bool get isCommerceSurfaceOpen =>
      _activeUtilitySurface == HomeUtilitySurface.commerce;

  void openCommerceSurface() {
    if (isCommerceSurfaceOpen) return;
    wrapSetState(() => _activeUtilitySurface = HomeUtilitySurface.commerce);
  }

  void toggleCommerceSurface() {
    wrapSetState(() {
      _activeUtilitySurface = isCommerceSurfaceOpen
          ? null
          : HomeUtilitySurface.commerce;
    });
  }

  void closeUtilitySurface() {
    if (_activeUtilitySurface == null) return;
    wrapSetState(() => _activeUtilitySurface = null);
  }

  void _closeUtilitySurfaceAfterNavigation() {
    _activeUtilitySurface = null;
  }

  @override
  final HomeShellHost host;

  @override
  final HomeBrowseFilterController filterCtrl = HomeBrowseFilterController();
  @override
  final HomeDashboardController dashboardCtrl = HomeDashboardController();
  @override
  final HomePersonalLibraryController personalLibCtrl =
      HomePersonalLibraryController();
  @override
  final HomeCollectibleCollectionController collectionCtrl =
      HomeCollectibleCollectionController();
  @override
  final WorkbenchController workbench = WorkbenchController();
  @override
  final HomeRegistryUi registryUi = const HomeRegistryUi();
  @override
  final RegistryPort registry = HomeShellDefaultPorts.registry;
  @override
  final UserCatalogPort userCatalog = HomeShellDefaultPorts.userCatalog;
  final registrySyncPort = HomeShellDefaultPorts.registrySync;

  @override
  final HomeVaultWatchReactor vaultWatchReactor = HomeVaultWatchReactor();

  @override
  late HomeShellCoordinatorBundle coordinators;

  @override
  HomeVaultCoordinator get vault => coordinators.vault;
  @override
  HomeCatalogCoordinator get catalog => coordinators.catalog;
  @override
  HomeWorkbenchCoordinator get workbenchCoord => coordinators.workbenchCoord;
  @override
  HomeShellWiring get wiring => coordinators.wiring;
  @override
  HomeNavigationCoordinator get navigation => coordinators.navigation;
  @override
  HomeBrowseCoordinator get browse => coordinators.browse;
  @override
  HomeDialogsCoordinator get dialogs => coordinators.dialogs;
  @override
  HomeRecentExplorationCoordinator get recentExplore =>
      coordinators.recentExplore;
  @override
  HomePreviewCoordinator get preview => coordinators.preview;

  @override
  HomeSectionPreferences sectionPrefs = HomeSectionPreferences();

  @override
  void wrapSetState(void Function() mutate) => host.scheduleRebuild(mutate);

  @override
  void rebuild() => host.scheduleRebuild();

  @override
  void showSnack(String msg) {
    if (!host.mounted) return;
    ScaffoldMessenger.of(
      host.context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  void installCoordinators() {
    coordinators = HomeShellCoordinatorBundle.create(
      host: host,
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      personalLibCtrl: personalLibCtrl,
      collectionCtrl: collectionCtrl,
      workbench: workbench,
      sectionPrefs: sectionPrefs,
      registry: registry,
      userCatalog: userCatalog,
      registrySyncPort: registrySyncPort,
      showSnack: showSnack,
      rebuild: rebuild,
      wrapSetState: wrapSetState,
      onEntityArchived: onEntityArchived,
      onPreviewWork: (item, {bool push = false}) =>
          coordinators.preview.openWorkPreview(item, push: push),
      onOpenWorkDetail: (item) => coordinators.preview.openWorkDetail(item),
      onNavigationCommitted: _closeUtilitySurfaceAfterNavigation,
      autoArchiveRegistryWorks: ({bool showFeedback = false}) =>
          vault.autoArchiveRegistryWorks(
            showFeedback: showFeedback,
            showMessage: showFeedback ? showSnack : null,
          ),
    );
  }

  void onEntityArchived(UserCatalogEntity entity, EntityJournalEntry? entry) {
    HomeEntityArchiveOps.onEntityArchived(
      context: host.context,
      entity: entity,
      entry: entry,
      filterCtrl: filterCtrl,
      rebuild: rebuild,
      isMounted: () => host.mounted,
      showSnack: showSnack,
    );
  }

  HomeDashboardUi get dashboardUi => wiring.dashboardUi;
  HomeLibraryUi get libraryUi => wiring.libraryUi;
  HomePersonalLibraryUi get personalLibraryUi => wiring.personalLibraryUi;
  HomeCollectibleCollectionUi get collectionUi => wiring.collectionUi;

  Future<void> init() async {
    installCoordinators();
    workbenchCoord.attach();
    await initVault();
    if (FeatureFlags.catalogContributions) {
      await syncCatalogContributionCount();
    }
    await workbench.loadPrefs();
    workbenchCoord.captureWorkbenchLayout();
  }

  void dispose() {
    // 1) Invalidate in-flight vault watch fan-out first.
    vaultWatchReactor.dispose();
    // 2) Cancel vault subscription + debounce (and catalog timer).
    coordinators.dispose();
    // 3) Then detach workbench listener and dispose the notifier.
    workbenchCoord.dispose();
    workbench.dispose();
  }
}
