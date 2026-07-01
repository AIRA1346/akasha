import 'package:flutter/material.dart';
import '../../../../utils/app_l10n.dart';

enum WorkbenchCloseTabChoice { cancel, discard, saveAndClose }

/// 미저장 작품 탭 닫기 확인
Future<WorkbenchCloseTabChoice?> showWorkbenchCloseTabDialog(
  BuildContext context, {
  required String title,
  required bool canSave,
}) {
  return showDialog<WorkbenchCloseTabChoice>(
    context: context,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      return AlertDialog(
        title: Text(l10n?.workbenchCloseTabDialogTitle ?? '미저장 변경'),
        content: Text(
          canSave
              ? (l10n != null
                    ? l10n.workbenchCloseTabMessageWithTitle(title)
                    : '"$title"에 저장하지 않은 변경이 있습니다.')
              : (l10n != null
                    ? l10n.workbenchCloseTabMessageWithTitleNoSave(title)
                    : '"$title"에 저장하지 않은 변경이 있습니다.\n다른 탭이므로 저장하려면 먼저 해당 작품을 선택하세요.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, WorkbenchCloseTabChoice.cancel),
            child: Text(l10n?.actionCancel ?? '취소'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, WorkbenchCloseTabChoice.discard),
            child: Text(l10n?.workbenchCloseTabDialogDiscard ?? '저장 안 함'),
          ),
          if (canSave)
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, WorkbenchCloseTabChoice.saveAndClose),
              child: Text(
                l10n?.workbenchCloseTabDialogSaveAndClose ?? '저장 후 닫기',
              ),
            ),
        ],
      );
    },
  );
}
