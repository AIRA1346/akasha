import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';
import '../../../services/markdown_parser.dart';
/// Case B — md 없을 때 아카이브 생성 (deprecated: `WorkLibraryPanel` + `ensureVaultMd`)
@Deprecated('Use WorkLibraryPanel with LibraryMembershipApply.ensureVaultMd')
Future<bool> showArchiveThenAddDialog(
  BuildContext context, {
  required AkashaItem draft,
}) async {
  final titleCtrl = TextEditingController(text: draft.title);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('기록 만들고 담기'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.category.label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '내 상태: ${draft.myStatusLabel}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '작품 상태: ${draft.workStatusLabel}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () async {
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;

            final service = AkashaFileService();
            if (service.vaultPath == null) {
              if (ctx.mounted) Navigator.pop(ctx, false);
              return;
            }

            draft.title = title;
            draft.workId = MarkdownParser.ensureWorkId(draft);
            try {
              await service.saveItem(draft);
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('저장 실패: $e')),
                );
              }
            }
          },
          child: const Text('기록 만들고 담기'),
        ),
      ],
    ),
  );

  titleCtrl.dispose();
  return result ?? false;
}
