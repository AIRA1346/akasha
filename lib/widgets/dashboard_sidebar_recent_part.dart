part of 'dashboard_sidebar.dart';

class _DashboardSidebarRecentSection extends StatelessWidget {
  const _DashboardSidebarRecentSection({
    required this.recentExploreItems,
    required this.activeDetailWorkId,
    required this.activeDetailEntityId,
    required this.onOpenRecentExplore,
  });

  final List<AkashaItem> recentExploreItems;
  final String? activeDetailWorkId;
  final String? activeDetailEntityId;
  final void Function(AkashaItem item)? onOpenRecentExplore;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSidebarSectionTitle(l10n?.sidebarRecentExplore ?? '최근 탐색'),
        const SizedBox(height: 6),
        ...recentExploreItems.take(5).map((item) => _buildRecentRow(item, l10n)),
      ],
    );
  }

  Widget _buildRecentRow(AkashaItem item, AppLocalizations? l10n) {
    final subtitle = switch (item) {
      EntityItem(:final entityType) => entityTypeDisplayLabel(entityType),
      _ => l10n?.itemKindWork ?? '작품',
    };
    final isActive = switch (item) {
      EntityItem(:final entityId) =>
        activeDetailEntityId != null && entityId == activeDetailEntityId,
      _ => activeDetailWorkId != null &&
          item.workId.isNotEmpty &&
          item.workId == activeDetailWorkId,
    };
    return _SidebarThumbnailTile(
      item: item,
      title: item.title,
      subtitle: subtitle,
      isActive: isActive,
      onTap: onOpenRecentExplore == null
          ? () {}
          : () => onOpenRecentExplore!(item),
    );
  }
}
