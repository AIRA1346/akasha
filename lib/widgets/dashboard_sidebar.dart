import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../models/akasha_item.dart';
import '../models/collectible_collection.dart';
import '../models/collectible_kind.dart';
import '../models/collectible_ref.dart';
import '../screens/home/home_personal_library_controller.dart';
import '../screens/home/views/preview_record_view_model.dart';
import '../theme/akasha_colors.dart';
import 'poster_image.dart';

/// 홈 좌측 네비게이션 사이드바 (시안: primary nav · 최근 탐색 · 내 컬렉션).
class DashboardSidebar extends StatelessWidget {
  static const Color dashboardAccent = AkashaColors.accent;
  static const Color personalAccent = Colors.amberAccent;
  static const Color collectionAccent = AkashaColors.accentDark;

  static const double _sidebarWidth = 280;

  final bool isOpen;
  final bool isHomeMode;
  final bool isExploreMode;
  final bool isPersonalLibraryMode;
  final bool isCollectibleCollectionMode;
  final bool isKnowledgeGraphMode;
  final bool isTimelineMode;
  final SidebarSelectionMode selectionMode;
  final List<AkashaItem> recentExploreItems;
  final List<AkashaItem> vaultItems;
  final List<CollectibleCollection> collectibleCollections;
  final String? activeCollectibleCollectionId;
  final Future<void> Function() onGoHome;
  final Future<void> Function() onGoExplore;
  final Future<void> Function() onGoLibrary;
  final Future<void> Function() onGoCollection;
  final Future<void> Function() onGoKnowledgeGraph;
  final VoidCallback onSelectTimeline;
  final void Function(AkashaItem item)? onOpenRecentExplore;
  final String? activeDetailWorkId;
  final String? activeDetailEntityId;
  final void Function(String id) onSelectCollectibleCollection;
  final VoidCallback? onToggleSidebar;

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.isHomeMode,
    required this.isExploreMode,
    required this.isPersonalLibraryMode,
    required this.isCollectibleCollectionMode,
    this.isKnowledgeGraphMode = false,
    required this.isTimelineMode,
    required this.selectionMode,
    this.recentExploreItems = const [],
    this.vaultItems = const [],
    this.collectibleCollections = const [],
    this.activeCollectibleCollectionId,
    required this.onGoHome,
    required this.onGoExplore,
    required this.onGoLibrary,
    required this.onGoCollection,
    required this.onGoKnowledgeGraph,
    required this.onSelectTimeline,
    this.onOpenRecentExplore,
    this.activeDetailWorkId,
    this.activeDetailEntityId,
    required this.onSelectCollectibleCollection,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isOpen ? _sidebarWidth : 0.0,
      decoration: const BoxDecoration(
        color: AkashaColors.sidebar,
        border: Border(
          right: BorderSide(color: AkashaColors.border, width: 1),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: isOpen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrimaryNav(),
                        if (recentExploreItems.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildRecentExplores(),
                        ],
                        const SizedBox(height: 20),
                        _buildMyCollections(),
                      ],
                    ),
                  ),
                ),
                if (onToggleSidebar != null) _buildCollapseFooter(),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLogoHeader() {
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

  Widget _buildPrimaryNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _SidebarNavTile(
            icon: Icons.home_outlined,
            label: '홈',
            isSelected: isHomeMode,
            onTap: () => onGoHome(),
          ),
          _SidebarNavTile(
            icon: Icons.explore_outlined,
            label: '탐색',
            isSelected: isExploreMode,
            onTap: () => onGoExplore(),
          ),
          _SidebarNavTile(
            icon: Icons.menu_book_outlined,
            label: '라이브러리',
            isSelected: isPersonalLibraryMode,
            onTap: () => onGoLibrary(),
          ),
          _SidebarNavTile(
            icon: Icons.collections_bookmark_outlined,
            label: '컬렉션',
            isSelected: isCollectibleCollectionMode,
            onTap: () => onGoCollection(),
          ),
          if (FeatureFlags.showKnowledgeGraph)
            _SidebarNavTile(
              icon: Icons.hub_outlined,
              label: '그래프',
              isSelected: isKnowledgeGraphMode,
              onTap: () => onGoKnowledgeGraph(),
            ),
          _SidebarNavTile(
            icon: Icons.access_time_outlined,
            label: '타임라인',
            isSelected: isTimelineMode,
            onTap: onSelectTimeline,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? trailingLabel,
    VoidCallback? onTrailing,
  }) {
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
                  trailingLabel,
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

  Widget _buildRecentExplores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('최근 탐색'),
        const SizedBox(height: 6),
        ...recentExploreItems.take(5).map(_buildRecentRow),
      ],
    );
  }

  Widget _buildRecentRow(AkashaItem item) {
    final subtitle = switch (item) {
      EntityItem(:final entityType) => entityTypeDisplayLabel(entityType),
      _ => '작품',
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

  Widget _buildMyCollections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          '내 컬렉션',
          trailingLabel: collectibleCollections.isNotEmpty ? '모두 보기' : null,
          onTrailing:
              collectibleCollections.isNotEmpty ? () => onGoCollection() : null,
        ),
        const SizedBox(height: 6),
        if (collectibleCollections.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '컬렉션이 없습니다',
              style: TextStyle(fontSize: 11, color: AkashaColors.textCaption),
            ),
          )
        else
          ...collectibleCollections.take(4).map(_buildCollectionRow),
      ],
    );
  }

  Widget _buildCollectionRow(CollectibleCollection col) {
    final isActive =
        selectionMode == SidebarSelectionMode.collectibleCollection &&
            activeCollectibleCollectionId == col.id;
    final count = col.isCurated ? col.memberOrder.length : 0;
    final subtitle = count > 0 ? '$count 작품' : '컬렉션';
    final coverItem = _coverItemForCollection(col);

    return _SidebarThumbnailTile(
      item: coverItem,
      title: col.title,
      subtitle: subtitle,
      isActive: isActive,
      fallbackIcon: Icons.favorite_outline,
      onTap: () => onSelectCollectibleCollection(col.id),
    );
  }

  AkashaItem? _coverItemForCollection(CollectibleCollection col) {
    if (!col.isCurated || col.memberOrder.isEmpty) return null;
    final byWorkId = <String, AkashaItem>{
      for (final item in vaultItems)
        if (item.workId.isNotEmpty) item.workId: item,
    };
    for (final CollectibleRef ref in col.memberOrder) {
      if (ref.kind == CollectibleKind.work) {
        final item = byWorkId[ref.id];
        if (item != null) return item;
      }
    }
    return null;
  }

  Widget _buildCollapseFooter() {
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
            Icon(Icons.chevron_left_rounded, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              '접기',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatefulWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final bg = selected
        ? AkashaColors.accent.withValues(alpha: 0.14)
        : _hovered
            ? AkashaColors.surface.withValues(alpha: 0.6)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (selected)
                    Container(
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AkashaColors.accent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AkashaColors.accent.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 13),
                  Icon(
                    widget.icon,
                    size: 18,
                    color: selected ? AkashaColors.accent : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarThumbnailTile extends StatefulWidget {
  const _SidebarThumbnailTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.item,
    this.isActive = false,
    this.fallbackIcon = Icons.image_outlined,
  });

  final AkashaItem? item;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isActive;
  final IconData fallbackIcon;

  @override
  State<_SidebarThumbnailTile> createState() => _SidebarThumbnailTileState();
}

class _SidebarThumbnailTileState extends State<_SidebarThumbnailTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isActive || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: highlight
                    ? AkashaColors.menuSelected.withValues(alpha: 0.7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: widget.item != null
                          ? PosterImage(
                              item: widget.item!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            )
                          : ColoredBox(
                              color: AkashaColors.thumbPlaceholder,
                              child: Icon(
                                widget.fallbackIcon,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AkashaColors.textCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
