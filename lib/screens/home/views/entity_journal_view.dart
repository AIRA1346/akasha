import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/file_service.dart';
import '../../../utils/entity_body_preview.dart';
import '../dialogs/add_catalog_entity_dialog.dart';
import '../dialogs/entity_journal_dialog.dart';

/// Wave 4.1 — entity journal (`vault/entities/`) 시간순 목록.
class EntityJournalView extends StatefulWidget {
  const EntityJournalView({
    super.key,
    required this.userCatalog,
    required this.linkIndex,
    required this.vaultItems,
    required this.onOpenWork,
    this.reloadToken = 0,
  });

  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item) onOpenWork;
  final int reloadToken;

  @override
  State<EntityJournalView> createState() => _EntityJournalViewState();
}

class _EntityJournalViewState extends State<EntityJournalView> {
  final _loader = const EntityVaultLoader();
  List<EntityJournalEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
    widget.userCatalog.onChanged.listen((_) {
      if (mounted) _reload();
    });
  }

  @override
  void didUpdateWidget(covariant EntityJournalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await widget.userCatalog.load();
    final path = AkashaFileService().vaultPath;
    final entries = await _loader.loadFromVault(path);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  UserCatalogEntity? _catalogFor(EntityJournalEntry entry) {
    for (final entity in widget.userCatalog.all) {
      if (entity.entityId == entry.entityId) return entity;
    }
    return null;
  }

  Future<void> _openDetail(EntityJournalEntry entry) async {
    final catalog = _catalogFor(entry);
    if (catalog == null) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(entry.title),
          content: SelectableText(entry.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
      return;
    }

    await showEntityJournalDialog(
      context,
      entity: catalog,
      entry: entry,
      linkIndex: widget.linkIndex,
      userCatalog: widget.userCatalog,
      vaultItems: widget.vaultItems,
      onOpenWork: widget.onOpenWork,
    );
    if (mounted) await _reload();
  }

  static String _formatWhen(DateTime at) {
    final local = at.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }


  @override
  Widget build(BuildContext context) {
    if (AkashaFileService().vaultPath == null) {
      return const Center(
        child: Text('볼트를 연결하면 entity journal을 볼 수 있습니다.'),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              '아직 entity journal이 없습니다.',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Fusion → 직접 추가로 Person · Concept · Event를 아카이브하세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Text(
                'Entity journal (${_entries.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '새로고침',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Material(
                color: const Color(0xFF252535),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openDetail(entry),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              entityTypeBadgeLabel(entry.entityType),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.tealAccent,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatWhen(entry.addedAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          EntityBodyPreview.format(entry.body),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
