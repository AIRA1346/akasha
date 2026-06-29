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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your Knowledge Universe',
            style: TextStyle(
              fontSize: 10,
              color: AkashaColors.textCaption,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
