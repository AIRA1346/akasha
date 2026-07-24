import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../services/vault_trash_service.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';

sealed class VaultTrashListItem {
  const VaultTrashListItem();
  DateTime get timestamp;
}

class LegacyTrashListItem extends VaultTrashListItem {
  const LegacyTrashListItem(this.entry);
  final VaultTrashEntry entry;

  @override
  DateTime get timestamp => entry.trashedAt;
}

class CompositeTrashListItem extends VaultTrashListItem {
  const CompositeTrashListItem(this.transaction);
  final VaultTrashTransaction transaction;

  @override
  DateTime get timestamp => transaction.createdAt;
}

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
  late Future<List<VaultTrashListItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _load();
  }

  Future<List<VaultTrashListItem>> _load() async {
    final results = await Future.wait([
      _trash.listEntries(vaultPath: widget.vaultPath),
      _trash.listTransactions(vaultPath: widget.vaultPath),
    ]);

    final legacyList = (results[0] as List<VaultTrashEntry>)
        .map(LegacyTrashListItem.new)
        .toList();
    final compositeList = (results[1] as List<VaultTrashTransaction>)
        .map(CompositeTrashListItem.new)
        .toList();

    final combined = <VaultTrashListItem>[...legacyList, ...compositeList];
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return combined;
  }

  void _refresh() {
    setState(() {
      _itemsFuture = _load();
    });
  }

  Future<void> _restoreLegacy(
    VaultTrashEntry entry,
    AppLocalizations? l10n,
  ) async {
    final restored = await _trash.restoreFile(entry);
    if (!mounted) return;
    if (restored) {
      await widget.onRestored?.call();
      _showSnack(l10n?.trashRestoredSuccess ?? '휴지통에서 복구했습니다.');
      _refresh();
    } else {
      _showSnack(
        l10n?.trashRestoredFailedFileExists ?? '원래 위치에 파일이 있어 복구하지 못했습니다.',
      );
    }
  }

  Future<void> _restoreComposite(
    VaultTrashTransaction tx,
    AppLocalizations? l10n,
  ) async {
    final result = await _trash.restoreCanvasTransaction(tx);
    if (!mounted) return;
    if (result.succeeded) {
      await widget.onRestored?.call();
      final title = tx.title ?? tx.recordId;
      _showSnack(
        l10n?.trashRestoredSuccessCanvas(title) ?? '지식 지도 「$title」을(를) 복구했습니다.',
      );
      _refresh();
    } else {
      final msg = result.error ?? '원래 위치에 파일이 있어 복구하지 못했습니다.';
      _showSnack(msg);
    }
  }

  Future<void> _deleteLegacyPermanently(
    VaultTrashEntry entry,
    AppLocalizations? l10n,
  ) async {
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

  Future<void> _deleteCompositePermanently(
    VaultTrashTransaction tx,
    AppLocalizations? l10n,
  ) async {
    final title = tx.title ?? tx.recordId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.trashDeletePermanently ?? '영구 삭제'),
        content: Text(
          l10n?.trashDeleteConfirmCanvas(title) ??
              '지식 지도 「$title」을(를) 휴지통에서도 영구 삭제할까요?\n'
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

    final deleted = await _trash.deleteTransactionPermanently(tx);
    if (!mounted) return;
    _showSnack(
      deleted
          ? (l10n?.trashDeletedSuccess ?? '휴지통에서 영구 삭제했습니다.')
          : (l10n?.trashDeleteFailedNotFound ?? '삭제할 파일을 찾지 못했습니다.'),
    );
    _refresh();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return AlertDialog(
      title: Text(l10n?.vaultTrashTitle ?? 'Vault 휴지통'),
      content: SizedBox(
        width: 580,
        child: FutureBuilder<List<VaultTrashListItem>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    snapshot.error.toString(),
                    style: AkashaTypography.bodySecondary.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
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
              constraints: const BoxConstraints(maxHeight: 440),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AkashaSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is LegacyTrashListItem) {
                    return _LegacyTrashTile(
                      entry: item.entry,
                      onRestore: () => _restoreLegacy(item.entry, l10n),
                      onDeletePermanently: () =>
                          _deleteLegacyPermanently(item.entry, l10n),
                    );
                  } else if (item is CompositeTrashListItem) {
                    return _CompositeTrashTile(
                      transaction: item.transaction,
                      onRestore: () =>
                          _restoreComposite(item.transaction, l10n),
                      onDeletePermanently: () =>
                          _deleteCompositePermanently(item.transaction, l10n),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _refresh,
          child: Text(l10n?.trashRefresh ?? '새로고침'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.appPreferencesClose ?? '닫기'),
        ),
      ],
    );
  }
}

class _LegacyTrashTile extends StatelessWidget {
  const _LegacyTrashTile({
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
    final timeStr = entry.trashedAt.toLocal().toString().split('.').first;

    return Container(
      padding: const EdgeInsets.all(AkashaSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(width: AkashaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.originalFileName,
                  style: AkashaTypography.compactLabel.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.originalPathRelativeToVault(),
                  style: AkashaTypography.caption.copyWith(
                    color: Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n?.trashDeletedTime(timeStr) ?? '삭제됨 $timeStr',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: AkashaSpacing.xs),
          TextButton(
            key: ValueKey<String>(
              'trash-restore-legacy-${entry.originalFileName}',
            ),
            onPressed: onRestore,
            child: Text(l10n?.trashRestore ?? '복구'),
          ),
          TextButton(
            key: ValueKey<String>(
              'trash-delete-legacy-${entry.originalFileName}',
            ),
            onPressed: onDeletePermanently,
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n?.trashDeletePermanently ?? '영구 삭제'),
          ),
        ],
      ),
    );
  }
}

class _CompositeTrashTile extends StatelessWidget {
  const _CompositeTrashTile({
    required this.transaction,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final VaultTrashTransaction transaction;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final timeStr = transaction.createdAt.toLocal().toString().split('.').first;
    final isCommitted =
        transaction.state == VaultTrashTransactionState.committed.wireName;
    final title = transaction.title ?? transaction.recordId;

    return Container(
      padding: const EdgeInsets.all(AkashaSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCommitted
              ? Colors.grey.shade800
              : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.amber, size: 24),
              const SizedBox(width: AkashaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AkashaTypography.compactLabel.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isCommitted
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.state,
                            style: TextStyle(
                              fontSize: 10,
                              color: isCommitted
                                  ? Colors.lightBlue
                                  : Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: ${transaction.recordId} · ${transaction.members.length} files (canvas.md, layout.json)',
                      style: AkashaTypography.caption.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      l10n?.trashDeletedTime(timeStr) ?? '삭제됨 $timeStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCommitted) ...[
            const SizedBox(height: AkashaSpacing.xs),
            Text(
              l10n?.trashUnsafeStateWarning(transaction.state) ??
                  '안전한 자동 복구/영구삭제가 제한된 항목입니다. (상태: ${transaction.state})',
              style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: ValueKey<String>(
                    'trash-restore-canvas-${transaction.recordId}',
                  ),
                  onPressed: onRestore,
                  child: Text(l10n?.trashRestore ?? '복구'),
                ),
                TextButton(
                  key: ValueKey<String>(
                    'trash-delete-canvas-${transaction.recordId}',
                  ),
                  onPressed: onDeletePermanently,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: Text(l10n?.trashDeletePermanently ?? '영구 삭제'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
