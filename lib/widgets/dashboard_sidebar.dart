import 'package:flutter/material.dart';

import '../models/dashboard_config.dart';
import '../models/personal_library_config.dart';
import '../screens/home/home_personal_library_controller.dart';

/// 대시보드 서재 + 나만의 서재 사이드바
class DashboardSidebar extends StatelessWidget {
  static const Color dashboardAccent = Colors.tealAccent;
  static const Color personalAccent = Colors.amberAccent;

  final bool isOpen;
  final SidebarSelectionMode selectionMode;
  final List<DashboardConfig> dashboards;
  final String? activeDashboardId;
  final List<PersonalLibraryConfig> personalLibraries;
  final String? activePersonalLibraryId;
  final VoidCallback onAddDashboard;
  final void Function(String id) onSelectDashboard;
  final void Function(DashboardConfig dash) onEditDashboard;
  final void Function(String id) onDeleteDashboard;
  final VoidCallback onAddPersonalLibrary;
  final void Function(String id) onSelectPersonalLibrary;
  final void Function(PersonalLibraryConfig lib) onEditPersonalLibrary;
  final void Function(String id) onDeletePersonalLibrary;

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.selectionMode,
    required this.dashboards,
    required this.activeDashboardId,
    required this.personalLibraries,
    required this.activePersonalLibraryId,
    required this.onAddDashboard,
    required this.onSelectDashboard,
    required this.onEditDashboard,
    required this.onDeleteDashboard,
    required this.onAddPersonalLibrary,
    required this.onSelectPersonalLibrary,
    required this.onEditPersonalLibrary,
    required this.onDeletePersonalLibrary,
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
                _SectionHeader(
                  icon: Icons.library_books,
                  iconColor: dashboardAccent,
                  title: '대시보드 서재',
                  onAdd: onAddDashboard,
                  addTooltip: '새 대시보드 추가',
                ),
                const Divider(color: Color(0xFF2D2D44), height: 1),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: dashboards.length,
                    itemBuilder: (context, index) {
                      final dash = dashboards[index];
                      final isActive = selectionMode ==
                              SidebarSelectionMode.dashboard &&
                          dash.id == activeDashboardId;
                      return SidebarItemWidget(
                        name: dash.name,
                        icon: dash.categories.isNotEmpty
                            ? dash.categories.first.icon
                            : dash.domain != null
                                ? dash.domain!.icon
                                : Icons.dashboard_outlined,
                        isActive: isActive,
                        accentColor: dashboardAccent,
                        canEdit: dash.id != 'master_index',
                        canDelete: dash.id != 'master_index',
                        onTap: () => onSelectDashboard(dash.id),
                        onEdit: () => onEditDashboard(dash),
                        onDelete: () => onDeleteDashboard(dash.id),
                      );
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2D2D44), height: 1),
                _SectionHeader(
                  icon: Icons.collections_bookmark_outlined,
                  iconColor: personalAccent,
                  title: '나만의 서재',
                  onAdd: onAddPersonalLibrary,
                  addTooltip: '나만의 서재 추가',
                ),
                const Divider(color: Color(0xFF2D2D44), height: 1),
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: personalLibraries.length,
                    itemBuilder: (context, index) {
                      final lib = personalLibraries[index];
                      final isActive = selectionMode ==
                              SidebarSelectionMode.personalLibrary &&
                          lib.id == activePersonalLibraryId;
                      return SidebarItemWidget(
                        name: lib.name,
                        icon: lib.categories.length == 1
                            ? lib.categories.first.icon
                            : Icons.inventory_2_outlined,
                        isActive: isActive,
                        accentColor: personalAccent,
                        canEdit: true,
                        canDelete: !lib.isPreset,
                        editTooltip: '서재 설정',
                        onTap: () => onSelectPersonalLibrary(lib.id),
                        onEdit: () => onEditPersonalLibrary(lib),
                        onDelete: () => onDeletePersonalLibrary(lib.id),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onAdd;
  final String addTooltip;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onAdd,
    required this.addTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
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
            tooltip: addTooltip,
            onPressed: onAdd,
          ),
        ],
      ),
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
  final String name;
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final bool canEdit;
  final bool canDelete;
  final String editTooltip;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SidebarItemWidget({
    super.key,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    this.canEdit = true,
    this.canDelete = true,
    this.editTooltip = '설정',
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
                  color: widget.accentColor.withValues(alpha: 0.35),
                  width: 1.0,
                )
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
                  widget.icon,
                  size: 16,
                  color: isActive ? widget.accentColor : Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.grey[300],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isHovered || isActive) ...[
                  if (widget.canEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 14, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: widget.editTooltip,
                      onPressed: widget.onEdit,
                    ),
                    if (widget.canDelete) const SizedBox(width: 6),
                  ],
                  if (widget.canDelete)
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
