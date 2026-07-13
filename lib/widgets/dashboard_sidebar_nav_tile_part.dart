part of 'dashboard_sidebar.dart';

class _SidebarNavTile extends StatefulWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final palette = context.akashaPalette;
    final bg = selected
        ? palette.accentSoft
        : _hovered
        ? palette.hoverSurface.withValues(alpha: 0.62)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (selected)
                    Container(
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 13),
                  Icon(
                    widget.icon,
                    size: 18,
                    color: selected ? palette.accent : palette.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style:
                          (selected
                                  ? AkashaTypography.sidebarNavLabelSelected
                                  : AkashaTypography.sidebarNavLabel)
                              .copyWith(
                                color: selected
                                    ? palette.accent
                                    : palette.textSecondary,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
