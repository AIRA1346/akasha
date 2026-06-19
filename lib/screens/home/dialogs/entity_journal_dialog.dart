import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../services/record_link_navigator.dart';
import 'add_catalog_entity_dialog.dart';

/// Entity catalog + journal 상세 · 편집 · 삭제 — Wave 4.1 / W5-3 incoming links.
///
/// 반환: `true` 삭제됨 · `false` 저장/생성됨 · `null` 변경 없음.
Future<bool?> showEntityJournalDialog(
  BuildContext context, {
  required UserCatalogEntity entity,
  EntityJournalEntry? entry,
  RecordLinkPort? linkIndex,
  UserCatalogPort? userCatalog,
  List<AkashaItem> vaultItems = const [],
  void Function(AkashaItem item)? onOpenWork,
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

  return showDialog<bool>(
    context: context,
    builder: (ctx) => _EntityJournalDialog(
      entity: entity,
      initialEntry: entry,
      vaultPath: vaultPath,
      linkIndex: linkIndex,
      userCatalog: userCatalog,
      vaultItems: vaultItems,
      onOpenWork: onOpenWork,
    ),
  );
}

class _EntityJournalDialog extends StatefulWidget {
  const _EntityJournalDialog({
    required this.entity,
    required this.initialEntry,
    required this.vaultPath,
    this.linkIndex,
    this.userCatalog,
    this.vaultItems = const [],
    this.onOpenWork,
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry? initialEntry;
  final String vaultPath;
  final RecordLinkPort? linkIndex;
  final UserCatalogPort? userCatalog;
  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item)? onOpenWork;

  @override
  State<_EntityJournalDialog> createState() => _EntityJournalDialogState();
}

class _EntityJournalDialogState extends State<_EntityJournalDialog> {
  static const _store = EntityVaultStore();

  EntityJournalEntry? _current;
  late final TextEditingController _bodyCtrl;
  var _creating = false;
  var _editing = false;
  List<String> _incomingPaths = const [];
  var _loadingIncoming = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialEntry;
    _creating = _current == null;
    _editing = _creating;
    _bodyCtrl = TextEditingController(text: _current?.body ?? '');
    _loadIncoming();
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIncoming() async {
    final index = widget.linkIndex;
    if (index == null) return;

    setState(() => _loadingIncoming = true);
    final paths = await index.incomingRecordPaths(widget.entity.entityId);
    if (!mounted) return;
    setState(() {
      _incomingPaths = paths;
      _loadingIncoming = false;
    });
  }

  bool get _hasJournal => _current != null;

  Future<void> _save() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본문을 입력해 주세요.')),
      );
      return;
    }

    if (_creating || _current == null) {
      _current = await _store.saveCatalogEntity(
        vaultPath: widget.vaultPath,
        entity: widget.entity,
        body: body,
      );
    } else {
      _current = await _store.updateEntry(
        entry: _current!,
        body: body,
        title: widget.entity.title,
      );
    }

    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
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
    if (ok == true && mounted) {
      if (_current != null) {
        await _store.deleteEntry(_current!.storagePath);
      }
      Navigator.pop(context, true);
    }
  }

  Future<void> _openIncoming(String path) async {
    final onOpenWork = widget.onOpenWork;
    final catalog = widget.userCatalog;
    if (onOpenWork == null || catalog == null) return;

    await RecordLinkNavigator.openRecordPath(
      context,
      storagePath: path,
      vaultItems: widget.vaultItems,
      userCatalog: catalog,
      onOpenWork: onOpenWork,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = entityTypeBadgeLabel(widget.entity.anchorType);

    return AlertDialog(
      title: Text(_editing ? 'Entity journal 편집' : widget.entity.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$badge · ${widget.entity.entityId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              if (widget.entity.aliases.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '별칭: ${widget.entity.aliases.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_hasJournal && !_creating) ...[
                const SizedBox(height: 8),
                Text(
                  _formatWhen(_current!.addedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
              if (!_editing && !_creating) ...[
                const SizedBox(height: 12),
                _IncomingLinksSection(
                  loading: _loadingIncoming,
                  paths: _incomingPaths,
                  onOpen: widget.onOpenWork != null ? _openIncoming : null,
                ),
              ],
              const SizedBox(height: 12),
              if (_editing || _creating)
                TextField(
                  controller: _bodyCtrl,
                  minLines: 6,
                  maxLines: 12,
                  autofocus: _creating,
                  decoration: const InputDecoration(
                    labelText: 'journal 본문',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                )
              else if (_hasJournal)
                SelectableText(_current!.body)
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
        if (!_hasJournal && !_creating)
          FilledButton(
            onPressed: () => setState(() {
              _creating = true;
              _editing = true;
            }),
            child: const Text('journal 생성'),
          ),
        if (_hasJournal && !_editing && !_creating)
          TextButton(
            onPressed: () => setState(() => _editing = true),
            child: const Text('편집'),
          ),
        if (_editing || _creating)
          FilledButton(
            onPressed: _save,
            child: Text(_creating ? '생성' : '저장'),
          ),
        if (_hasJournal && !_creating)
          TextButton(
            onPressed: _delete,
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_editing || _creating ? '취소' : '닫기'),
        ),
      ],
    );
  }
}

class _IncomingLinksSection extends StatelessWidget {
  const _IncomingLinksSection({
    required this.loading,
    required this.paths,
    this.onOpen,
  });

  final bool loading;
  final List<String> paths;
  final Future<void> Function(String path)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (paths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '링크한 Record (${paths.length})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.tealAccent,
          ),
        ),
        const SizedBox(height: 6),
        ...paths.map((path) {
          final label = p.basename(path);
          return Material(
            color: const Color(0xFF252535),
            borderRadius: BorderRadius.circular(6),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.link, size: 16),
              title: Text(label, style: const TextStyle(fontSize: 12)),
              subtitle: Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
              onTap: onOpen != null ? () => onOpen!(path) : null,
            ),
          );
        }),
      ],
    );
  }
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
