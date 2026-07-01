import 'package:flutter/material.dart';

import '../../../utils/app_l10n.dart';

/// 나만의 서재 삭제 확인.
Future<bool?> showDeletePersonalLibraryConfirmDialog(
  BuildContext context, {
  required String libraryName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      return AlertDialog(
        title: Text(l10n?.personalLibraryDeleteTitle ?? '나만의 서재 삭제'),
        content: Text(
          l10n != null
              ? l10n.personalLibraryDeleteMessage(libraryName)
              : '「$libraryName」 서재를 삭제할까요?\n아카이브된 작품과 md 파일은 삭제되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.actionCancel ?? '취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.actionDelete ?? '삭제'),
          ),
        ],
      );
    },
  );
}
