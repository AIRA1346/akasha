import 'package:flutter/material.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_vault_store.dart';
import 'workbench_vault.dart';
import '../../../utils/app_l10n.dart';

const kEntityJournalPlaceholderBody = '(기록 대기중)';

class EntityBodyResolveResult {
  const EntityBodyResolveResult({
    required this.body,
    this.usedPlaceholder = false,
  });

  /// `null`이면 저장을 중단합니다 (본문·메타 모두 비어 있음).
  final String? body;
  final bool usedPlaceholder;
}

class EntityDetailSaveOutcome {
  const EntityDetailSaveOutcome({required this.mirrored, required this.saved});

  final UserCatalogEntity mirrored;
  final EntityJournalEntry saved;
}

/// EntityDetailWorkspace 저장·아카이브 상태 (WorkDetailArchiveOps 대칭).
abstract final class EntityDetailArchiveOps {
  static bool hasJournal(EntityJournalEntry? journal) => journal != null;

  static bool isVaultConnected() {
    final vaultPath = WorkbenchVault.port.vaultPath;
    return vaultPath != null && vaultPath.isNotEmpty;
  }

  static EntityBodyResolveResult resolveBodyForSave(
    BuildContext context, {
    required String rawBody,
    required String posterPath,
    required List<String> tags,
  }) {
    var body = rawBody.trim();
    if (body.isNotEmpty) {
      return EntityBodyResolveResult(body: body);
    }
    final hasMetaChanges = posterPath.trim().isNotEmpty || tags.isNotEmpty;
    if (!hasMetaChanges) {
      return const EntityBodyResolveResult(body: null);
    }
    final l10n = lookupAppL10n(context);
    return EntityBodyResolveResult(
      body: l10n?.entityJournalPlaceholderBody ?? kEntityJournalPlaceholderBody,
      usedPlaceholder: true,
    );
  }

  static Future<EntityDetailSaveOutcome> persist({
    required String vaultPath,
    required UserCatalogEntity entityDraft,
    required EntityJournalEntry? existingJournal,
    required String body,
    required List<String> tags,
    required String posterPath,
    UserCatalogPort? userCatalog,
    EntityVaultStore? vaultStore,
  }) async {
    final store = vaultStore ?? EntityVaultStore();
    final EntityJournalEntry saved;
    if (existingJournal == null) {
      saved = await store.saveCatalogEntity(
        vaultPath: vaultPath,
        entity: entityDraft,
        body: body,
      );
    } else {
      saved = await store.updateEntry(
        entry: existingJournal,
        body: body,
        title: entityDraft.title,
        aliases: entityDraft.aliases,
        tags: tags,
        posterPath: posterPath,
        vaultPath: vaultPath,
      );
    }

    var mirrored = entityDraft;
    if (userCatalog != null) {
      mirrored = await EntityArchiveService.syncCatalogFromJournal(
        draft: entityDraft,
        entry: saved,
        userCatalog: userCatalog,
      );
    }

    return EntityDetailSaveOutcome(mirrored: mirrored, saved: saved);
  }

  static Future<bool> deleteFromVault({
    required EntityJournalEntry entry,
    required UserCatalogPort userCatalog,
    EntityVaultStore? vaultStore,
  }) => EntityArchiveService.deleteArchivedEntity(
    entry: entry,
    userCatalog: userCatalog,
    vaultStore: vaultStore,
  );

  static String saveSuccessMessage(
    BuildContext context,
    UserCatalogEntity entity,
  ) {
    final l10n = lookupAppL10n(context);
    return l10n != null
        ? l10n.entityJournalSaveSuccess(entity.title)
        : '"${entity.title}" entity journal을 저장했습니다.';
  }

  static String? vaultRequiredSnack(
    BuildContext context, {
    required bool silent,
  }) {
    if (silent) return null;
    final l10n = lookupAppL10n(context);
    return l10n?.errorVaultRequired ?? '볼트를 먼저 연결해 주세요.';
  }

  static String? emptyBodySnack(BuildContext context, {required bool silent}) {
    if (silent) return null;
    final l10n = lookupAppL10n(context);
    return l10n?.errorEmptyBody ?? '본문을 입력해 주세요.';
  }
}
