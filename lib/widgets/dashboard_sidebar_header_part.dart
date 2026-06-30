part of 'dashboard_sidebar.dart';

class _DashboardSidebarLogoHeader extends StatelessWidget {
  const _DashboardSidebarLogoHeader();

  static const _brandMarkAsset = 'assets/branding/akasha_mark.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            _brandMarkAsset,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            semanticLabel: 'AKASHA',
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AKASHA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AkashaTypography.sidebarBrand,
                ),
                SizedBox(height: 4),
                Text(
                  'Your Knowledge Universe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AkashaTypography.sidebarTagline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
