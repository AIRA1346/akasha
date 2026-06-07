import 'package:flutter/material.dart';

/// 명대사 추가 다이얼로그
Future<String?> showAddQuoteDialog(BuildContext context) async {
  final ctrl = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('🎬 명대사 추가'),
      content: TextField(
        controller: ctrl,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: '"대사 내용" — 캐릭터 이름 / 상황 설명',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final text = ctrl.text.trim();
            if (text.isNotEmpty) Navigator.pop(ctx, text);
          },
          child: const Text('추가'),
        ),
      ],
    ),
  );
}
