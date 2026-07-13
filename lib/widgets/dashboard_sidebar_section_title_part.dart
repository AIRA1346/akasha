part of 'dashboard_sidebar.dart';

class _DashboardSidebarSectionTitle extends StatelessWidget {
  const _DashboardSidebarSectionTitle(
    this.title, {
    this.trailingLabel,
    this.onTrailing,
    this.onAdd,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailing;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: AkashaTypography.sidebarSectionTitle.copyWith(
              color: palette.textMuted,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 16, color: palette.textMuted),
              ),
            ),
          if (trailingLabel != null && onTrailing != null)
            InkWell(
              onTap: onTrailing,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  trailingLabel!,
                  style: AkashaTypography.sidebarTrailingLink.copyWith(
                    color: palette.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
