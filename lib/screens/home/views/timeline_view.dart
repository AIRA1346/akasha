import 'package:flutter/material.dart';

import '../../../core/archiving/archive_record.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/archiving/timeline_entry.dart';
import '../../../data/adapters/vault_archive_record_adapter.dart';
import '../../../models/akasha_item.dart';
import '../../../services/timeline_vault_loader.dart';
import '../../../services/vault_recovery_write_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

/// Phase 4.4 — Timeline entry 시간순 목록.
class TimelineView extends StatefulWidget {
  const TimelineView({
    super.key,
    required this.vaultPath,
    required this.vaultItems,
    required this.onOpenWork,
    required this.onNewEntry,
    this.reloadToken = 0,
  });

  final String? vaultPath;
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
    final path = widget.vaultPath;
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
    final titleCtrl = TextEditingController(text: entry.title);
    final bodyCtrl = TextEditingController(text: entry.body);
    var editing = false;

    final deleted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final l10n = lookupAppL10n(ctx);
          return AlertDialog(
            title: Text(
              editing ? (l10n?.actionEditTimeline ?? '타임라인 편집') : entry.title,
            ),
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
                        color: AkashaColors.textMuted,
                      ),
                    ),
                    if (entry.entityId != null && !editing) ...[
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
                    if (editing) ...[
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: l10n?.labelTitle ?? '제목',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: bodyCtrl,
                        minLines: 6,
                        maxLines: 12,
                        decoration: InputDecoration(
                          labelText: l10n?.labelBody ?? '본문',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ] else
                      SelectableText(entry.body),
                  ],
                ),
              ),
            ),
            actions: [
              if (!editing)
                TextButton(
                  onPressed: () => setLocal(() => editing = true),
                  child: Text(l10n?.actionEdit ?? '편집'),
                ),
              if (editing)
                FilledButton(
                  onPressed: () async {
                    final body = bodyCtrl.text.trim();
                    if (body.isEmpty) return;
                    var title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      title = body.length <= 40
                          ? body
                          : '${body.substring(0, 40)}…';
                    }
                    EntityAnchor? entity;
                    final entityId = entry.entityId?.trim();
                    if (entityId != null && entityId.isNotEmpty) {
                      entity = EntityAnchor(
                        entityId: entityId,
                        type: EntityAnchor.typeForEntityId(entityId),
                      );
                    }
                    try {
                      await _adapter.save(
                      ArchiveRecord(
                        recordId: entry.recordId,
                        kind: RecordKind.timelineEntry,
                        title: title,
                        timeAnchor: entry.occurredAt,
                        storagePath: entry.storagePath,
                        entity: entity,
                        openedRevision: entry.openedRevision,
                      ),
                      bodyMarkdown: body,
                    );
                      if (ctx.mounted) Navigator.pop(ctx);
                    } on VaultWriteConflictException {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '외부 변경을 감지해 저장하지 않았습니다. 편집본은 복구 충돌 보관함에 남겼습니다.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(l10n?.actionSave ?? '저장'),
                ),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (c) {
                      final l10nDelete = lookupAppL10n(c);
                      return AlertDialog(
                        title: Text(l10nDelete?.actionDelete ?? '삭제'),
                        content: Text(
                          l10nDelete?.confirmDeleteTimeline ??
                              '이 타임라인 기록을 삭제할까요?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text(l10nDelete?.actionCancel ?? '취소'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(l10nDelete?.actionDelete ?? '삭제'),
                          ),
                        ],
                      );
                    },
                  );
                  if (ok == true && ctx.mounted) Navigator.pop(ctx, true);
                },
                child: Text(
                  l10n?.actionDelete ?? '삭제',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  editing
                      ? (l10n?.actionCancel ?? '취소')
                      : (l10n?.actionClose ?? '닫기'),
                ),
              ),
            ],
          );
        },
      ),
    );

    titleCtrl.dispose();
    bodyCtrl.dispose();

    if (deleted == true) {
      await _adapter.delete(entry.recordId);
      if (mounted) await _reload();
    } else if (deleted == null && mounted) {
      await _reload();
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
    final l10n = lookupAppL10n(context);

    if (widget.vaultPath == null) {
      return Center(
        child: Text(
          l10n?.helpTimelineConnectVault ?? '볼트를 연결하면 타임라인을 볼 수 있습니다.',
        ),
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
            const Icon(Icons.timeline, size: 48, color: AkashaColors.textMuted),
            const SizedBox(height: 12),
            Text(l10n?.helpTimelineEmpty ?? '아직 타임라인 기록이 없습니다.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onNewEntry,
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l10n?.actionWriteFirstRecord ?? '첫 기록 작성'),
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
                l10n != null
                    ? l10n.countTimelineRecords(_entries.length)
                    : '타임라인 (${_entries.length})',
                style: AkashaTypography.dashboardPanelTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n?.tooltipNewRecord ?? '새 기록',
                onPressed: widget.onNewEntry,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: l10n?.tooltipRefresh ?? '새로고침',
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
                color: AkashaColors.workbenchListTile,
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
                              style: AkashaTypography.bodySecondary.copyWith(
                                color: AkashaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (entry.entityId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🔗 ${_workTitleFor(entry.entityId)}',
                            style: AkashaTypography.compactLabel.copyWith(
                              color: Colors.tealAccent,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          _preview(entry.body),
                          style: AkashaTypography.listItemTitle.copyWith(
                            color: AkashaColors.textSecondary,
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
