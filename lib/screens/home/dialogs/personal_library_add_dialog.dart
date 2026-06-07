import 'package:flutter/material.dart';

import '../../../models/personal_library_config.dart';

/// 나만의 서재 추가 — 이름만 입력 (v1: archived 규칙 고정)
Future<PersonalLibraryConfig?> showPersonalLibraryAddDialog(
  BuildContext context,
) async {
  final nameCtrl = TextEditingController();

  final result = await showDialog<PersonalLibraryConfig>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('➕ 나만의 서재 추가'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '서재 이름',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '예: 인생 명작, 감상 완료 목록…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'v1: 볼트 아카이브 작품만 표시됩니다. (전 매체)',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
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
            final id =
                'personal_${DateTime.now().millisecondsSinceEpoch}';
            Navigator.pop(
              ctx,
              PersonalLibraryConfig(id: id, name: name),
            );
          },
          child: const Text('추가'),
        ),
      ],
    ),
  );

  nameCtrl.dispose();
  return result;
}
