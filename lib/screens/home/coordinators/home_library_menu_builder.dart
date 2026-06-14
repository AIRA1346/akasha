import '../../../models/akasha_item.dart';
import '../../../models/browse_card.dart';
import '../../../models/personal_library_config.dart';
import '../../../services/file_service.dart';
import '../../../services/franchise_library_scope.dart';
import '../../../services/library_membership_apply.dart';
import '../../../services/personal_library_membership_service.dart';
import '../dialogs/work_library_menu.dart';
import '../home_registry_hide_actions.dart';

/// Work library popover/dialog 요청 객체 조립 (Presentation 진입 전).
class HomeLibraryMenuBuilder {
  const HomeLibraryMenuBuilder({
    required this.hideActions,
    required this.membership,
  });

  final HomeRegistryHideActions hideActions;
  final PersonalLibraryMembershipService membership;

  WorkLibraryMenuRequest buildRequest({
    required BrowseCard card,
    required AkashaItem workItem,
    required bool includeLibraryActions,
    required List<AkashaItem> vaultItems,
    required bool isCuratedLibraryActive,
    required String? activeLibraryId,
    required Future<PersonalLibraryConfig?> Function()? onCreateLibrary,
    required WorkLibraryPanelApplyCallback? onApply,
  }) {
    final fileService = AkashaFileService();
    final singleIds = FranchiseLibraryScope.workIdsForSingleFormat(card);
    final ipOption = includeLibraryActions &&
        FranchiseLibraryScope.offersEntireIpOption(card, vaultItems);
    final needsTitle =
        includeLibraryActions && !fileService.isArchivedInVault(workItem);
    return WorkLibraryMenuRequest(
      displayTitle: workItem.title,
      draftItem: workItem,
      showTitleEditor: needsTitle,
      draftMetaLine:
          needsTitle ? '${workItem.myStatusLabel} · ${workItem.category.label}' : null,
      singleWorkIds: singleIds,
      entireIpWorkIds: ipOption
          ? FranchiseLibraryScope.archivedWorkIdsForEntireIp(card, vaultItems)
          : singleIds,
      showIpScopeOption: ipOption,
      membership: membership,
      activeLibraryId: isCuratedLibraryActive ? activeLibraryId : null,
      onCreateLibrary: onCreateLibrary,
      onHideFromRegistry: hideActions.registryHideActionFor(workItem),
      onHideFranchise: hideActions.franchiseHideActionFor(card),
      onApply: onApply,
    );
  }
}
