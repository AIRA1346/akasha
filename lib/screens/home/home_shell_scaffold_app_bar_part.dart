part of 'home_shell_scaffold.dart';

PreferredSizeWidget _homeShellScaffoldAppBar(
  BuildContext context,
  HomeShellController controller,
  ShellLayoutSpec layoutSpec,
) {
  return HomeAppBar(
    toolbarHeight: layoutSpec.appBarHeight,
    isSidebarOpen: controller.isSidebarOpen,
    isInspectorOpen: controller.isInspectorOpen,
    vaultLinked: controller.vaultLinked,
    onCommerce: controller.toggleCommerceSurface,
    commerceSelected: controller.isCommerceSurfaceOpen,
    onSettings: () => unawaited(
      showAppPreferencesDialog(
        context,
        onOpenAppTheme: controller.showAppThemePicker,
        onOpenCommerceCenter: controller.openCommerceSurface,
        onOpenVaultSettings: controller.openVaultSettingsDialog,
      ),
    ),
    onToggleSidebar: controller.toggleSidebar,
    onToggleInspector: controller.toggleInspector,
    onTimelineCapture: controller.openTimelineQuickCapture,
    onClipboardImport: controller.openClipboardImportDialog,
    onPromptTemplates: () => HomeDialogsFacade.showPromptTemplates(context),
    onVaultSettings: controller.openVaultSettingsDialog,
    onCatalogInbox: FeatureFlags.catalogContributions
        ? controller.openCatalogContributionsInbox
        : null,
    catalogContributionCount: controller.catalogContributionCount,
  );
}
