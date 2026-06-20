import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../features/workbench/presentation/collectible_tab.dart';
import '../../../widgets/poster_image.dart';

/// 열린 Collectible 탭 레일 (Work + Entity).
class CollectibleTabRail extends StatelessWidget {
  const CollectibleTabRail({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onSelect,
    required this.onClose,
  });

  final List<CollectibleTab> tabs;
  final String? activeTabId;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String id) onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF181824),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleCollapsed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                      size: 18,
                      color: Colors.grey[500],
                    ),
                    if (!collapsed)
                      Text(
                        '탭',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2D2D44)),
          if (tabs.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  collapsed ? '·' : '항목 없음',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: tabs.length,
                itemBuilder: (_, i) {
                  final tab = tabs[i];
                  final active = tab.id == activeTabId;
                  return _TabTile(
                    tab: tab,
                    active: active,
                    compact: collapsed,
                    onTap: () => onSelect(tab.id),
                    onClose: () => onClose(tab.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TabTile extends StatelessWidget {
  const _TabTile({
    required this.tab,
    required this.active,
    required this.compact,
    required this.onTap,
    required this.onClose,
  });

  final CollectibleTab tab;
  final bool active;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: tab.title,
        child: Material(
          color: active ? const Color(0xFF2A2A40) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _TabThumbnail(tab: tab, size: 36, height: 48),
                  if (tab.isDirty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: active ? const Color(0xFF2A2A40) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            children: [
              _TabThumbnail(tab: tab, size: 32, height: 44),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? Colors.white : Colors.grey[400],
                        height: 1.2,
                      ),
                    ),
                    if (tab.isDirty)
                      Text(
                        '● 미저장',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.amber[700],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabThumbnail extends StatelessWidget {
  const _TabThumbnail({
    required this.tab,
    required this.size,
    required this.height,
  });

  final CollectibleTab tab;
  final double size;
  final double height;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      WorkCollectibleTab(:final item) => SizedBox(
          width: size,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: PosterImage(item: item, fit: BoxFit.cover),
          ),
        ),
      EntityCollectibleTab(:final entity) => SizedBox(
          width: size,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF252535),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.35)),
            ),
            child: Icon(
              _iconFor(entity.anchorType),
              size: size * 0.55,
              color: Colors.tealAccent,
            ),
          ),
        ),
    };
  }

  IconData _iconFor(EntityAnchorType type) => switch (type) {
        EntityAnchorType.person => Icons.person_outline,
        EntityAnchorType.concept => Icons.lightbulb_outline,
        EntityAnchorType.event => Icons.event_outlined,
        EntityAnchorType.place => Icons.place_outlined,
        EntityAnchorType.organization => Icons.groups_outlined,
        _ => Icons.category_outlined,
      };
}
