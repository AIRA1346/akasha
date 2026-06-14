import 'package:flutter/material.dart';

/// 나만의 서재 삭제 확인
Future<bool?> showDeletePersonalLibraryConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('나만의 서재 삭제'),
      content: const Text('이 서재를 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
