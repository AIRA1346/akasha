part of 'dashboard_sidebar.dart';

class _DashboardSidebarPrimaryNav extends StatelessWidget {
  const _DashboardSidebarPrimaryNav({
    required this.isHomeMode,
    required this.isExploreMode,
    required this.isPersonalLibraryMode,
    required this.isCollectibleCollectionMode,
    required this.isKnowledgeGraphMode,
    required this.isTimelineMode,
    required this.onGoHome,
    required this.onGoExplore,
    required this.onGoLibrary,
    required this.onGoCollection,
    required this.onGoKnowledgeGraph,
    required this.onSelectTimeline,
  });

  final bool isHomeMode;
  final bool isExploreMode;
  final bool isPersonalLibraryMode;
  final bool isCollectibleCollectionMode;
  final bool isKnowledgeGraphMode;
  final bool isTimelineMode;
  final Future<void> Function() onGoHome;
  final Future<void> Function() onGoExplore;
  final Future<void> Function() onGoLibrary;
  final Future<void> Function() onGoCollection;
  final Future<void> Function() onGoKnowledgeGraph;
  final VoidCallback onSelectTimeline;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _SidebarNavTile(
            icon: Icons.home_outlined,
            label: l10n?.sidebarHome ?? '홈',
            isSelected: isHomeMode,
            onTap: () => onGoHome(),
          ),
          _SidebarNavTile(
            icon: Icons.explore_outlined,
            label: l10n?.sidebarExplore ?? '탐색',
            isSelected: isExploreMode,
            onTap: () => onGoExplore(),
          ),
          _SidebarNavTile(
            icon: Icons.menu_book_outlined,
            label: l10n?.sidebarLibrary ?? '라이브러리',
            isSelected: isPersonalLibraryMode,
            onTap: () => onGoLibrary(),
          ),
          _SidebarNavTile(
            icon: Icons.collections_bookmark_outlined,
            label: l10n?.sidebarCollections ?? '컬렉션',
            isSelected: isCollectibleCollectionMode,
            onTap: () => onGoCollection(),
          ),
          if (FeatureFlags.showKnowledgeGraph)
            _SidebarNavTile(
              icon: Icons.hub_outlined,
              label: l10n?.sidebarGraph ?? '그래프',
              isSelected: isKnowledgeGraphMode,
              onTap: () => onGoKnowledgeGraph(),
            ),
          if (FeatureFlags.showTimeline)
            _SidebarNavTile(
              icon: Icons.access_time_outlined,
              label: l10n?.sidebarTimeline ?? '타임라인',
              isSelected: isTimelineMode,
              onTap: onSelectTimeline,
            ),
        ],
      ),
    );
  }
}
