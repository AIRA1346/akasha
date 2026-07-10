import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/vault_recovery_write_service.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'entity_detail_archive_ops.dart';
import 'entity_detail_draft_ops.dart';
import 'entity_detail_save_ops.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_l10n.dart';

/// EntityDetailWorkspace — 저장 성공 후 UI·상태 패치.
class EntityDetailSaveUiPatch {
  const EntityDetailSaveUiPatch({
    required this.entity,
    required this.journal,
    required this.item,
    required this.preview,
    required this.draftTags,
    required this.serializedFile,
    required this.bodyForPlaceholder,
    required this.pageView,
    required this.savedAt,
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry journal;
  final EntityItem item;
  final EntityItem preview;
  final List<String> draftTags;
  final String serializedFile;
  final String? bodyForPlaceholder;
  final SanctumPageView? pageView;
  final DateTime savedAt;

  static EntityDetailSaveUiPatch fromSucceeded({
    required EntityDetailSaveSucceeded result,
    required SanctumPageView currentPageView,
    required bool silent,
  }) {
    final nextPageView = EntityDetailSaveOps.pageViewAfterSave(
      current: currentPageView,
      silent: silent,
    );
    final item = EntityDetailDraftOps.buildEntityItem(
      result.mirrored,
      result.saved,
    );
    return EntityDetailSaveUiPatch(
      entity: result.mirrored,
      journal: result.saved,
      item: item,
      preview: item,
      draftTags: List<String>.from(result.saved.tags),
      serializedFile: result.serializedFile,
      bodyForPlaceholder: result.bodyForPlaceholder,
      pageView: nextPageView,
      savedAt: result.savedAt,
    );
  }
}

/// Entity journal 저장 전 검증·본문 해석.
sealed class EntityDetailSavePrepareResult {
  const EntityDetailSavePrepareResult();
}

class EntityDetailSaveBlocked extends EntityDetailSavePrepareResult {
  const EntityDetailSaveBlocked(this.message);

  final String message;
}

class EntityDetailSaveReady extends EntityDetailSavePrepareResult {
  const EntityDetailSaveReady({
    required this.body,
    required this.usedPlaceholder,
  });

  final String body;
  final bool usedPlaceholder;
}

abstract final class EntityDetailSavePrepareOps {
  static EntityDetailSavePrepareResult prepare(
    BuildContext context, {
    required String rawBody,
    required String posterPath,
    required List<String> tags,
    required bool silent,
    required SanctumPageView pageView,
    required void Function() syncBodyFromEditor,
  }) {
    final vaultMsg = EntityDetailSaveOps.vaultBlockedMessage(
      context,
      silent: silent,
    );
    if (vaultMsg != null) {
      return EntityDetailSaveBlocked(vaultMsg);
    }

    if (pageView == SanctumPageView.file) {
      syncBodyFromEditor();
    }

    final emptyMsg = EntityDetailSaveOps.emptyBodyBlockedMessage(
      context,
      rawBody: rawBody,
      posterPath: posterPath,
      tags: tags,
      silent: silent,
    );
    if (emptyMsg != null) {
      return EntityDetailSaveBlocked(emptyMsg);
    }

    final bodyResolve = EntityDetailArchiveOps.resolveBodyForSave(
      context,
      rawBody: rawBody,
      posterPath: posterPath,
      tags: tags,
    );
    final body = bodyResolve.body!;
    return EntityDetailSaveReady(
      body: body,
      usedPlaceholder: bodyResolve.usedPlaceholder,
    );
  }

  static String? saveFailedMessage(
    BuildContext context, {
    required Object error,
    required bool silent,
  }) {
    if (silent) return null;
    if (error is EntityVaultPathConflict) return error.userMessage;
    if (error is VaultWriteConflictException) {
      return '외부 변경을 감지해 저장하지 않았습니다. 편집본은 복구 충돌 보관함에 남겼습니다.';
    }
    final l10n = lookupAppL10n(context);
    return l10n != null
        ? l10n.errorSaveFailed(error.toString())
        : '저장 실패: $error';
  }
}
