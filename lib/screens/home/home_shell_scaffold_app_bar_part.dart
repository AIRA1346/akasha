part of 'home_shell_scaffold.dart';

PreferredSizeWidget _homeShellScaffoldAppBar(
  BuildContext context,
  HomeShellController controller,
) {
  return HomeAppBar(
    isSidebarOpen: controller.isSidebarOpen,
    isSyncing: controller.isSyncing,
    vaultLinked: controller.vaultLinked,
    showLibraryThemeButton: controller.isPersonalLibraryMode,
    onLibraryTheme: controller.showLibraryThemePicker,
    libraryThemeAccent: controller.libraryTheme.accentColor,
    onToggleSidebar: controller.toggleSidebar,
    onSearch: controller.openSearchDialog,
    onTimelineCapture: controller.openTimelineQuickCapture,
    onClipboardImport: controller.openClipboardImportDialog,
    onSync: controller.syncRegistry,
    onSyncSettings: controller.showCustomUrlDialog,
    onPromptTemplates: () => HomeDialogsFacade.showPromptTemplates(context),
    onVaultSettings: controller.openVaultSettingsDialog,
    onClearRegistryCache: controller.clearRegistryCache,
    onCatalogInbox: FeatureFlags.catalogContributions
        ? controller.openCatalogContributionsInbox
        : null,
    catalogContributionCount: controller.catalogContributionCount,
  );
}
