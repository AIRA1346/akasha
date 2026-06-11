import 'package:flutter/material.dart';

/// curated 서재 생성 — 이름만 입력
Future<String?> showPersonalLibraryNameDialog(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('➕ 나만의 서재 추가'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '서재 이름',
            hintText: '예: 인생 명작, 읽을 예정 2026…',
            border: OutlineInputBorder(),
            isDense: true,
            helperText: '만든 뒤 작품을 담아 채웁니다. 필터는 설정에서 조정할 수 있습니다.',
            helperMaxLines: 2,
          ),
          onSubmitted: (v) {
            final name = v.trim();
            if (name.isNotEmpty) Navigator.pop(ctx, name);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx, name);
          },
          child: const Text('만들기'),
        ),
      ],
    ),
  );
  nameCtrl.dispose();
  return result;
}
