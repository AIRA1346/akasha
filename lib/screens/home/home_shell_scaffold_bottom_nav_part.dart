part of 'home_shell_scaffold.dart';

Widget _homeShellScaffoldBottomNavigationBar(
  BuildContext context,
  HomeShellController controller,
) {
  final isHome = controller.isHomeDashboardMode;
  final isExplore = controller.isExploreModeActive;
  final l10n = lookupAppL10n(context);
  final palette = context.akashaPalette;

  return DecoratedBox(
    decoration: BoxDecoration(
      color: palette.bottomBar,
      border: Border(top: BorderSide(color: palette.borderSubtle(0.52))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: _homeShellScaffoldBottomTabItem(
                icon: Icons.home_filled,
                label: l10n?.navHome ?? '홈',
                isSelected: isHome,
                onTap: () => controller.goHome(),
              ),
            ),
            Expanded(
              child: _homeShellScaffoldBottomTabItem(
                icon: Icons.explore_outlined,
                label: l10n?.navExplore ?? '탐색',
                isSelected: isExplore,
                onTap: () => controller.goExplore(),
              ),
            ),
            Expanded(
              child: _homeShellScaffoldBottomTabItem(
                icon: Icons.search,
                label: l10n?.navSearch ?? '검색',
                isSelected: false,
                emphasize: true,
                onTap: controller.openSearchDialog,
              ),
            ),
            Expanded(
              child: _homeShellScaffoldBottomTabItem(
                icon: Icons.book_outlined,
                label: l10n?.navLibrary ?? '라이브러리',
                isSelected: controller.isPersonalLibraryMode,
                onTap: () {
                  if (controller.personalLibCtrl.libraries.isNotEmpty) {
                    controller.selectPersonalLibrary(
                      controller.personalLibCtrl.libraries.first.id,
                    );
                  } else {
                    controller.libraryUi.promptCreateCuratedLibrary(
                      controller.host.context,
                      setState: controller.wrapSetState,
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: _homeShellScaffoldBottomTabItem(
                icon: Icons.folder_open_outlined,
                label: l10n?.navCollections ?? '컬렉션',
                isSelected: controller.isCollectibleCollectionMode,
                onTap: () {
                  if (controller.collectionCtrl.collections.isNotEmpty) {
                    controller.selectCollectibleCollection(
                      controller.collectionCtrl.collections.first.id,
                    );
                  } else {
                    controller.collectionUi.promptCreate(
                      controller.host.context,
                      personalLibCtrl: controller.personalLibCtrl,
                      setState: controller.wrapSetState,
                      vaultItems: controller.items,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _homeShellScaffoldBottomTabItem({
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
  bool emphasize = false,
}) {
  return Builder(
    builder: (context) {
      final palette = context.akashaPalette;
      final color = isSelected || emphasize
          ? palette.accent
          : AkashaColors.textMuted;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
