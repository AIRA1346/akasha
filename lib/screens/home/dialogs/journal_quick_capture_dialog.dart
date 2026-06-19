import 'package:flutter/material.dart';

/// Wave 3 — freeform journal quick capture 입력.
class JournalQuickCaptureResult {
  const JournalQuickCaptureResult({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

Future<JournalQuickCaptureResult?> showJournalQuickCaptureDialog(
  BuildContext context,
) async {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  final result = await showDialog<JournalQuickCaptureResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('메모 기록'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: bodyCtrl,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '본문',
                  hintText: '아이디어, 메모, 생각…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목 (선택)',
                  hintText: '비우면 본문 앞부분을 사용합니다',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final body = bodyCtrl.text.trim();
            if (body.isEmpty) return;
            var title = titleCtrl.text.trim();
            if (title.isEmpty) {
              title = body.length <= 40 ? body : '${body.substring(0, 40)}…';
            }
            Navigator.pop(
              ctx,
              JournalQuickCaptureResult(title: title, body: body),
            );
          },
          child: const Text('저장'),
        ),
      ],
    ),
  );

  titleCtrl.dispose();
  bodyCtrl.dispose();
  return result;
}
