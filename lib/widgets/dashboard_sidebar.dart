import 'package:flutter/material.dart';

import '../models/collectible_collection.dart';
import '../models/dashboard_config.dart';
import '../models/personal_library_config.dart';
import '../models/work_drag_payload.dart';
import '../screens/home/home_personal_library_controller.dart';
import 'personal_library_drop_target.dart';

/// 나만의 서재 + 컬렉션 + 대시보드 서재 사이드바.
class DashboardSidebar extends StatelessWidget {
  static const Color dashboardAccent = Colors.tealAccent;
  static const Color personalAccent = Colors.amberAccent;
  static const Color collectionAccent = Colors.deepPurpleAccent;

  final bool isOpen;
  final SidebarSelectionMode selectionMode;
  final List<DashboardConfig> dashboards;
  final String? activeDashboardId;
  final List<PersonalLibraryConfig> personalLibraries;
  final String? activePersonalLibraryId;
  final List<CollectibleCollection> collectibleCollections;
  final String? activeCollectibleCollectionId;
  final VoidCallback onAddDashboard;
  final void Function(String id) onSelectDashboard;
  final void Function(DashboardConfig dash) onEditDashboard;
  final void Function(String id) onDeleteDashboard;
  final VoidCallback onAddPersonalLibrary;
  final VoidCallback onAddCollectibleCollection;
  final VoidCallback onSelectTimeline;
  final void Function(String id) onSelectPersonalLibrary;
  final void Function(PersonalLibraryConfig lib) onEditPersonalLibrary;
  final void Function(String id) onDeletePersonalLibrary;
  final void Function(String id) onSelectCollectibleCollection;
  final void Function(CollectibleCollection col) onEditCollectibleCollection;
  final void Function(String id) onDeleteCollectibleCollection;
  final void Function(String libraryId, WorkDragPayload payload)? onDropWorkToLibrary;
  final VoidCallback? onLibraryDragStarted;
  final VoidCallback? onToggleSidebar;

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.selectionMode,
    required this.dashboards,
    required this.activeDashboardId,
    required this.personalLibraries,
    required this.activePersonalLibraryId,
    this.collectibleCollections = const [],
    this.activeCollectibleCollectionId,
    required this.onAddDashboard,
    required this.onSelectDashboard,
    required this.onEditDashboard,
    required this.onDeleteDashboard,
    required this.onAddPersonalLibrary,
    required this.onAddCollectibleCollection,
    required this.onSelectTimeline,
    required this.onSelectPersonalLibrary,
    required this.onEditPersonalLibrary,
    required this.onDeletePersonalLibrary,
    required this.onSelectCollectibleCollection,
    required this.onEditCollectibleCollection,
    required this.onDeleteCollectibleCollection,
    this.onDropWorkToLibrary,
    this.onLibraryDragStarted,
    this.onToggleSidebar,
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
                // 1. 로고 영역
                _buildLogoHeader(),
                const SizedBox(height: 8),

                // 2. 스크롤 가능한 본문 영역
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainMenu(context),
                        const SizedBox(height: 16),
                        _buildRecentExplore(),
                        const SizedBox(height: 16),
                        _buildMyCollections(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 3. AKASHA Pro 배너
                _buildProBanner(),

                // 4. 하단 사이드바 접기 단추
                if (onToggleSidebar != null)
                  InkWell(
                    onTap: onToggleSidebar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF161622),
                        border: Border(top: BorderSide(color: Color(0xFF2D2D44))),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '접기',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // 폴백
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF161622),
                      border: Border(top: BorderSide(color: Color(0xFF2D2D44))),
                    ),
                    child: Row(
                      children: [
                        const _TabKeyHint(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '키를 눌러 사이드바 토글',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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

  Widget _buildLogoHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.blur_on_rounded,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AKASHA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Your Knowledge Universe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    final isHome = selectionMode == SidebarSelectionMode.dashboard &&
        activeDashboardId == 'master_index';

    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.home_filled,
          label: '홈',
          isSelected: isHome,
          onTap: () => onSelectDashboard('master_index'),
        ),
        _buildMenuTile(
          icon: Icons.explore_outlined,
          label: '탐색',
          isSelected: false,
          onTap: () {
            // 탐색 관련 이벤트 호출
          },
        ),
        _buildMenuTile(
          icon: Icons.book_outlined,
          label: '라이브러리',
          isSelected: selectionMode == SidebarSelectionMode.personalLibrary,
          onTap: () {
            if (personalLibraries.isNotEmpty) {
              onSelectPersonalLibrary(personalLibraries.first.id);
            }
          },
        ),
        _buildMenuTile(
          icon: Icons.folder_open_outlined,
          label: '컬렉션',
          isSelected: selectionMode == SidebarSelectionMode.collectibleCollection,
          onTap: () {
            if (collectibleCollections.isNotEmpty) {
              onSelectCollectibleCollection(collectibleCollections.first.id);
            }
          },
        ),
        _buildMenuTile(
          icon: Icons.hub_outlined,
          label: '그래프',
          isSelected: false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('지식 그래프 모드는 준비 중입니다.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildMenuTile(
          icon: Icons.access_time_outlined,
          label: '타임라인',
          isSelected: selectionMode == SidebarSelectionMode.timeline,
          onTap: onSelectTimeline,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2A2A3E) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                width: 1.0,
              )
            : Border.all(color: Colors.transparent, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExplore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '최근 탐색',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '최근 탐색 기록이 없습니다.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCollections() {
    if (collectibleCollections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '내 컬렉션',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '모두 보기',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...collectibleCollections.take(5).map((col) {
            final isActive = selectionMode == SidebarSelectionMode.collectibleCollection &&
                activeCollectibleCollectionId == col.id;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => onSelectCollectibleCollection(col.id),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 14,
                        color: isActive ? collectionAccent : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          col.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? Colors.white : Colors.grey[300],
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        col.isCurated ? '${col.memberOrder.length}' : '필터',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                          fontFamily: 'Consolas',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171725),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AKASHA Pro',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '더 많은 기능을 경험해보세요',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: FilledButton(
              onPressed: () {
                // 업그레이드 액션 스텁
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5D3FD3),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                '업그레이드',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
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
                AnimatedScale(
                  scale: _isHovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: isActive ? widget.accentColor : Colors.grey[400],
                  ),
                ),
                AnimatedPadding(
                  padding: EdgeInsets.only(left: _isHovered ? 14 : 10),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: const SizedBox.shrink(),
                ),
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

class _RecentData {
  const _RecentData({required this.title, required this.category});
  final String title;
  final String category;
}

class _ColData {
  const _ColData({required this.title, required this.count});
  final String title;
  final int count;
}
