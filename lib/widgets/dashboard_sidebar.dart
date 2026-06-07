import 'package:flutter/material.dart';
import '../models/dashboard_config.dart';

/// 대시보드 서재 사이드바
class DashboardSidebar extends StatelessWidget {
  final bool isOpen;
  final List<DashboardConfig> dashboards;
  final String? activeDashboardId;
  final VoidCallback onAddDashboard;
  final void Function(String id) onSelectDashboard;
  final void Function(DashboardConfig dash) onEditDashboard;
  final void Function(String id) onDeleteDashboard;

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.dashboards,
    required this.activeDashboardId,
    required this.onAddDashboard,
    required this.onSelectDashboard,
    required this.onEditDashboard,
    required this.onDeleteDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isOpen ? 260.0 : 0.0,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2F),
        border: Border(
          right: BorderSide(color: Color(0xFF2D2D44), width: 1.5),
        ),
      ),
      child: isOpen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.library_books,
                              color: Colors.tealAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '대시보드 서재',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined,
                            size: 20, color: Colors.grey),
                        tooltip: '새 대시보드 추가',
                        onPressed: onAddDashboard,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2D2D44), height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: dashboards.length,
                    itemBuilder: (context, index) {
                      final dash = dashboards[index];
                      final isActive = dash.id == activeDashboardId;
                      return SidebarItemWidget(
                        dash: dash,
                        isActive: isActive,
                        onTap: () => onSelectDashboard(dash.id),
                        onEdit: () => onEditDashboard(dash),
                        onDelete: () => onDeleteDashboard(dash.id),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A26),
                    border:
                        Border(top: BorderSide(color: Color(0xFF2D2D44))),
                  ),
                  child: const Row(
                    children: [
                      _TabKeyHint(),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '키를 눌러 사이드바 토글',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _TabKeyHint extends StatelessWidget {
  const _TabKeyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: const Text(
        'Tab',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SidebarItemWidget extends StatefulWidget {
  final DashboardConfig dash;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SidebarItemWidget({
    super.key,
    required this.dash,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<SidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2A2A3E)
              : _isHovered
                  ? const Color(0xFF222235)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(
                  color: Colors.tealAccent.withValues(alpha: 0.3), width: 1.0)
              : Border.all(color: Colors.transparent, width: 1.0),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  widget.dash.categories.isNotEmpty
                      ? widget.dash.categories.first.icon
                      : widget.dash.domain != null
                          ? widget.dash.domain!.icon
                          : Icons.dashboard_outlined,
                  size: 16,
                  color: isActive ? Colors.tealAccent : Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.dash.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.grey[300],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.dash.id != 'master_index' &&
                    (_isHovered || isActive)) ...[
                  IconButton(
                    icon: const Icon(Icons.settings,
                        size: 14, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onEdit,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 14, color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
