part of 'home_shell_scaffold.dart';

List<BrowseCard> _homeShellScaffoldFilteredCards(HomeShellController controller) {
  final scope = controller.filterCtrl.entityScope;
  return controller.isPersonalLibraryMode
      ? (scope.showsWorkGrid
          ? controller.personalBrowseCards
          : const <BrowseCard>[])
      : controller.filteredBrowseCards;
}

Widget _homeShellScaffoldRoot(
  BuildContext context,
  HomeShellController controller,
) {
  final filtered = _homeShellScaffoldFilteredCards(controller);

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
    },
    child: Focus(
      autofocus: true,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: controller.libraryTheme.backgroundColor,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: controller.libraryTheme.accentColor,
                secondary: controller.libraryTheme.accentColor,
              ),
        ),
        child: Scaffold(
          backgroundColor: controller.libraryTheme.backgroundColor,
          appBar: _homeShellScaffoldAppBar(context, controller),
          body: _homeShellScaffoldBody(context, controller, filtered),
          bottomNavigationBar: _homeShellScaffoldBottomNavigationBar(context, controller),
        ),
      ),
    ),
  );
}
