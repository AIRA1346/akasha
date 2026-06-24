import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'entity_detail_archive_ops.dart';
import 'entity_detail_draft_ops.dart';

/// EntityDetailWorkspace 저장 플로우 결과.
sealed class EntityDetailSaveFlowResult {
  const EntityDetailSaveFlowResult();
}

class EntityDetailSaveSkipped extends EntityDetailSaveFlowResult {
  const EntityDetailSaveSkipped();
}

class EntityDetailSaveFailed extends EntityDetailSaveFlowResult {
  const EntityDetailSaveFailed(this.error);

  final Object error;
}

class EntityDetailSaveSucceeded extends EntityDetailSaveFlowResult {
  const EntityDetailSaveSucceeded({
    required this.mirrored,
    required this.saved,
    required this.savedAt,
    required this.serializedFile,
    required this.bodyForPlaceholder,
    required this.usedPlaceholder,
  });

  final UserCatalogEntity mirrored;
  final EntityJournalEntry saved;
  final DateTime savedAt;
  final String serializedFile;
  final String? bodyForPlaceholder;
  final bool usedPlaceholder;
}

/// EntityDetailWorkspace — 저장 전 검증·persist.
abstract final class EntityDetailSaveOps {
  static bool shouldSkip({
    required bool suppressPersist,
    required bool isSaving,
  }) =>
      suppressPersist || isSaving;

  static String? vaultBlockedMessage({required bool silent}) {
    if (EntityDetailArchiveOps.isVaultConnected()) return null;
    return EntityDetailArchiveOps.vaultRequiredSnack(silent: silent);
  }

  static String? emptyBodyBlockedMessage({
    required String rawBody,
    required String posterPath,
    required List<String> tags,
    required bool silent,
  }) {
    final bodyResolve = EntityDetailArchiveOps.resolveBodyForSave(
      rawBody: rawBody,
      posterPath: posterPath,
      tags: tags,
    );
    if (bodyResolve.body != null) return null;
    return EntityDetailArchiveOps.emptyBodySnack(silent: silent);
  }

  static Future<void> warnWorkTitleTagsIfNeeded({
    required BuildContext context,
    required UserCatalogPort? catalog,
    required List<String> tags,
  }) async {
    if (catalog == null) return;
    await catalog.load();
    if (!context.mounted) return;
    EntityTagValidation.showWorkTitleWarningIfNeeded(
      context,
      tags: tags,
      workTitles: EntityTagValidation.buildWorkTitleIndex(
        catalogEntities: catalog.all,
        vaultItems: const [],
      ),
    );
  }

  static Future<EntityDetailSaveFlowResult> run({
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
    required List<String> tags,
    required String posterPath,
    required String body,
    required bool usedPlaceholder,
    required UserCatalogPort? catalog,
    required EntityVaultStore vaultStore,
  }) async {
    try {
      final vaultPath = AkashaFileService().vaultPath!;
      final entityDraft = entity.copyWith(tags: tags, posterPath: posterPath);
      final outcome = await EntityDetailArchiveOps.persist(
        vaultPath: vaultPath,
        entityDraft: entityDraft,
        existingJournal: journal,
        body: body,
        tags: tags,
        posterPath: posterPath,
        userCatalog: catalog,
        vaultStore: vaultStore,
      );
      return EntityDetailSaveSucceeded(
        mirrored: outcome.mirrored,
        saved: outcome.saved,
        savedAt: DateTime.now(),
        serializedFile: EntityDetailDraftOps.serializeFile(
          entity: outcome.mirrored,
          journal: outcome.saved,
          body: body,
          tags: tags,
          posterPath: posterPath,
        ),
        bodyForPlaceholder: usedPlaceholder ? body : null,
        usedPlaceholder: usedPlaceholder,
      );
    } on EntityVaultPathConflict catch (e) {
      return EntityDetailSaveFailed(e);
    } catch (e) {
      return EntityDetailSaveFailed(e);
    }
  }

  static SanctumPageView? pageViewAfterSave({
    required SanctumPageView current,
    required bool silent,
  }) {
    if (silent || current == SanctumPageView.file) return null;
    return SanctumPageView.preview;
  }
}
