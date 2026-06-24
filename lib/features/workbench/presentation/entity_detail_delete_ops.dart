import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../services/entity_vault_store.dart';
import 'entity_detail_archive_ops.dart';

/// Entity journal 삭제 확인·실행.
abstract final class EntityDetailDeleteOps {
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('「$title」 entity journal을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> deleteJournal({
    required EntityJournalEntry entry,
    required UserCatalogPort userCatalog,
    required EntityVaultStore vaultStore,
  }) =>
      EntityDetailArchiveOps.deleteFromVault(
        entry: entry,
        userCatalog: userCatalog,
        vaultStore: vaultStore,
      );
}
