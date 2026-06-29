part of 'dashboard_sidebar.dart';

class _DashboardSidebarCollapseFooter extends StatelessWidget {
  const _DashboardSidebarCollapseFooter({required this.onToggleSidebar});

  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleSidebar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AkashaColors.sidebarFooter,
          border: Border(top: BorderSide(color: AkashaColors.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded, size: 18, color: AkashaColors.textMuted),
            const SizedBox(width: 6),
            Text(
              '접기',
              style: AkashaTypography.sidebarFooterLabel,
            ),
          ],
        ),
      ),
    );
  }
}
