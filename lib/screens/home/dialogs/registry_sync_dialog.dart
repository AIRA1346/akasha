import 'package:flutter/material.dart';
import '../../../services/registry_sync_service.dart';
import '../home_registry_sync.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/app_l10n.dart';

/// 글로벌 사전 동기화·커스텀 URL 설정 다이얼로그
Future<void> showRegistrySyncDialog(
  BuildContext context, {
  required bool isSyncing,
  required Future<void> Function() onSyncNow,
  required Future<void> Function() onUrlSaved,
  DateTime? lastSyncTime,
}) async {
  final l10n = lookupAppL10n(context);
  final syncService = RegistrySyncService();
  await syncService.init();
  final ctrl = TextEditingController(text: syncService.customDbUrl);
  const defaultBase = RegistrySyncService.defaultDbBaseUrl;
  var dialogLastSync = lastSyncTime ?? syncService.lastSyncTime;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: Text(l10n?.registrySyncTitle ?? '🌐 글로벌 사전 동기화'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 16,
                      color: AkashaColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n != null
                            ? l10n.lastSyncTime(
                                HomeRegistrySync.formatLastSyncTime(
                                  dialogLastSync,
                                ),
                              )
                            : '마지막 동기화: ${HomeRegistrySync.formatLastSyncTime(dialogLastSync)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await onSyncNow();
                        },
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(l10n?.actionSyncNow ?? '지금 동기화'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  l10n?.labelCustomDbUrl ?? '커스텀 사전 DB Base URL',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.customDbUrlDescription ??
                      'manifest.json, search_index.json, shards/ 파일을 이 주소에서 내려받습니다.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AkashaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Default: $defaultBase',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AkashaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Registry Base URL (include trailing /)',
                    hintText: 'https://raw.githubusercontent.com/.../main/',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.actionClose ?? '닫기'),
            ),
            FilledButton(
              onPressed: () async {
                await syncService.setCustomDbUrl(ctrl.text);
                await syncService.init();
                dialogLastSync = syncService.lastSyncTime;
                setDialogState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                await onUrlSaved();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n?.syncUrlChanged ?? '동기화 주소가 변경되었습니다.'),
                    ),
                  );
                }
              },
              child: Text(l10n?.actionSaveUrl ?? 'URL 저장'),
            ),
          ],
        );
      },
    ),
  );
}
