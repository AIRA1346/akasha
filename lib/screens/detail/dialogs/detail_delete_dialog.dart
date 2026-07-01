import 'package:flutter/material.dart';

import '../../../utils/app_l10n.dart';

/// 작품 삭제 확인 다이얼로그
Future<bool> showDetailDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required bool hasVault,
  bool hasUnsavedChanges = false,
}) async {
  final l10n = lookupAppL10n(context);
  final unsavedNote = hasUnsavedChanges
      ? (l10n?.deleteUnsavedWarning ?? '\n저장하지 않은 편집 내용도 함께 사라집니다.')
      : '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.detailDeleteTitle ?? '🗑️ 작품 삭제'),
      content: Text(
        hasVault
            ? (l10n != null
                  ? l10n.detailDeleteConfirmVault(title, unsavedNote)
                  : '"$title" 작품을 아카이브에서 삭제할까요?\n'
                        '로컬 볼트의 .md 파일이 영구 삭제됩니다.$unsavedNote\n'
                        '탐색·사전 목록에서는 사라지지 않으며, 자동 아카이빙 설정 시 .md가 다시 생성될 수 있습니다.')
            : (l10n != null
                  ? l10n.detailDeleteConfirmNoVault(title, unsavedNote)
                  : '"$title" 작품을 목록에서 제거할까요?\n'
                        '(데모 모드 — 볼트 연동 시 .md 파일이 삭제됩니다)$unsavedNote'),
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
    ),
  );
  return confirmed == true;
}
