import 'package:flutter/material.dart';

/// 감상문 편집 다이얼로그
Future<String?> showEditReviewDialog(
  BuildContext context, {
  required String initialReview,
}) async {
  final ctrl = TextEditingController(text: initialReview);

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('📖 감상문 편집'),
      content: SizedBox(
        width: 500,
        child: TextField(
          controller: ctrl,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: '이 작품에 대한 감상을 자유롭게 적어주세요...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: const Text('저장'),
        ),
      ],
    ),
  );
}
