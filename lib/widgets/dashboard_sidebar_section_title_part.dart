part of 'dashboard_sidebar.dart';

class _DashboardSidebarSectionTitle extends StatelessWidget {
  const _DashboardSidebarSectionTitle(
    this.title, {
    this.trailingLabel,
    this.onTrailing,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

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
