import 'package:flutter/material.dart';

import '../../../core/archiving/timeline_entry.dart';
import '../../../data/adapters/vault_archive_record_adapter.dart';
import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';
import '../../../services/timeline_vault_loader.dart';

/// Phase 4.4 — Timeline entry 시간순 목록.
class TimelineView extends StatefulWidget {
  const TimelineView({
    super.key,
    required this.vaultItems,
    required this.onOpenWork,
    required this.onNewEntry,
    this.reloadToken = 0,
  });

  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item) onOpenWork;
  final VoidCallback onNewEntry;
  final int reloadToken;

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final _loader = const TimelineVaultLoader();
  final _adapter = VaultArchiveRecordAdapter();
  List<TimelineEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final path = AkashaFileService().vaultPath;
    final entries = await _loader.loadFromVault(path);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String? _workTitleFor(String? entityId) {
    if (entityId == null || entityId.isEmpty) return null;
    for (final item in widget.vaultItems) {
      if (item.workId == entityId) return item.title;
    }
    return entityId;
  }

  Future<void> _openDetail(TimelineEntry entry) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatWhen(entry.occurredAt),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                if (entry.entityId != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      for (final item in widget.vaultItems) {
                        if (item.workId == entry.entityId) {
                          Navigator.pop(ctx);
                          widget.onOpenWork(item);
                          return;
                        }
                      }
                    },
                    child: Text(
                      '🔗 ${_workTitleFor(entry.entityId)}',
                      style: const TextStyle(color: Colors.tealAccent),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SelectableText(entry.body),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: ctx,
                builder: (c) => AlertDialog(
                  title: const Text('삭제'),
                  content: const Text('이 타임라인 기록을 삭제할까요?'),
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
            child: const Text('닫기'),
          ),
        ],
      ),
    );

    if (deleted == true) {
      await _adapter.delete(entry.recordId);
      if (mounted) await _reload();
    }
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

  static String _preview(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (AkashaFileService().vaultPath == null) {
      return const Center(
        child: Text('볼트를 연결하면 타임라인을 볼 수 있습니다.'),
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
            const Icon(Icons.timeline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('아직 타임라인 기록이 없습니다.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onNewEntry,
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('첫 기록 작성'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.timeline, size: 20, color: Colors.tealAccent),
              const SizedBox(width: 8),
              Text(
                '타임라인 (${_entries.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '새 기록',
                onPressed: widget.onNewEntry,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: '새로고침',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                            Expanded(
                              child: Text(
                                entry.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _formatWhen(entry.occurredAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        if (entry.entityId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🔗 ${_workTitleFor(entry.entityId)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.tealAccent,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          _preview(entry.body),
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
