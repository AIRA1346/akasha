import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/markdown_parser.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

/// AI 마크다운 클립보드 가져오기 다이얼로그
Future<void> showClipboardImportDialog(
  BuildContext context, {
  required String initialText,
  required List<AkashaItem> existingItems,
  required Future<void> Function(AkashaItem item) onImport,
}) async {
  final l10n = lookupAppL10n(context);
  final ctrl = TextEditingController(text: initialText);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.clipboardImportTitle ?? '🤖 AI 마크다운 가져오기'),
      content: SizedBox(
        width: 500,
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.clipboardImportDescription ??
                  'AI가 생성한 마크다운 텍스트를 여기에 붙여넣으세요. 파싱하여 작품 목록에 추가합니다.',
              style: AkashaTypography.body,
            ),
            SizedBox(height: AkashaSpacing.sm),
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '---\ntitle: "Title"\n...',
                ),
                style: AkashaTypography.body.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n?.actionCancel ?? '취소'),
        ),
        FilledButton(
          onPressed: () async {
            final content = ctrl.text.trim();
            if (content.isEmpty) return;
            try {
              final defaultTitle = l10n?.untitledWork ?? '이름 없는 작품';
              final item = MarkdownParser.deserialize(content, defaultTitle);
              final exists = existingItems.any(
                (e) =>
                    (item.workId.isNotEmpty && e.workId == item.workId) ||
                    (e.title == item.title && e.category == item.category),
              );
              if (exists) {
                final msg = l10n != null
                    ? l10n.clipboardImportAlreadyExists(item.title)
                    : '"${item.title}"은(는) 이미 아카이브에 있습니다.';
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(msg)));
                return;
              }

              if (ctx.mounted) Navigator.pop(ctx);
              await onImport(item);
              if (context.mounted) {
                final msg = l10n != null
                    ? l10n.clipboardImportAdded(item.title, item.workId)
                    : '"${item.title}" 추가됨 (work_id: ${item.workId})';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            } catch (e) {
              if (ctx.mounted) {
                final msg = l10n != null
                    ? l10n.clipboardImportParseFailed(e.toString())
                    : '파싱에 실패했습니다: $e';
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            }
          },
          child: Text(l10n?.actionParseAndImport ?? '파싱 및 가져오기'),
        ),
      ],
    ),
  );
}
