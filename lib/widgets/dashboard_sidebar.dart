import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../models/akasha_item.dart';
import '../models/collectible_collection.dart';
import '../models/collectible_kind.dart';
import '../models/collectible_ref.dart';
import '../models/personal_library_config.dart';
import '../models/work_drag_payload.dart';
import '../screens/home/home_personal_library_controller.dart';
import '../screens/home/views/preview_record_view_model.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_typography.dart';
import '../generated/l10n/app_localizations.dart';
import '../utils/app_l10n.dart';
import 'personal_library_drop_target.dart';
import 'poster_image.dart';

part 'dashboard_sidebar_header_part.dart';
part 'dashboard_sidebar_section_title_part.dart';
part 'dashboard_sidebar_nav_tile_part.dart';
part 'dashboard_sidebar_thumbnail_tile_part.dart';
part 'dashboard_sidebar_nav_part.dart';
part 'dashboard_sidebar_recent_part.dart';
part 'dashboard_sidebar_personal_libraries_part.dart';
part 'dashboard_sidebar_collections_part.dart';
part 'dashboard_sidebar_footer_part.dart';

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
  final List<PersonalLibraryConfig> personalLibraries;
  final String? activePersonalLibraryId;
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
  final VoidCallback onAddPersonalLibrary;
  final void Function(String id) onSelectPersonalLibrary;
  final void Function(PersonalLibraryConfig library)? onEditPersonalLibrary;
  final void Function(String id)? onDeletePersonalLibrary;
  final Future<void> Function(String libraryId, WorkDragPayload payload)?
  onDropWorkToLibrary;
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
    this.personalLibraries = const [],
    this.activePersonalLibraryId,
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
    required this.onAddPersonalLibrary,
    required this.onSelectPersonalLibrary,
    this.onEditPersonalLibrary,
    this.onDeletePersonalLibrary,
    this.onDropWorkToLibrary,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isOpen ? _sidebarWidth : 0.0,
      decoration: BoxDecoration(
        color: palette.sidebar,
        border: Border(right: BorderSide(color: palette.borderSubtle(0.52))),
      ),
      clipBehavior: Clip.hardEdge,
      child: isOpen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DashboardSidebarLogoHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardSidebarPrimaryNav(
                          isHomeMode: isHomeMode,
                          isExploreMode: isExploreMode,
                          isPersonalLibraryMode: isPersonalLibraryMode,
                          isCollectibleCollectionMode:
                              isCollectibleCollectionMode,
                          isKnowledgeGraphMode: isKnowledgeGraphMode,
                          isTimelineMode: isTimelineMode,
                          onGoHome: onGoHome,
                          onGoExplore: onGoExplore,
                          onGoLibrary: onGoLibrary,
                          onGoCollection: onGoCollection,
                          onGoKnowledgeGraph: onGoKnowledgeGraph,
                          onSelectTimeline: onSelectTimeline,
                        ),
                        const SizedBox(height: 20),
                        _DashboardSidebarPersonalLibrariesSection(
                          selectionMode: selectionMode,
                          personalLibraries: personalLibraries,
                          activePersonalLibraryId: activePersonalLibraryId,
                          vaultItems: vaultItems,
                          onAddPersonalLibrary: onAddPersonalLibrary,
                          onSelectPersonalLibrary: onSelectPersonalLibrary,
                          onEditPersonalLibrary: onEditPersonalLibrary,
                          onDeletePersonalLibrary: onDeletePersonalLibrary,
                          onDropWorkToLibrary: onDropWorkToLibrary,
                        ),
                        if (recentExploreItems.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _DashboardSidebarRecentSection(
                            recentExploreItems: recentExploreItems,
                            activeDetailWorkId: activeDetailWorkId,
                            activeDetailEntityId: activeDetailEntityId,
                            onOpenRecentExplore: onOpenRecentExplore,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _DashboardSidebarCollectionsSection(
                          selectionMode: selectionMode,
                          collectibleCollections: collectibleCollections,
                          vaultItems: vaultItems,
                          activeCollectibleCollectionId:
                              activeCollectibleCollectionId,
                          onGoCollection: onGoCollection,
                          onSelectCollectibleCollection:
                              onSelectCollectibleCollection,
                        ),
                      ],
                    ),
                  ),
                ),
                if (onToggleSidebar != null)
                  _DashboardSidebarCollapseFooter(
                    onToggleSidebar: onToggleSidebar!,
                  ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
