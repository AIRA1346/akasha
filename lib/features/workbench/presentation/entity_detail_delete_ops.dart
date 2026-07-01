import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../services/entity_vault_store.dart';
import 'entity_detail_archive_ops.dart';
import '../../../utils/app_l10n.dart';

/// Entity journal 삭제 확인·실행.
abstract final class EntityDetailDeleteOps {
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = lookupAppL10n(ctx);
        return AlertDialog(
          title: Text(l10n?.actionDelete ?? '삭제'),
          content: Text(
            l10n != null
                ? l10n.entityJournalDeleteConfirm(title)
                : '「$title」 entity journal을 삭제할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n?.actionCancel ?? '취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n?.actionDelete ?? '삭제'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  static Future<bool> deleteJournal({
    required EntityJournalEntry entry,
    required UserCatalogPort userCatalog,
    required EntityVaultStore vaultStore,
  }) => EntityDetailArchiveOps.deleteFromVault(
    entry: entry,
    userCatalog: userCatalog,
    vaultStore: vaultStore,
  );
}
