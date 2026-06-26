import '../../../core/ports/vault_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/browse_card.dart';
import '../../../models/membership_apply_result.dart';
import '../../../models/personal_library_config.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/franchise_library_scope.dart';
import '../../../services/library_membership_apply.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/personal_library_membership_service.dart';
import '../home_personal_library_controller.dart';

/// DnD·패널 「적용」 결과 — Presentation이 SnackBar만 담당
class AddWorkToLibraryOutcome {
  const AddWorkToLibraryOutcome.added(this.libraryName)
      : alreadyInLibrary = false,
        vaultMdError = null,
        skipped = false;

  const AddWorkToLibraryOutcome.alreadyPresent(this.libraryName)
      : alreadyInLibrary = true,
        vaultMdError = null,
        skipped = false;

  const AddWorkToLibraryOutcome.skipped()
      : libraryName = null,
        alreadyInLibrary = false,
        vaultMdError = null,
        skipped = true;

  const AddWorkToLibraryOutcome.vaultMdFailed(this.vaultMdError)
      : libraryName = null,
        alreadyInLibrary = false,
        skipped = false;

  final String? libraryName;
  final bool alreadyInLibrary;
  final String? vaultMdError;
  final bool skipped;
}

/// curated 서재 담기·패널 적용 오케스트레이션 (Wave 1.1).
class HomeMembershipCoordinator {
  HomeMembershipCoordinator({
    required VaultPort vault,
    required HomePersonalLibraryController personalLibraryController,
    required PersonalLibraryMembershipService membership,
    required AkashaItem Function(AkashaItem) resolveItemForOpen,
    required Future<void> Function() reloadItems,
  })  : _vault = vault,
        _personalLibraryController = personalLibraryController,
        _membership = membership,
        _resolveItemForOpen = resolveItemForOpen,
        _reloadItems = reloadItems;

  final VaultPort _vault;

  final HomePersonalLibraryController _personalLibraryController;
  final PersonalLibraryMembershipService _membership;
  final AkashaItem Function(AkashaItem) _resolveItemForOpen;
  final Future<void> Function() _reloadItems;

  HomePersonalLibraryController get personalLibraryController =>
      _personalLibraryController;

  PersonalLibraryMembershipService get membership => _membership;

  /// DnD·메뉴·다이얼로그에서 작품을 curated 서재에 담기.
  Future<AddWorkToLibraryOutcome> addWorkToLibrary({
    required String libraryId,
    required AkashaItem item,
  }) async {
    final fileService = _vault;
    var workItem = _resolveItemForOpen(item);

    if (!fileService.isArchivedInVault(workItem)) {
      try {
        await LibraryMembershipApply.ensureVaultMd(draft: workItem);
        await _reloadItems();
        workItem = _resolveItemForOpen(item);
      } catch (e) {
        return AddWorkToLibraryOutcome.vaultMdFailed(e.toString());
      }
    }

    PersonalLibraryConfig? lib;
    for (final l in _personalLibraryController.libraries) {
      if (l.id == libraryId) {
        lib = l;
        break;
      }
    }
    if (lib == null || !lib.isCurated) {
      return const AddWorkToLibraryOutcome.skipped();
    }

    final workId = MarkdownParser.ensureWorkId(workItem);
    final already = _membership.containsWork(lib, workId);
    await _membership.addWork(libraryId, workId);

    return already
        ? AddWorkToLibraryOutcome.alreadyPresent(lib.name)
        : AddWorkToLibraryOutcome.added(lib.name);
  }

  /// work library panel 「적용」.
  Future<MembershipApplyResult> applyWorkLibraryPanel(
    BrowseCard card, {
    required AkashaItem draft,
    required WorkLibraryPanelApplyInput input,
    required List<AkashaItem> vaultItems,
  }) {
    return LibraryMembershipApply.applyPanel(
      draft: draft,
      input: input,
      membership: _membership,
      reloadItems: _reloadItems,
      resolveWorkIds: (useEntireIp) {
        final ipOption =
            FranchiseLibraryScope.offersEntireIpOption(card, vaultItems);
        if (ipOption && useEntireIp) {
          return FranchiseLibraryScope.archivedWorkIdsForEntireIp(
            card,
            vaultItems,
          );
        }
        final resolved = _resolveItemForOpen(draft);
        return FranchiseLibraryScope.workIdsForSingleFormat(
          BrowseCard(
            item: resolved,
            formatSlots: card.formatSlots,
            franchiseId: card.franchiseId,
          ),
        );
      },
    );
  }

  /// Entity library panel 「적용」.
  Future<MembershipApplyResult> applyEntityLibraryPanel(
    UserCatalogEntity entity, {
    required WorkLibraryPanelApplyInput input,
  }) async {
    return await _membership.applyCheckboxDiff(
      workIds: [entity.entityId],
      desiredChecked: input.desiredChecked,
      initialChecked: input.initialChecked,
    );
  }
}
