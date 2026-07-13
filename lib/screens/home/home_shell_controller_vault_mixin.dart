import 'home_section_preferences.dart';
import 'home_shell_controller_base.dart';
import '../../services/local_derived_index_lifecycle.dart';

/// Vault·catalog bootstrap and sync.
mixin HomeShellControllerVaultMixin on HomeShellControllerBase {
  String? get vaultPath => vault.vaultPath;

  bool get vaultLinked => vault.isVaultLinked;

  Future<void> initVault() async {
    await vault.initService();
    // Cold-start path restore must rebind the derived Work-summary cache to
    // the same vault that FileService just activated (indexes + notify).
    await LocalDerivedIndexLifecycle.app.refresh();
    await navigation.loadSidebarState();
    await navigation.loadDashboards();
    await navigation.loadPersonalLibraries();
    await navigation.loadCollectibleCollections();
    sectionPrefs = await HomeSectionPreferences.load();
    await vault.loadPreferences();
    // Home dashboard (계속 탐험하기 / 사전에서 발견) still resolves against the
    // legacy vault item list. Skipping loadItems on linked cold-start left
    // Home empty until the user re-selected the folder (which calls loadItems).
    // A new/default profile lands on Home. Existing legacy sidebar selections
    // keep their mapped AppDestination instead of being overwritten here.
    await loadItems();
    await navigation.finalizeInitialDestination(
      vaultLinked: vault.isVaultLinked,
    );
    await loadRecentExploration();
    await vault.runStartupAutoArchiveIfNeeded();
    await prefetchRegistryForCurrentFilters();
    await refreshLastSyncTime();
    vault.bindVaultWatch(
      onVaultChanged: (change) async {
        await vault.applyVaultChange(change);
        await refreshRecentExploration();
        final vaultPath = this.vaultPath;
        if (vaultPath != null && vaultPath.isNotEmpty) {
          await workbench.syncEntityTabs(vaultPath);
        }
        host.scheduleRebuild(() => navigation.timelineReloadToken++);
      },
    );
    catalog.registrySync.checkAutoSync();
  }

  Future<void> loadItems() => vault.loadItems();

  Future<void> prefetchRegistryForCurrentFilters({bool append = false}) =>
      catalog.prefetchRegistryForCurrentFilters(append: append);

  Future<void> loadMoreCatalog() => catalog.loadMoreCatalog();

  Future<void> autoArchiveRegistryWorks({bool showFeedback = false}) =>
      vault.autoArchiveRegistryWorks(
        showFeedback: showFeedback,
        showMessage: showFeedback ? showSnack : null,
      );

  Future<void> refreshRecentExploration() => recentExplore.refresh();

  Future<void> loadRecentExploration() => recentExplore.load();

  Future<void> refreshLastSyncTime() => catalog.refreshLastSyncTime();

  Future<void> syncRegistry() => catalog.syncRegistry();

  Future<void> syncCatalogContributionCount() =>
      catalog.syncCatalogContributionCount();
}
