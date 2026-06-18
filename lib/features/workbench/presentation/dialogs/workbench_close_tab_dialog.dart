import 'package:flutter/material.dart';

enum WorkbenchCloseTabChoice {
  cancel,
  discard,
  saveAndClose,
}

/// 미저장 작품 탭 닫기 확인
Future<WorkbenchCloseTabChoice?> showWorkbenchCloseTabDialog(
  BuildContext context, {
  required String title,
  required bool canSave,
}) {
  return showDialog<WorkbenchCloseTabChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('미저장 변경'),
      content: Text(
        canSave
            ? '"$title"에 저장하지 않은 변경이 있습니다.'
            : '"$title"에 저장하지 않은 변경이 있습니다.\n'
                '다른 탭이므로 저장하려면 먼저 해당 작품을 선택하세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, WorkbenchCloseTabChoice.cancel),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, WorkbenchCloseTabChoice.discard),
          child: const Text('저장 안 함'),
        ),
        if (canSave)
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, WorkbenchCloseTabChoice.saveAndClose),
            child: const Text('저장 후 닫기'),
          ),
      ],
    ),
  );
}
