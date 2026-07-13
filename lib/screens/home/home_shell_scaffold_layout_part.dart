part of 'home_shell_scaffold.dart';

List<BrowseCard> _homeShellScaffoldFilteredCards(
  HomeShellController controller,
) {
  final scope = controller.filterCtrl.entityScope;
  return controller.currentDestination == AppDestination.library
      ? (scope.showsWorkGrid
            ? controller.personalBrowseCards
            : const <BrowseCard>[])
      : controller.filteredBrowseCards;
}

void _homeShellHandleEscape(
  BuildContext context,
  HomeShellController controller,
  ShellLayoutSpec layoutSpec,
) {
  if (ModalRoute.of(context)?.isCurrent != true) return;

  switch (resolveShellEscapeTarget(
    layoutSpec: layoutSpec,
    sidebarOpen: controller.isSidebarOpen,
    previewOpen: controller.hasOpenPreview,
  )) {
    case ShellEscapeTarget.sidebar:
      controller.toggleSidebar();
      return;
    case ShellEscapeTarget.preview:
      controller.closeAllPreviews();
      return;
    case ShellEscapeTarget.none:
      return;
  }
}

Widget _homeShellScaffoldRoot(
  BuildContext context,
  HomeShellController controller,
  FocusNode shortcutFocusNode,
) {
  final filtered = _homeShellScaffoldFilteredCards(controller);
  final palette = context.akashaPalette;
  final layoutSpec = ShellLayoutSpec.resolve(MediaQuery.sizeOf(context).width);
  final modalDrawerOpen =
      controller.isSidebarOpen &&
      layoutSpec.sidebarPresentation == ShellSidebarPresentation.drawer;
  final appBar = _homeShellScaffoldAppBar(context, controller, layoutSpec);
  final destinationShortcuts = AppDestinationRegistry.shortcutBindings(
    enabled: () => ModalRoute.of(context)?.isCurrent == true,
    onSelected: (destination) {
      unawaited(controller.selectDestination(destination));
    },
  );

  return CallbackShortcuts(
    bindings: {
      ...destinationShortcuts,
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
        if (ModalRoute.of(context)?.isCurrent == true) {
          controller.toggleSidebar();
        }
      },
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
        if (ModalRoute.of(context)?.isCurrent == true) {
          controller.openSearchDialog();
        }
      },
      const SingleActivator(LogicalKeyboardKey.escape): () {
        _homeShellHandleEscape(context, controller, layoutSpec);
      },
    },
    child: Focus(
      focusNode: shortcutFocusNode,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: appBar.preferredSize,
          child: ExcludeFocus(excluding: modalDrawerOpen, child: appBar),
        ),
        body: _homeShellScaffoldBody(context, controller, filtered, layoutSpec),
        bottomNavigationBar: ExcludeFocus(
          excluding: modalDrawerOpen,
          child: _homeShellScaffoldBottomNavigationBar(
            context,
            controller,
            palette,
            layoutSpec,
          ),
        ),
      ),
    ),
  );
}
