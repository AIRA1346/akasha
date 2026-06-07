import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';
import '../../../services/markdown_parser.dart';

/// AI 마크다운 클립보드 가져오기 다이얼로그
Future<void> showClipboardImportDialog(
  BuildContext context, {
  required String initialText,
  required List<AkashaItem> existingItems,
  required Future<void> Function(AkashaItem item) onItemImported,
}) async {
  final ctrl = TextEditingController(text: initialText);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('🤖 AI 마크다운 가져오기'),
      content: SizedBox(
        width: 500,
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI가 생성한 마크다운 텍스트를 여기에 붙여넣으세요. 파싱하여 작품 목록에 추가합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '---\ntitle: "작품명"\n...',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
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
          onPressed: () async {
            final content = ctrl.text.trim();
            if (content.isEmpty) return;
            try {
              final item = MarkdownParser.deserialize(content, '이름 없는 작품');
              final exists = existingItems.any(
                (e) =>
                    (item.workId.isNotEmpty && e.workId == item.workId) ||
                    (e.title == item.title && e.category == item.category),
              );
              if (exists) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('"${item.title}"은(는) 이미 아카이브에 있습니다.'),
                  ),
                );
                return;
              }

              final service = AkashaFileService();
              await service.saveItem(item);
              if (ctx.mounted) Navigator.pop(ctx);
              await onItemImported(item);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '"${item.title}" 추가됨 (work_id: ${item.workId})',
                    ),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('파싱에 실패했습니다: $e')),
              );
            }
          },
          child: const Text('파싱 및 가져오기'),
        ),
      ],
    ),
  );
}
