part of 'home_shell_scaffold.dart';

List<BrowseCard> _homeShellScaffoldFilteredCards(
  HomeShellController controller,
) {
  final scope = controller.filterCtrl.entityScope;
  return controller.isPersonalLibraryMode
      ? (scope.showsWorkGrid
            ? controller.personalBrowseCards
            : const <BrowseCard>[])
      : controller.filteredBrowseCards;
}

void _homeShellHandleEscape(
  BuildContext context,
  HomeShellController controller,
) {
  if (ModalRoute.of(context)?.isCurrent != true) return;

  if (controller.hasOpenPreview) {
    controller.closeAllPreviews();
    return;
  }

  unawaited(
    showAppPreferencesDialog(
      context,
      onOpenAppTheme: controller.showLibraryThemePicker,
      onOpenVaultSettings: controller.openVaultSettingsDialog,
    ),
  );
}

Widget _homeShellScaffoldRoot(
  BuildContext context,
  HomeShellController controller,
  FocusNode shortcutFocusNode,
) {
  final filtered = _homeShellScaffoldFilteredCards(controller);
  final themedData = AkashaTheme.withAppTheme(
    Theme.of(context),
    controller.libraryTheme,
  );
  final palette =
      themedData.extension<AkashaPalette>() ?? AkashaPalette.classic;

  return CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.tab): () {
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
        _homeShellHandleEscape(context, controller);
      },
    },
    child: Focus(
      focusNode: shortcutFocusNode,
      autofocus: true,
      child: Theme(
        data: themedData,
        child: Scaffold(
          backgroundColor: palette.background,
          appBar: _homeShellScaffoldAppBar(context, controller),
          body: _homeShellScaffoldBody(context, controller, filtered),
          bottomNavigationBar: _homeShellScaffoldBottomNavigationBar(
            context,
            controller,
            palette,
          ),
        ),
      ),
    ),
  );
}
