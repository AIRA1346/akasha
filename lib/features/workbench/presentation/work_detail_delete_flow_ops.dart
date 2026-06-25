import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import 'work_detail_delete_ops.dart';

/// Work md 삭제 플로우 결과.
sealed class WorkDetailDeleteFlowResult {
  const WorkDetailDeleteFlowResult();
}

class WorkDetailDeleteBlocked extends WorkDetailDeleteFlowResult {
  const WorkDetailDeleteBlocked(this.message);

  final String message;
}

class WorkDetailDeleteCancelled extends WorkDetailDeleteFlowResult {
  const WorkDetailDeleteCancelled();
}

class WorkDetailDeleteSucceeded extends WorkDetailDeleteFlowResult {
  const WorkDetailDeleteSucceeded(this.displayTitle);

  final String displayTitle;
}

class WorkDetailDeleteFailed extends WorkDetailDeleteFlowResult {
  const WorkDetailDeleteFailed(this.message);

  final String message;
}

/// WorkDetailWorkspace — 삭제 확인·대기·실행.
abstract final class WorkDetailDeleteFlowOps {
  static Future<WorkDetailDeleteFlowResult> run({
    required BuildContext context,
    required bool isSaving,
    required bool isArchivedInVault,
    required String displayTitle,
    required bool hasUnsavedChanges,
    required AkashaItem item,
    required Future<void> Function() waitWhileSaving,
    required Future<void> Function() onConfirmed,
  }) async {
    if (isSaving) {
      return const WorkDetailDeleteBlocked('');
    }
    if (!isArchivedInVault) {
      return const WorkDetailDeleteBlocked('삭제할 md 파일이 없습니다.');
    }

    final confirmed = await WorkDetailDeleteOps.confirmDelete(
      context,
      displayTitle: displayTitle,
      hasUnsavedChanges: hasUnsavedChanges,
    );
    if (!confirmed) {
      return const WorkDetailDeleteCancelled();
    }

    await waitWhileSaving();

    await onConfirmed();

    final deleted = await WorkDetailDeleteOps.deleteFromVault(item);
    if (deleted) {
      return WorkDetailDeleteSucceeded(displayTitle);
    }
    return const WorkDetailDeleteFailed('삭제할 파일을 찾지 못했습니다.');
  }

  static void handleResult({
    required WorkDetailDeleteFlowResult result,
    required void Function(String message) showSnack,
    required VoidCallback onDeleted,
    required VoidCallback restorePersist,
  }) {
    switch (result) {
      case WorkDetailDeleteBlocked(:final message):
        if (message.isNotEmpty) showSnack(message);
      case WorkDetailDeleteCancelled():
        return;
      case WorkDetailDeleteSucceeded(:final displayTitle):
        showSnack('"$displayTitle" md 파일을 삭제했습니다.');
        onDeleted();
      case WorkDetailDeleteFailed(:final message):
        restorePersist();
        showSnack(message);
    }
  }
}
