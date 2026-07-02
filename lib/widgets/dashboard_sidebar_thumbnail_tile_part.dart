part of 'dashboard_sidebar.dart';

class _SidebarThumbnailTile extends StatefulWidget {
  const _SidebarThumbnailTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.item,
    this.isActive = false,
    this.fallbackIcon = Icons.image_outlined,
    this.trailing,
  });

  final AkashaItem? item;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isActive;
  final IconData fallbackIcon;
  final Widget? trailing;

  @override
  State<_SidebarThumbnailTile> createState() => _SidebarThumbnailTileState();
}

class _SidebarThumbnailTileState extends State<_SidebarThumbnailTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isActive || _hovered;
    final palette = context.akashaPalette;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: highlight
                    ? palette.menuSelected.withValues(alpha: 0.74)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: widget.isActive
                    ? Border.all(color: palette.accent.withValues(alpha: 0.18))
                    : null,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: widget.item != null
                          ? PosterImage(
                              item: widget.item!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            )
                          : ColoredBox(
                              color: palette.thumbPlaceholder,
                              child: Icon(
                                widget.fallbackIcon,
                                size: 16,
                                color: AkashaColors.textCaption,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: widget.isActive
                              ? AkashaTypography.sidebarThumbTitleActive
                              : AkashaTypography.sidebarThumbTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AkashaTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 4),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
