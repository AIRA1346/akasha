import 'package:flutter/material.dart';

import '../../../core/archiving/archive_record.dart';
import '../../../core/archiving/journal_entry.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../data/adapters/vault_archive_record_adapter.dart';
import '../../../services/journal_vault_loader.dart';
import '../../../services/vault_recovery_write_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

/// Wave 3 — freeform journal 시간순 목록.
class JournalView extends StatefulWidget {
  const JournalView({
    super.key,
    required this.vaultPath,
    required this.onNewEntry,
    this.reloadToken = 0,
  });

  final String? vaultPath;
  final VoidCallback onNewEntry;
  final int reloadToken;

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  final _loader = const JournalVaultLoader();
  final _adapter = VaultArchiveRecordAdapter();
  List<JournalEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant JournalView oldWidget) {
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

  Future<void> _openDetail(JournalEntry entry) async {
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
              editing ? (l10n?.actionEditMemo ?? '메모 편집') : entry.title,
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatWhen(entry.addedAt),
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AkashaColors.textMuted,
                      ),
                    ),
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
                    try {
                      await _adapter.save(
                      ArchiveRecord(
                        recordId: entry.recordId,
                        kind: RecordKind.freeformJournal,
                        title: title,
                        timeAnchor: entry.addedAt,
                        storagePath: entry.storagePath,
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
                          l10nDelete?.confirmDeleteMemo ?? '이 메모를 삭제할까요?',
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
        child: Text(l10n?.helpJournalConnectVault ?? '볼트를 연결하면 메모를 볼 수 있습니다.'),
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
            const Icon(
              Icons.note_alt_outlined,
              size: 48,
              color: AkashaColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(l10n?.helpJournalEmpty ?? '아직 메모가 없습니다.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onNewEntry,
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l10n?.actionWriteFirstMemo ?? '첫 메모 작성'),
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
                    ? l10n.countMemos(_entries.length)
                    : '메모 (${_entries.length})',
                style: AkashaTypography.dashboardPanelTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n?.tooltipNewMemo ?? '새 메모',
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
                              _formatWhen(entry.addedAt),
                              style: AkashaTypography.bodySecondary.copyWith(
                                color: AkashaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
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
