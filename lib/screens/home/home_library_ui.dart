import 'package:flutter/material.dart';

import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../models/user_catalog_entity.dart';
import '../../models/browse_card.dart';
import '../../models/membership_apply_result.dart';
import '../../models/personal_library_config.dart';
import '../../models/work_drag_payload.dart';
import '../../services/works_registry.dart';
import 'coordinators/home_browse_card_builder.dart';
import 'coordinators/home_library_menu_builder.dart';
import 'coordinators/home_membership_coordinator.dart';
import 'coordinators/home_filter_coordinator.dart';
import 'dialogs/work_library_menu.dart';
import 'home_auto_archive.dart';
import 'home_personal_library_controller.dart';
import 'home_registry_hide_actions.dart';
import 'dialogs/personal_library_name_dialog.dart';
import '../../utils/app_l10n.dart';

/// 서재 담기·work library 메뉴 Presentation glue (Wave 1.3b).
class HomeLibraryUi {
  const HomeLibraryUi({
    required this.vault,
    required this.membershipCoordinator,
    required this.libraryMenuBuilder,
    required this.filterCoordinator,
    required this.personalLibCtrl,
    required this.hideActions,
  });

  final VaultPort vault;
  final HomeMembershipCoordinator membershipCoordinator;
  final HomeLibraryMenuBuilder libraryMenuBuilder;
  final HomeFilterCoordinator filterCoordinator;
  final HomePersonalLibraryController personalLibCtrl;
  final HomeRegistryHideActions hideActions;

  WorkLibraryMenuRequest buildMenuRequest({
    required BrowseCard card,
    required AkashaItem workItem,
    required bool includeLibraryActions,
    required List<AkashaItem> vaultItems,
    required bool isCuratedLibraryActive,
    required Future<PersonalLibraryConfig?> Function()? onCreateLibrary,
  }) {
    return libraryMenuBuilder.buildRequest(
      card: card,
      workItem: workItem,
      includeLibraryActions: includeLibraryActions,
      vaultItems: vaultItems,
      isCuratedLibraryActive: isCuratedLibraryActive,
      activeLibraryId: personalLibCtrl.activeLibraryId,
      onCreateLibrary: onCreateLibrary,
      onApply: includeLibraryActions
          ? (input) => membershipCoordinator.applyWorkLibraryPanel(
              card,
              draft: workItem,
              input: input,
              vaultItems: vaultItems,
            )
          : null,
    );
  }

  void showMembershipApplySnackBar(
    BuildContext context,
    MembershipApplyResult? result,
  ) {
    if (result == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.toSnackBarMessage())));
  }

  Future<void> addWorkToLibrary(
    BuildContext context, {
    required String libraryId,
    required AkashaItem item,
    required bool switchToLibrary,
    required void Function(void Function()) setState,
    required void Function(String libraryId) selectPersonalLibrary,
  }) async {
    final l10n = lookupAppL10n(context);
    if (vault.vaultPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorVaultRequiredToAddToLibrary ??
                '볼트를 먼저 연결해야 서재에 담을 수 있습니다.',
          ),
        ),
      );
      return;
    }

    final outcome = await membershipCoordinator.addWorkToLibrary(
      libraryId: libraryId,
      item: item,
    );
    if (!context.mounted) return;

    if (outcome.vaultMdError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n != null
                ? l10n.errorArchiveFailed(outcome.vaultMdError.toString())
                : '아카이브 실패: ${outcome.vaultMdError}',
          ),
        ),
      );
      return;
    }
    if (outcome.skipped || outcome.libraryName == null) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.alreadyInLibrary
              ? (l10n != null
                    ? l10n.alreadyInLibrary(outcome.libraryName!)
                    : '이미 「${outcome.libraryName}」 서재에 있습니다.')
              : (l10n != null
                    ? l10n.addedToLibrary(outcome.libraryName!)
                    : '「${outcome.libraryName}」 서재에 담았습니다.'),
        ),
        action: switchToLibrary
            ? SnackBarAction(
                label: l10n?.actionView ?? '보기',
                onPressed: () => selectPersonalLibrary(libraryId),
              )
            : null,
      ),
    );
  }

  Future<void> openWorkLibraryMenu(
    BuildContext context, {
    required BrowseCard card,
    required Offset anchor,
    required bool canAddToLibrary,
    required bool isCuratedLibraryActive,
    required List<AkashaItem> items,
    required AkashaItem Function(AkashaItem) resolveItemForOpen,
    required void Function(void Function()) setState,
    required Future<PersonalLibraryConfig?> Function() onCreateLibrary,
  }) async {
    final hasHide =
        hideActions.registryHideActionFor(card.item) != null ||
        hideActions.franchiseHideActionFor(card) != null;
    if (!canAddToLibrary && !hasHide) return;

    final l10n = lookupAppL10n(context);
    if (canAddToLibrary && vault.vaultPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorVaultRequiredToAddToLibrary ??
                '볼트를 먼저 연결해야 서재에 담을 수 있습니다.',
          ),
        ),
      );
      return;
    }

    final workItem = resolveItemForOpen(card.item);
    if (!context.mounted) return;

    final result = await showWorkLibraryPopover(
      context,
      anchor: anchor,
      request: buildMenuRequest(
        card: card,
        workItem: workItem,
        includeLibraryActions: canAddToLibrary,
        vaultItems: items,
        isCuratedLibraryActive: isCuratedLibraryActive,
        onCreateLibrary: canAddToLibrary ? onCreateLibrary : null,
      ),
    );
    if (!context.mounted) return;
    showMembershipApplySnackBar(context, result);
    setState(() {});
  }

  Future<void> showAddToLibraryForCard(
    BuildContext context, {
    required BrowseCard card,
    required bool isCuratedLibraryActive,
    required List<AkashaItem> items,
    required AkashaItem Function(AkashaItem) resolveItemForOpen,
    required void Function(void Function()) setState,
    required Future<PersonalLibraryConfig?> Function() onCreateLibrary,
  }) async {
    final l10n = lookupAppL10n(context);
    if (vault.vaultPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorVaultRequiredToAddToLibrary ??
                '볼트를 먼저 연결해야 서재에 담을 수 있습니다.',
          ),
        ),
      );
      return;
    }

    final workItem = resolveItemForOpen(card.item);
    if (!context.mounted) return;

    final result = await showWorkLibraryDialog(
      context,
      request: buildMenuRequest(
        card: card,
        workItem: workItem,
        includeLibraryActions: true,
        vaultItems: items,
        isCuratedLibraryActive: isCuratedLibraryActive,
        onCreateLibrary: onCreateLibrary,
      ),
    );
    if (!context.mounted) return;
    showMembershipApplySnackBar(context, result);
    setState(() {});
  }

  Future<void> showAddToLibraryForItem(
    BuildContext context, {
    required AkashaItem item,
    required bool isCuratedLibraryActive,
    required List<AkashaItem> items,
    required AkashaItem Function(AkashaItem) resolveItemForOpen,
    required void Function(void Function()) setState,
    required Future<PersonalLibraryConfig?> Function() onCreateLibrary,
  }) async {
    await showAddToLibraryForCard(
      context,
      card: HomeBrowseCardBuilder.forItem(item, items),
      isCuratedLibraryActive: isCuratedLibraryActive,
      items: items,
      resolveItemForOpen: resolveItemForOpen,
      setState: setState,
      onCreateLibrary: onCreateLibrary,
    );
  }

  Future<void> addRegistryWorkToLibrary(
    BuildContext context, {
    required RegistryWork work,
    required bool isCuratedLibraryActive,
    required List<AkashaItem> items,
    required AkashaItem Function(AkashaItem) resolveItemForOpen,
    required void Function(void Function()) setState,
    required Future<PersonalLibraryConfig?> Function() onCreateLibrary,
  }) async {
    AkashaItem? existing;
    for (final i in items) {
      if (WorksRegistry.setContainsWorkId({work.workId}, i.workId)) {
        existing = i;
        break;
      }
    }

    final item = existing != null
        ? resolveItemForOpen(existing)
        : HomeAutoArchive.itemFromRegistryWork(work);
    await showAddToLibraryForCard(
      context,
      card: HomeBrowseCardBuilder.forItem(item, items),
      isCuratedLibraryActive: isCuratedLibraryActive,
      items: items,
      resolveItemForOpen: resolveItemForOpen,
      setState: setState,
      onCreateLibrary: onCreateLibrary,
    );
    setState(() {});
  }

  Future<void> onDropWorkToLibrary(
    BuildContext context, {
    required String libraryId,
    required WorkDragPayload payload,
    required void Function(void Function()) setState,
    required void Function(String libraryId) selectPersonalLibrary,
  }) async {
    await addWorkToLibrary(
      context,
      libraryId: libraryId,
      item: payload.item,
      switchToLibrary: true,
      setState: setState,
      selectPersonalLibrary: selectPersonalLibrary,
    );
  }

  Future<PersonalLibraryConfig?> promptCreateCuratedLibrary(
    BuildContext context, {
    required void Function(void Function()) setState,
  }) async {
    final name = await showPersonalLibraryNameDialog(context);
    if (name == null || !context.mounted) return null;
    final config = PersonalLibraryConfig(
      id: 'personal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      mode: PersonalLibraryMode.curated,
    );
    setState(() {
      personalLibCtrl.add(config);
      filterCoordinator.applyPersonalLibraryFilterSnapshot(config);
    });
    await personalLibCtrl.save();
    setState(() {});
    return config;
  }

  Future<void> showAddToLibraryForEntity(
    BuildContext context, {
    required UserCatalogEntity entity,
    required bool isCuratedLibraryActive,
    required List<AkashaItem> items,
    required void Function(void Function()) setState,
    required Future<PersonalLibraryConfig?> Function() onCreateLibrary,
  }) async {
    final l10n = lookupAppL10n(context);
    if (vault.vaultPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorVaultRequiredToAddToLibrary ??
                '볼트를 먼저 연결해야 서재에 담을 수 있습니다.',
          ),
        ),
      );
      return;
    }

    final dummyItem = ContentItem(
      workId: entity.entityId,
      title: entity.title,
      category: MediaCategory.book,
      domain: AppDomain.newWorkDefault,
      tags: entity.tags,
      addedAt: entity.addedAt,
      posterPath: entity.posterPath,
    );
    dummyItem.filePath = 'dummy_path';

    final request = WorkLibraryMenuRequest(
      displayTitle: entity.title,
      draftItem: dummyItem,
      showTitleEditor: false,
      singleWorkIds: [entity.entityId],
      entireIpWorkIds: const [],
      showIpScopeOption: false,
      membership: membershipCoordinator.membership,
      activeLibraryId: personalLibCtrl.activeLibraryId,
      onCreateLibrary: onCreateLibrary,
      onApply: (input) =>
          membershipCoordinator.applyEntityLibraryPanel(entity, input: input),
    );

    if (!context.mounted) return;

    final result = await showWorkLibraryDialog(context, request: request);
    if (!context.mounted) return;
    showMembershipApplySnackBar(context, result);
    setState(() {});
  }
}
