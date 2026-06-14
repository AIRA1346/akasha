import 'package:flutter/material.dart';

/// 로컬 사전 캐시(registry_cache) 삭제 확인
Future<bool?> showClearRegistryCacheConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('사전 캐시 삭제'),
      content: const Text(
        '디스크에 저장된 사전 캐시(registry_cache)를 삭제합니다.\n'
        '앱 번들에 포함된 사전으로 다시 시작합니다.\n\n'
        '네트워크 동기화 기록은 유지됩니다.\n'
        '다음 동기화 시 CDN 데이터를 다시 받습니다.',
      ),
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
}
