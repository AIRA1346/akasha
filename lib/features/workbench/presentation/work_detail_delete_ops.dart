import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../screens/detail/dialogs/detail_delete_dialog.dart';
import 'work_detail_archive_ops.dart';

/// Work md 삭제 확인·실행.
abstract final class WorkDetailDeleteOps {
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String displayTitle,
    required bool hasUnsavedChanges,
  }) =>
      showDetailDeleteConfirmDialog(
        context,
        title: displayTitle,
        hasVault: true,
        hasUnsavedChanges: hasUnsavedChanges,
      );

  static Future<bool> deleteFromVault(AkashaItem item) =>
      WorkDetailArchiveOps.deleteFromVault(item);
}
