part of 'dashboard_sidebar.dart';

class _DashboardSidebarCollapseFooter extends StatelessWidget {
  const _DashboardSidebarCollapseFooter({required this.onToggleSidebar});

  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return InkWell(
      onTap: onToggleSidebar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: palette.sidebarFooter,
          border: Border(top: BorderSide(color: palette.borderSubtle(0.45))),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: palette.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              '접기',
              style: AkashaTypography.sidebarFooterLabel.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
