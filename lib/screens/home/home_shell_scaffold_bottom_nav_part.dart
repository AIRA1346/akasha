part of 'home_shell_scaffold.dart';

Widget _homeShellScaffoldBottomNavigationBar(
  BuildContext context,
  HomeShellController controller,
  AkashaPalette palette,
  ShellLayoutSpec layoutSpec,
) {
  final l10n = lookupAppL10n(context);
  final destinations = AppDestinationRegistry.bindings(
    currentDestination: controller.currentDestination,
    onSelected: (destination) {
      unawaited(controller.selectDestination(destination));
    },
  );
  final buildIdentity = BuildIdentityScope.of(context);

  return DecoratedBox(
    key: const ValueKey('home-shell-dock'),
    decoration: BoxDecoration(
      color: palette.bottomBar,
      border: Border(top: BorderSide(color: palette.borderSubtle(0.52))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: layoutSpec.dockHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identityPresentation = resolveBuildIdentityDockPresentation(
              layoutClass: layoutSpec.layoutClass,
              viewportWidth: constraints.maxWidth,
              hasAppVersion: buildIdentity.hasAppVersion,
            );
            final showCondensedIdentity =
                identityPresentation == BuildIdentityDockPresentation.condensed;
            return Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (final destination in destinations)
                        Expanded(
                          child: _homeShellScaffoldBottomTabItem(
                            key: ValueKey(
                              'destination-${destination.definition.stableId}-dock',
                            ),
                            icon: destination.definition.icon,
                            label: destination.definition.resolveLabel(l10n),
                            isSelected: destination.isSelected,
                            onTap: destination.action,
                          ),
                        ),
                    ],
                  ),
                ),
                if (identityPresentation !=
                    BuildIdentityDockPresentation.hidden)
                  SizedBox(
                    width: showCondensedIdentity ? 112 : 276,
                    child: BuildIdentityDockLabel(
                      identity: buildIdentity,
                      condensed: showCondensedIdentity,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

Widget _homeShellScaffoldBottomTabItem({
  required Key key,
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback? onTap,
}) {
  return Builder(
    key: key,
    builder: (context) {
      final palette = context.akashaPalette;
      final color = isSelected ? palette.accent : palette.textMuted;
      return Semantics(
        selected: isSelected,
        button: true,
        enabled: onTap != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 21),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
