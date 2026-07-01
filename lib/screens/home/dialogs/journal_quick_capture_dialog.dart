import 'package:flutter/material.dart';

import '../../../utils/app_l10n.dart';

/// Wave 3 — freeform journal quick capture 입력.
class JournalQuickCaptureResult {
  const JournalQuickCaptureResult({required this.title, required this.body});

  final String title;
  final String body;
}

Future<JournalQuickCaptureResult?> showJournalQuickCaptureDialog(
  BuildContext context,
) async {
  final l10n = lookupAppL10n(context);
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  final result = await showDialog<JournalQuickCaptureResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.journalQuickCaptureTitle ?? '메모 기록'),
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
                decoration: InputDecoration(
                  labelText: l10n?.labelBody ?? '본문',
                  hintText: l10n?.hintJournalBody ?? '아이디어, 메모, 생각…',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.labelTitleOptional ?? '제목 (선택)',
                  hintText: l10n?.hintTitleAutoFill ?? '비우면 본문 앞부분을 사용합니다',
                  border: const OutlineInputBorder(),
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
          child: Text(l10n?.actionCancel ?? '취소'),
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
          child: Text(l10n?.actionSave ?? '저장'),
        ),
      ],
    ),
  );

  titleCtrl.dispose();
  bodyCtrl.dispose();
  return result;
}
