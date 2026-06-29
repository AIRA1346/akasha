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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AkashaColors.textCaption,
              letterSpacing: 0.3,
            ),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: AkashaColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
