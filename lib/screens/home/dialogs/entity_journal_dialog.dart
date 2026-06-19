import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import 'add_catalog_entity_dialog.dart';

/// Entity catalog + journal 상세 · 편집 · 삭제 — Wave 4.1.
///
/// 반환: `true` 삭제됨 · `false` 저장/생성됨 · `null` 변경 없음.
Future<bool?> showEntityJournalDialog(
  BuildContext context, {
  required UserCatalogEntity entity,
  EntityJournalEntry? entry,
}) async {
  final vaultPath = AkashaFileService().vaultPath;
  if (vaultPath == null || vaultPath.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('볼트를 먼저 연결해 주세요.')),
      );
    }
    return null;
  }

  const store = EntityVaultStore();
  var current = entry;
  var creating = current == null;

  final bodyCtrl = TextEditingController(text: current?.body ?? '');
  var editing = creating;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final badge = entityTypeBadgeLabel(entity.anchorType);
        final hasJournal = current != null;

        return AlertDialog(
          title: Text(editing ? 'Entity journal 편집' : entity.title),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$badge · ${entity.entityId}',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  if (entity.aliases.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '별칭: ${entity.aliases.join(', ')}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                  if (hasJournal && !creating) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatWhen(current!.addedAt),
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (editing || creating)
                    TextField(
                      controller: bodyCtrl,
                      minLines: 6,
                      maxLines: 12,
                      autofocus: creating,
                      decoration: const InputDecoration(
                        labelText: 'journal 본문',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    )
                  else if (hasJournal)
                    SelectableText(current!.body)
                  else
                    Text(
                      '아직 entity journal이 없습니다.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (!hasJournal && !creating)
              FilledButton(
                onPressed: () => setLocal(() {
                  creating = true;
                  editing = true;
                }),
                child: const Text('journal 생성'),
              ),
            if (hasJournal && !editing && !creating)
              TextButton(
                onPressed: () => setLocal(() => editing = true),
                child: const Text('편집'),
              ),
            if (editing || creating)
              FilledButton(
                onPressed: () async {
                  final body = bodyCtrl.text.trim();
                  if (body.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('본문을 입력해 주세요.')),
                    );
                    return;
                  }

                  if (creating || current == null) {
                    current = await store.saveCatalogEntity(
                      vaultPath: vaultPath,
                      entity: entity,
                      body: body,
                    );
                  } else {
                    current = await store.updateEntry(
                      entry: current!,
                      body: body,
                      title: entity.title,
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx, false);
                },
                child: Text(creating ? '생성' : '저장'),
              ),
            if (hasJournal && !creating)
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('삭제'),
                      content: const Text('이 entity journal을 삭제할까요?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(editing || creating ? '취소' : '닫기'),
            ),
          ],
        );
      },
    ),
  );

  bodyCtrl.dispose();

  if (result == true && current != null) {
    await store.deleteEntry(current!.storagePath);
  }

  return result;
}

String _formatWhen(DateTime at) {
  final local = at.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}
