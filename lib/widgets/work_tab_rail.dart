import 'package:flutter/material.dart';

import '../features/workbench/presentation/work_tab.dart';
import '../widgets/poster_image.dart';

/// 열린 작품 탭 레일 (2열)
class WorkTabRail extends StatelessWidget {
  final List<WorkTab> tabs;
  final String? activeTabId;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String id) onClose;

  const WorkTabRail({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onSelect,
    required this.onClose,
  });

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
                child: RotatedBox(
                  quarterTurns: collapsed ? 0 : 0,
                  child: Text(
                    collapsed ? '·' : '작품 없음',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
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
  final WorkTab tab;
  final bool active;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabTile({
    required this.tab,
    required this.active,
    required this.compact,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final item = tab.item;
    if (compact) {
      return Tooltip(
        message: item.title,
        child: Material(
          color: active ? const Color(0xFF2A2A40) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SizedBox(
                    width: 36,
                    height: 48,
                    child: PosterImage(
                      item: item,
                      fit: BoxFit.cover,
                    ),
                  ),
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
              SizedBox(
                width: 32,
                height: 44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: PosterImage(item: item, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
