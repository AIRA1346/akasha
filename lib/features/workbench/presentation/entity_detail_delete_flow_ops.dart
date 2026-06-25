import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../services/entity_vault_store.dart';
import 'entity_detail_delete_ops.dart';

/// Entity journal 삭제 플로우 결과.
sealed class EntityDetailDeleteFlowResult {
  const EntityDetailDeleteFlowResult();
}

class EntityDetailDeleteBlocked extends EntityDetailDeleteFlowResult {
  const EntityDetailDeleteBlocked(this.message);

  final String message;
}

class EntityDetailDeleteCancelled extends EntityDetailDeleteFlowResult {
  const EntityDetailDeleteCancelled();
}

class EntityDetailDeleteSucceeded extends EntityDetailDeleteFlowResult {
  const EntityDetailDeleteSucceeded(this.title);

  final String title;
}

class EntityDetailDeleteFailed extends EntityDetailDeleteFlowResult {
  const EntityDetailDeleteFailed(this.message);

  final String message;
}

/// EntityDetailWorkspace — journal 삭제 확인·실행.
abstract final class EntityDetailDeleteFlowOps {
  static Future<EntityDetailDeleteFlowResult> run({
    required BuildContext context,
    required bool isSaving,
    required EntityJournalEntry? journal,
    required String title,
    required UserCatalogPort? catalog,
    required EntityVaultStore vaultStore,
    required Future<void> Function() onConfirmed,
  }) async {
    if (journal == null || isSaving) {
      return const EntityDetailDeleteBlocked('');
    }

    final confirmed = await EntityDetailDeleteOps.confirmDelete(
      context,
      title: title,
    );
    if (!confirmed) {
      return const EntityDetailDeleteCancelled();
    }

    if (catalog == null) {
      return const EntityDetailDeleteBlocked('catalog 연결이 필요합니다.');
    }

    await onConfirmed();

    final deleted = await EntityDetailDeleteOps.deleteJournal(
      entry: journal,
      userCatalog: catalog,
      vaultStore: vaultStore,
    );
    if (deleted) {
      return EntityDetailDeleteSucceeded(title);
    }
    return const EntityDetailDeleteFailed('삭제할 파일을 찾지 못했습니다.');
  }
}
