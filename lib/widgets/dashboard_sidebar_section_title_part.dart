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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: AkashaTypography.sidebarSectionTitle,
          ),
          const Spacer(),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: AkashaColors.textCaption,
                ),
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
                  style: AkashaTypography.sidebarTrailingLink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
