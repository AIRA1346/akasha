import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../models/browse_card.dart';
import '../../models/work_drag_payload.dart';
import '../../services/franchise_library_scope.dart';
import '../../services/markdown_parser.dart';
import '../../services/personal_library_membership_service.dart';
import '../../widgets/poster_card.dart';
import '../../widgets/work_draggable_card.dart';
import 'home_registry_hide_actions.dart';

/// Browse/PersonalLibrary 그리드용 포스터 카드 빌드 (DnD·메뉴·숨김 액션 포함)
class HomePosterCardFactory {
  const HomePosterCardFactory({
    required this.allItems,
    required this.libraryMembership,
    required this.hideActions,
    required this.isPersonalLibraryMode,
    required this.canAddToLibrary,
    required this.onOpenItem,
    required this.onOpenLibraryMenu,
    required this.onLibraryDragStarted,
  });

  final List<AkashaItem> allItems;
  final PersonalLibraryMembershipService libraryMembership;
  final HomeRegistryHideActions hideActions;
  final bool isPersonalLibraryMode;
  final bool canAddToLibrary;
  final void Function(AkashaItem item) onOpenItem;
  final void Function(BrowseCard card, Offset anchor) onOpenLibraryMenu;
  final VoidCallback onLibraryDragStarted;

  Widget build(BrowseCard card) {
    final item = card.item;
    final libraryBadgeCount = canAddToLibrary
        ? libraryMembership.countLibrariesContainingAny(
            FranchiseLibraryScope.relatedWorkIds(card, allItems),
          )
        : 0;

    final hideRegistry = hideActions.registryHideActionFor(item);
    final hideFranchise = hideActions.franchiseHideActionFor(card);
    final canOpenMenu =
        canAddToLibrary || hideRegistry != null || hideFranchise != null;

    Widget poster = PosterCard(
      item: item,
      formatSlots: card.formatSlots,
      franchiseId: card.franchiseId,
      showPoster: isPersonalLibraryMode,
      curatedLibraryCount: libraryBadgeCount,
      onTap: () => onOpenItem(item),
      onOpenLibraryMenu:
          canOpenMenu ? (pos) => onOpenLibraryMenu(card, pos) : null,
      onHideFormatSlot: hideActions.formatSlotHideActionFor(card),
    );

    if (canAddToLibrary) {
      final workId =
          item.workId.isNotEmpty ? item.workId : MarkdownParser.ensureWorkId(item);
      poster = WorkDraggableCard(
        payload: WorkDragPayload(
          workId: workId,
          item: item,
          source: isPersonalLibraryMode
              ? WorkDragSource.libraryGrid
              : WorkDragSource.catalogGrid,
        ),
        onDragStarted: onLibraryDragStarted,
        child: poster,
      );
    }

    return poster;
  }
}
