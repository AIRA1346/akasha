import 'package:flutter/material.dart';

/// 작품 삭제 확인 다이얼로그
Future<bool> showDetailDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required bool hasVault,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('🗑️ 작품 삭제'),
      content: Text(
        hasVault
            ? '"$title" 작품을 아카이브에서 삭제할까요?\n로컬 볼트의 .md 파일이 영구 삭제됩니다.'
            : '"$title" 작품을 목록에서 제거할까요?\n(데모 모드 — 볼트 연동 시 .md 파일이 삭제됩니다)',
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
  return confirmed == true;
}
