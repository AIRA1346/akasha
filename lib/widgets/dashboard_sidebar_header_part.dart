part of 'dashboard_sidebar.dart';

class _DashboardSidebarLogoHeader extends StatelessWidget {
  const _DashboardSidebarLogoHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AKASHA',
            style: AkashaTypography.sidebarBrand,
          ),
          SizedBox(height: 4),
          Text(
            'Your Knowledge Universe',
            style: AkashaTypography.sidebarTagline,
          ),
        ],
      ),
    );
  }
}
