import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../models/akasha_item.dart';
import '../models/collectible_collection.dart';
import '../models/dashboard_config.dart';
import '../models/personal_library_config.dart';
import '../models/work_drag_payload.dart';
import '../screens/home/home_personal_library_controller.dart';
import '../theme/akasha_colors.dart';
import 'personal_library_drop_target.dart';
import 'poster_image.dart';

/// 나만의 서재 + 컬렉션 + 대시보드 서재 사이드바.
class DashboardSidebar extends StatelessWidget {
  static const Color dashboardAccent = AkashaColors.accent;
  static const Color personalAccent = Colors.amberAccent;
  static const Color collectionAccent = AkashaColors.accentDark;

  final bool isOpen;
  final bool isExploreMode;
  final bool isKnowledgeGraphMode;
  final SidebarSelectionMode selectionMode;
  final List<AkashaItem> recentExploreItems;
  final List<DashboardConfig> dashboards;
  final String? activeDashboardId;
  final List<PersonalLibraryConfig> personalLibraries;
  final String? activePersonalLibraryId;
  final List<CollectibleCollection> collectibleCollections;
  final String? activeCollectibleCollectionId;
  final VoidCallback onAddDashboard;
  final Future<void> Function(String id) onSelectDashboard;
  final Future<void> Function() onGoHome;
  final Future<void> Function() onGoExplore;
  final Future<void> Function() onGoKnowledgeGraph;
  final void Function(AkashaItem item)? onOpenRecentExplore;
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
    required this.isExploreMode,
    this.isKnowledgeGraphMode = false,
    this.recentExploreItems = const [],
    required this.selectionMode,
    required this.dashboards,
    required this.activeDashboardId,
    required this.personalLibraries,
    required this.activePersonalLibraryId,
    this.collectibleCollections = const [],
    this.activeCollectibleCollectionId,
    required this.onAddDashboard,
    required this.onSelectDashboard,
    required this.onGoHome,
    required this.onGoExplore,
    required this.onGoKnowledgeGraph,
    this.onOpenRecentExplore,
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
        color: AkashaColors.sidebar,
        border: Border(
          right: BorderSide(color: AkashaColors.border, width: 1.5),
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
                if (personalLibraries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPersonalLibraries(),
                ],
                if (recentExploreItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildRecentExplores(),
                ],
                        if (_customDashboards.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildCustomDashboards(),
                        ],
                        const SizedBox(height: 16),
                        _buildMyCollections(),
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
                        color: AkashaColors.sidebarFooter,
                        border: Border(top: BorderSide(color: AkashaColors.border)),
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
                      color: AkashaColors.sidebarFooter,
                      border: Border(top: BorderSide(color: AkashaColors.border)),
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
              color: AkashaColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.blur_on_rounded,
              color: AkashaColors.accent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            '도구',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (FeatureFlags.showKnowledgeGraph)
          _buildMenuTile(
            icon: Icons.hub_outlined,
            label: '연결 목록',
            isSelected: isKnowledgeGraphMode,
            onTap: () => onGoKnowledgeGraph(),
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
        color: isSelected ? AkashaColors.menuSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? Border.all(
                color: AkashaColors.accent.withValues(alpha: 0.3),
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
                color: isSelected ? AkashaColors.accent : Colors.grey[400],
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

  List<DashboardConfig> get _customDashboards =>
      dashboards.where((d) => d.id != 'master_index').toList();

  Widget _buildSectionTitle(String title, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 14, color: Colors.grey[500]),
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
        const SizedBox(height: 4),
        ...recentExploreItems.take(5).map((item) {
          final isEntity = item is EntityItem;
          return SidebarItemWidget(
            name: item.title,
            icon: isEntity ? Icons.person_outline : Icons.movie_outlined,
            isActive: false,
            accentColor: dashboardAccent,
            onTap: onOpenRecentExplore == null
                ? () {}
                : () => onOpenRecentExplore!(item),
          );
        }),
      ],
    );
  }

  Widget _buildPersonalLibraries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('나의 서재', onAdd: onAddPersonalLibrary),
        const SizedBox(height: 4),
        ...personalLibraries.map((lib) {
          final isActive = selectionMode == SidebarSelectionMode.personalLibrary &&
              lib.id == activePersonalLibraryId;
          Widget row = SidebarItemWidget(
            name: lib.isCurated && lib.memberOrder.isNotEmpty
                ? '${lib.name} (${lib.memberOrder.length})'
                : lib.name,
            icon: lib.isMasterArchive
                ? Icons.inventory_2_outlined
                : lib.isCurated
                    ? Icons.collections_bookmark_outlined
                    : lib.categories.length == 1
                        ? lib.categories.first.icon
                        : Icons.filter_list_outlined,
            isActive: isActive,
            accentColor: personalAccent,
            canEdit: lib.id != PersonalLibraryConfig.masterArchiveId,
            canDelete: lib.id != PersonalLibraryConfig.masterArchiveId,
            editTooltip: '서재 설정',
            onTap: () => onSelectPersonalLibrary(lib.id),
            onEdit: () => onEditPersonalLibrary(lib),
            onDelete: () => onDeletePersonalLibrary(lib.id),
          );
          if (lib.isCurated && onDropWorkToLibrary != null) {
            row = PersonalLibraryDropTarget(
              accentColor: personalAccent,
              onAccept: (payload) {
                onLibraryDragStarted?.call();
                onDropWorkToLibrary!(lib.id, payload);
              },
              child: row,
            );
          }
          return row;
        }),
      ],
    );
  }

  Widget _buildCustomDashboards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('대시보드', onAdd: onAddDashboard),
        const SizedBox(height: 4),
        ..._customDashboards.map((dash) {
          final isActive = selectionMode == SidebarSelectionMode.dashboard &&
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
            onTap: () => onSelectDashboard(dash.id),
            onEdit: () => onEditDashboard(dash),
            onDelete: () => onDeleteDashboard(dash.id),
          );
        }),
      ],
    );
  }

  Widget _buildMyCollections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('내 컬렉션', onAdd: onAddCollectibleCollection),
          const SizedBox(height: 4),
          if (collectibleCollections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '컬렉션이 없습니다',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            )
          else
            ...collectibleCollections.take(8).map((col) {
              final isActive =
                  selectionMode == SidebarSelectionMode.collectibleCollection &&
                      activeCollectibleCollectionId == col.id;
              final countLabel = col.isCurated
                  ? (col.memberOrder.isNotEmpty ? ' (${col.memberOrder.length})' : '')
                  : '';
              return SidebarItemWidget(
                name: '${col.title}$countLabel',
                icon: col.isCurated
                    ? Icons.favorite_outline
                    : Icons.local_offer_outlined,
                isActive: isActive,
                accentColor: collectionAccent,
                editTooltip: '컬렉션 설정',
                onTap: () => onSelectCollectibleCollection(col.id),
                onEdit: () => onEditCollectibleCollection(col),
                onDelete: () => onDeleteCollectibleCollection(col.id),
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
        color: AkashaColors.proBanner,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AkashaColors.borderSubtle()),
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
          Text(
            '곧 출시 예정',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
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
        color: AkashaColors.border,
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
              ? AkashaColors.menuSelected
              : _isHovered
                  ? AkashaColors.surface
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
