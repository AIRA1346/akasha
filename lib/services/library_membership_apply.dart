import '../core/app_vault.dart';
import '../models/akasha_item.dart';
import '../models/membership_apply_result.dart';
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

/// panel 적용 실패 — [vaultMdCreated] 시 md는 유지 (Q5)
class LibraryApplyException implements Exception {
  final String message;
  final bool vaultMdCreated;
  final Object? cause;

  const LibraryApplyException(
    this.message, {
    this.vaultMdCreated = false,
    this.cause,
  });

  @override
  String toString() => message;
}

/// E1 · dialog 「적용」 — ensureVaultMd → reload → applyCheckboxDiff
class LibraryMembershipApply {
  LibraryMembershipApply._();

  /// add diff가 있고 draft md가 없을 때 saveItem 필요
  static bool needsVaultMd({
    required AkashaItem draft,
    required Map<String, bool?> desired,
    required Map<String, bool?> initial,
  }) {
    final vault = AppVault.port;
    if (vault.vaultPath == null || vault.isArchivedInVault(draft)) {
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
    final vault = AppVault.port;
    if (vault.vaultPath == null) {
      throw LibraryApplyException('볼트가 연결되지 않았습니다.');
    }
    if (vault.isArchivedInVault(draft)) {
      return draft;
    }

    final title = (titleOverride ?? draft.title).trim();
    if (title.isEmpty) {
      throw LibraryApplyException('제목을 입력하세요.');
    }

    draft.title = title;
    draft.workId = MarkdownParser.ensureWorkId(draft);
    await vault.saveItem(draft);
    return draft;
  }

  static Future<MembershipApplyResult> applyPanel({
    required AkashaItem draft,
    required WorkLibraryPanelApplyInput input,
    required PersonalLibraryMembershipService membership,
    required Future<void> Function() reloadItems,
    required List<String> Function(bool useEntireIp) resolveWorkIds,
  }) async {
    if (AppVault.port.vaultPath == null) {
      throw LibraryApplyException('볼트가 연결되지 않았습니다.');
    }

    var vaultMdCreated = false;
    try {
      if (needsVaultMd(
        draft: draft,
        desired: input.desiredChecked,
        initial: input.initialChecked,
      )) {
        await ensureVaultMd(
          draft: draft,
          titleOverride: input.titleOverride,
        );
        vaultMdCreated = true;
        await reloadItems();
      }

      final workIds = resolveWorkIds(input.useEntireIp);
      if (workIds.isEmpty) {
        return const MembershipApplyResult();
      }

      return await membership.applyCheckboxDiff(
        workIds: workIds,
        desiredChecked: input.desiredChecked,
        initialChecked: input.initialChecked,
      );
    } catch (e) {
      if (vaultMdCreated && e is! LibraryApplyException) {
        throw LibraryApplyException(
          '볼트 기록은 만들어졌으나 서재 반영에 실패했습니다. 다시 「적용」해 주세요.',
          vaultMdCreated: true,
          cause: e,
        );
      }
      if (e is LibraryApplyException) rethrow;
      throw LibraryApplyException('적용 실패: $e', cause: e);
    }
  }
}
