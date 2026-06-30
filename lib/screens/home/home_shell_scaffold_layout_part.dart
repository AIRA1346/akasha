part of 'home_shell_scaffold.dart';

bool _homeShellShowsBrowseSearchChrome(HomeShellController controller) {
  return !controller.isTimelineMode &&
      !controller.isCollectibleCollectionMode &&
      !controller.workbench.hasOpenDetail;
}

Widget _homeShellScaffoldBodyWithSearch(
  BuildContext context,
  HomeShellController controller,
  List<BrowseCard> filtered,
) {
  final showChrome = _homeShellShowsBrowseSearchChrome(controller);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showChrome)
        HomeBrowseSearchChrome(
          onSearch: controller.openSearchDialog,
          selectedCategories: controller.filterCtrl.categories,
          selectedWorkStatuses: controller.filterCtrl.workStatuses,
          selectedMyStatuses: controller.filterCtrl.myStatuses,
          onToggleCategory: controller.toggleCategory,
          onClearCategories: controller.clearCategories,
          onToggleWorkStatus: controller.toggleWorkStatus,
          onToggleMyStatus: controller.toggleMyStatus,
          selectedEntityScope: controller.filterCtrl.entityScope,
          onEntityScopeChanged: controller.onEntityScopeChanged,
          onAddNewEntity: controller.openAddEntityDialog,
        ),
      Expanded(
        child: _homeShellScaffoldBody(context, controller, filtered),
      ),
    ],
  );
}

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
        data: controller.isPersonalLibraryMode
            ? Theme.of(context).copyWith(
                scaffoldBackgroundColor: controller.libraryTheme.backgroundColor,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      secondary: controller.libraryTheme.accentColor,
                    ),
              )
            : Theme.of(context),
        child: Scaffold(
          backgroundColor: controller.isPersonalLibraryMode
              ? controller.libraryTheme.backgroundColor
              : null,
          appBar: _homeShellScaffoldAppBar(context, controller),
          body: _homeShellScaffoldBodyWithSearch(context, controller, filtered),
          bottomNavigationBar: _homeShellScaffoldBottomNavigationBar(context, controller),
        ),
      ),
    ),
  );
}
