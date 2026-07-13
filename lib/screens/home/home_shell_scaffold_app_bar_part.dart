part of 'home_shell_scaffold.dart';

PreferredSizeWidget _homeShellScaffoldAppBar(
  BuildContext context,
  HomeShellController controller,
  ShellLayoutSpec layoutSpec,
) {
  return HomeAppBar(
    toolbarHeight: layoutSpec.appBarHeight,
    isSidebarOpen: controller.isSidebarOpen,
    isSyncing: controller.isSyncing,
    vaultLinked: controller.vaultLinked,
    onSettings: () => unawaited(
      showAppPreferencesDialog(
        context,
        onOpenAppTheme: controller.showLibraryThemePicker,
        onOpenVaultSettings: controller.openVaultSettingsDialog,
      ),
    ),
    onToggleSidebar: controller.toggleSidebar,
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
