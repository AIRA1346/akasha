import 'home_section_preferences.dart';
import 'home_shell_controller_base.dart';

/// Vault·catalog bootstrap and sync.
mixin HomeShellControllerVaultMixin on HomeShellControllerBase {
  String? get vaultPath => vault.vaultPath;

  bool get vaultLinked => vault.isVaultLinked;

  Future<void> initVault() async {
    await vault.initService();
    await navigation.loadSidebarState();
    await navigation.loadDashboards();
    await navigation.loadPersonalLibraries();
    await navigation.loadCollectibleCollections();
    sectionPrefs = await HomeSectionPreferences.load();
    await vault.loadPreferences();
    final usesLegacyStartup = !vault.isVaultLinked || vault.autoArchiveRegistry;
    if (usesLegacyStartup) {
      await loadItems();
    } else {
      await navigation.enterWorkArchiveBrowse();
    }
    await loadRecentExploration();
    if (usesLegacyStartup) await vault.runStartupAutoArchiveIfNeeded();
    await prefetchRegistryForCurrentFilters();
    await refreshLastSyncTime();
    vault.bindVaultWatch(
      onVaultChanged: () async {
        if (!vault.hasLoadedItems) return;
        await loadItems();
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
