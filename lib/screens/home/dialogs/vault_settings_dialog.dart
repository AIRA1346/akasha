import 'package:flutter/material.dart';

import '../../../config/catalog_locale.dart';
import '../../../utils/app_l10n.dart';
import '../../../services/catalog_locale_preferences.dart';
import '../../../services/file_service.dart';
import '../../../services/user_preferences.dart';
import '../../../services/user_registry_preferences.dart';
import '../../../widgets/hidden_registry_dialog.dart';

/// 로컬 볼트(Vault) 설정 다이얼로그
Future<void> showVaultSettingsDialog(
  BuildContext context, {
  required String displayName,
  required bool autoArchiveRegistry,
  required void Function(String displayName) onDisplayNameSaved,
  required void Function(bool enabled) onAutoArchiveChanged,
  required Future<void> Function({bool showFeedback}) runAutoArchive,
  required Future<void> Function() reloadItems,
  required Future<void> Function() selectVaultFolder,
  required VoidCallback onRegistryVisibilityChanged,
}) async {
  final service = AkashaFileService();
  final path = service.vaultPath;
  final vaultValid = await service.isVaultPathValid();
  final mdCount =
      vaultValid && path != null ? await service.countMarkdownFiles() : 0;
  final nameCtrl = TextEditingController(text: displayName);
  var localAutoArchive = autoArchiveRegistry;
  var localLocale = CatalogLocaleScope.current;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final l10n = lookupAppL10n(ctx);
        return AlertDialog(
          title: const Text('📂 로컬 볼트(Vault) 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (l10n != null) ...[
                Text(
                  l10n.settingsDisplayLanguage,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<CatalogLocale>(
                  initialValue: localLocale,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CatalogLocale.ko,
                      child: Text(l10n.localeKo),
                    ),
                    DropdownMenuItem(
                      value: CatalogLocale.en,
                      child: Text(l10n.localeEn),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await CatalogLocalePreferences.save(value);
                    CatalogLocaleScope.setCurrent(value);
                    localLocale = value;
                    setD(() {});
                  },
                ),
                const SizedBox(height: 16),
              ],
              Text(
                path != null
                    ? '현재 연동된 폴더:\n$path'
                    : '연동된 폴더가 없습니다. 마크다운 파일로 영속적으로 기록하려면 Sanctum Vault 폴더를 연동해 주세요.',
                style: const TextStyle(fontSize: 13),
              ),
              if (path != null) ...[
                const SizedBox(height: 8),
                Text(
                  vaultValid
                      ? '상태: 연동됨 · 아카이브 .md $mdCount개'
                      : '상태: 경로를 찾을 수 없음 (다시 연동해 주세요)',
                  style: TextStyle(
                    fontSize: 12,
                    color: vaultValid ? Colors.tealAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '※ manga, game, animation 등 카테고리 폴더에 .md가 생성됩니다. work_id는 YAML에 기록됩니다.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '사전 작품 자동 아카이빙',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    '켜면 현재 필터 범위의 사전 작품을 .md로 자동 생성합니다. (기본: 끔)',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: localAutoArchive,
                  onChanged: (value) async {
                    await UserPreferences.setAutoArchiveRegistryEnabled(value);
                    localAutoArchive = value;
                    onAutoArchiveChanged(value);
                    setD(() {});
                    if (value && service.vaultPath != null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      await runAutoArchive(showFeedback: true);
                    }
                  },
                ),
                if (localAutoArchive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await runAutoArchive(showFeedback: true);
                      },
                      icon: const Icon(Icons.archive_outlined, size: 16),
                      label: const Text('지금 사전 작품 아카이빙 실행'),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await showHiddenRegistryDialog(
                    ctx,
                    onChanged: () {
                      setD(() {});
                      onRegistryVisibilityChanged();
                    },
                  );
                },
                icon: const Icon(Icons.visibility_off_outlined, size: 16),
                label: Text(
                  '숨긴 사전 항목 관리 (${UserRegistryPreferences.instance.hiddenWorkIds.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '표시 이름 (워치리스트 등)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: '사용자',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            if (path != null)
              TextButton(
                onPressed: () async {
                  await service.setVaultPath('');
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    await reloadItems();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('연동 해제'),
              ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                await UserPreferences.setDisplayName(name);
                onDisplayNameSaved(
                  name.isEmpty ? UserPreferences.defaultDisplayName : name,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('이름 저장'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                selectVaultFolder();
              },
              child: Text(path != null ? '폴더 변경' : '폴더 연동'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    ),
  );
}
