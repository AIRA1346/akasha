import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../services/vault_trash_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

Future<void> showVaultTrashDialog(
  BuildContext context, {
  required String vaultPath,
  Future<void> Function()? onRestored,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) =>
        _VaultTrashDialog(vaultPath: vaultPath, onRestored: onRestored),
  );
}

class _VaultTrashDialog extends StatefulWidget {
  const _VaultTrashDialog({required this.vaultPath, this.onRestored});

  final String vaultPath;
  final Future<void> Function()? onRestored;

  @override
  State<_VaultTrashDialog> createState() => _VaultTrashDialogState();
}

class _VaultTrashDialogState extends State<_VaultTrashDialog> {
  final _trash = const VaultTrashService();
  late Future<List<VaultTrashEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _load();
  }

  Future<List<VaultTrashEntry>> _load() =>
      _trash.listEntries(vaultPath: widget.vaultPath);

  void _refresh() {
    setState(() {
      _entriesFuture = _load();
    });
  }

  Future<void> _restore(VaultTrashEntry entry, AppLocalizations? l10n) async {
    final restored = await _trash.restoreFile(entry);
    if (!mounted) return;
    if (restored) {
      await widget.onRestored?.call();
      _showSnack(l10n?.trashRestoredSuccess ?? '휴지통에서 복구했습니다.');
      _refresh();
    } else {
      _showSnack(l10n?.trashRestoredFailedFileExists ?? '원래 위치에 파일이 있어 복구하지 못했습니다.');
    }
  }

  Future<void> _deletePermanently(VaultTrashEntry entry, AppLocalizations? l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.trashDeletePermanently ?? '영구 삭제'),
        content: Text(
          l10n?.trashDeleteConfirm(entry.originalFileName) ??
          '「${entry.originalFileName}」을(를) 휴지통에서도 삭제할까요?\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.actionCancel ?? '취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n?.trashDeletePermanently ?? '영구 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await _trash.deleteEntryPermanently(entry);
    if (!mounted) return;
    _showSnack(
      deleted
          ? (l10n?.trashDeletedSuccess ?? '휴지통에서 영구 삭제했습니다.')
          : (l10n?.trashDeleteFailedNotFound ?? '삭제할 파일을 찾지 못했습니다.'),
    );
    _refresh();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return AlertDialog(
      title: Text(l10n?.vaultTrashTitle ?? 'Vault 휴지통'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<VaultTrashEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    l10n?.trashEmpty ?? '휴지통이 비어 있습니다.',
                    style: AkashaTypography.bodySecondary,
                  ),
                ),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AkashaSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _VaultTrashTile(
                    entry: entry,
                    onRestore: () => _restore(entry, l10n),
                    onDeletePermanently: () => _deletePermanently(entry, l10n),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(l10n?.trashRefresh ?? '새로고침'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.appPreferencesClose ?? '닫기'),
        ),
      ],
    );
  }
}

class _VaultTrashTile extends StatelessWidget {
  const _VaultTrashTile({
    required this.entry,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final VaultTrashEntry entry;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final trashedAt = entry.trashedAt.toLocal();
    final time =
        '${trashedAt.year.toString().padLeft(4, '0')}-'
        '${trashedAt.month.toString().padLeft(2, '0')}-'
        '${trashedAt.day.toString().padLeft(2, '0')} '
        '${trashedAt.hour.toString().padLeft(2, '0')}:'
        '${trashedAt.minute.toString().padLeft(2, '0')}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AkashaColors.borderSubtle(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.delete_outline, color: AkashaColors.textSecondary),
            const SizedBox(width: AkashaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.originalFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AkashaTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AkashaSpacing.xs),
                  Text(
                    entry.originalPathRelativeToVault(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AkashaTypography.caption,
                  ),
                  const SizedBox(height: AkashaSpacing.xs),
                  Text(
                    l10n?.trashDeletedTime(time) ?? '삭제됨 $time',
                    style: AkashaTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AkashaSpacing.md),
            IconButton(
              tooltip: l10n?.trashRestore ?? '복구',
              onPressed: onRestore,
              icon: const Icon(Icons.restore, size: 18),
            ),
            IconButton(
              tooltip: l10n?.trashDeletePermanently ?? '영구 삭제',
              onPressed: onDeletePermanently,
              color: Colors.redAccent,
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
