import 'package:flutter/material.dart';

/// 대시보드 서재 삭제 확인
Future<bool?> showDeleteDashboardConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('대시보드 서재 삭제'),
      content: const Text(
        '이 대시보드를 삭제할까요?\n'
        '저장된 필터 설정도 함께 삭제되며, 볼트의 작품에는 영향을 주지 않습니다.',
      ),
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
