import '../models/akasha_item.dart';
import '../models/membership_apply_result.dart';
import 'file_service.dart';
import 'markdown_parser.dart';
import 'personal_library_membership_service.dart';

/// Panel 「적용」 입력 — coordinator에 전달
class WorkLibraryPanelApplyInput {
  final String? titleOverride;
  final bool useEntireIp;
  final Map<String, bool?> desiredChecked;
  final Map<String, bool?> initialChecked;

  const WorkLibraryPanelApplyInput({
    required this.titleOverride,
    required this.useEntireIp,
    required this.desiredChecked,
    required this.initialChecked,
  });
}

typedef WorkLibraryPanelApplyCallback = Future<MembershipApplyResult> Function(
  WorkLibraryPanelApplyInput input,
);

/// E1 · dialog 「적용」 — ensureVaultMd → reload → applyCheckboxDiff
class LibraryMembershipApply {
  LibraryMembershipApply._();

  /// add diff가 있고 draft md가 없을 때 saveItem 필요
  static bool needsVaultMd({
    required AkashaItem draft,
    required Map<String, bool?> desired,
    required Map<String, bool?> initial,
  }) {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null || fileService.isArchivedInVault(draft)) {
      return false;
    }
    for (final entry in desired.entries) {
      if (entry.value == true && entry.value != initial[entry.key]) {
        return true;
      }
    }
    return false;
  }

  static Future<AkashaItem> ensureVaultMd({
    required AkashaItem draft,
    String? titleOverride,
  }) async {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null) {
      throw StateError('볼트가 연결되지 않았습니다.');
    }
    if (fileService.isArchivedInVault(draft)) {
      return draft;
    }

    final title = (titleOverride ?? draft.title).trim();
    if (title.isEmpty) {
      throw StateError('제목을 입력하세요.');
    }

    draft.title = title;
    draft.workId = MarkdownParser.ensureWorkId(draft);
    await fileService.saveItem(draft);
    return draft;
  }

  static Future<MembershipApplyResult> applyPanel({
    required AkashaItem draft,
    required WorkLibraryPanelApplyInput input,
    required PersonalLibraryMembershipService membership,
    required Future<void> Function() reloadItems,
    required List<String> Function(bool useEntireIp) resolveWorkIds,
  }) async {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null) {
      throw StateError('볼트가 연결되지 않았습니다.');
    }

    if (needsVaultMd(
      draft: draft,
      desired: input.desiredChecked,
      initial: input.initialChecked,
    )) {
      await ensureVaultMd(
        draft: draft,
        titleOverride: input.titleOverride,
      );
      await reloadItems();
    }

    final workIds = resolveWorkIds(input.useEntireIp);
    if (workIds.isEmpty) {
      return const MembershipApplyResult();
    }

    return membership.applyCheckboxDiff(
      workIds: workIds,
      desiredChecked: input.desiredChecked,
      initialChecked: input.initialChecked,
    );
  }
}
