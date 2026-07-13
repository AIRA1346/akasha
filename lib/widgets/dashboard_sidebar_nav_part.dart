part of 'dashboard_sidebar.dart';

class _DashboardSidebarPrimaryNav extends StatelessWidget {
  const _DashboardSidebarPrimaryNav({
    required this.selectedDestination,
    required this.onSelectDestination,
  });

  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onSelectDestination;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final destinations = AppDestinationRegistry.bindings(
      currentDestination: selectedDestination,
      onSelected: onSelectDestination,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (final destination in destinations)
            _SidebarNavTile(
              key: ValueKey(
                'destination-${destination.definition.stableId}-sidebar',
              ),
              icon: destination.definition.icon,
              label: destination.definition.resolveLabel(l10n),
              isSelected: destination.isSelected,
              onTap: destination.action,
            ),
        ],
      ),
    );
  }
}
