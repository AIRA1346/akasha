import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../config/catalog_locale.dart';
import '../../../core/ports/vault_port.dart';
import '../../../utils/app_l10n.dart';
import '../../../services/catalog_locale_preferences.dart';
import '../../../services/user_preferences.dart';
import '../../../services/user_registry_preferences.dart';
import '../../../services/vault_backup_exporter.dart';
import '../../../widgets/hidden_registry_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import 'vault_trash_dialog.dart';

/// 로컬 볼트(Vault) 설정 다이얼로그
Future<void> showVaultSettingsDialog(
  BuildContext context, {
  required VaultPort vault,
  required String displayName,
  required bool autoArchiveRegistry,
  required void Function(String displayName) onDisplayNameSaved,
  required void Function(bool enabled) onAutoArchiveChanged,
  required Future<void> Function({bool showFeedback}) runAutoArchive,
  required Future<void> Function() reloadItems,
  required Future<void> Function() selectVaultFolder,
  required VoidCallback onRegistryVisibilityChanged,
}) async {
  final path = vault.vaultPath;
  final vaultValid = await vault.isVaultPathValid();
  final mdCount = vaultValid && path != null
      ? await vault.countMarkdownFiles()
      : 0;
  final nameCtrl = TextEditingController(text: displayName);
  var localAutoArchive = autoArchiveRegistry;
  var localLocale = CatalogLocaleScope.current;
  var isExportingBackup = false;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final l10n = lookupAppL10n(ctx);
        return AlertDialog(
          title: Text(
            l10n != null ? '📂 ${l10n.vaultSettingsTitle}' : '📂 로컬 볼트(Vault) 설정',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (l10n != null) ...[
                Text(
                  l10n.settingsDisplayLanguage,
                  style: AkashaTypography.settingsLabel,
                ),
                SizedBox(height: AkashaSpacing.xs + 2),
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
                SizedBox(height: AkashaSpacing.lg),
              ],
              Text(
                path != null
                    ? (l10n?.vaultPathLinked(path) ?? '현재 연동된 폴더:\n$path')
                    : (l10n?.vaultPathNotLinked ?? '연동된 폴더가 없습니다. 마크다운 파일로 영속적으로 기록하려면 Sanctum Vault 폴더를 연동해 주세요.'),
                style: AkashaTypography.dialogBody,
              ),
              if (path != null) ...[
                SizedBox(height: AkashaSpacing.sm),
                Text(
                  vaultValid
                      ? (l10n?.vaultStatusLinked(mdCount) ?? '상태: 연동됨 · 아카이브 .md $mdCount개')
                      : (l10n?.vaultStatusPathNotFound ?? '상태: 경로를 찾을 수 없음 (다시 연동해 주세요)'),
                  style: AkashaTypography.bodyEmphasis.copyWith(
                    color: vaultValid
                        ? AkashaColors.linkAccent
                        : Colors.redAccent,
                  ),
                ),
                SizedBox(height: AkashaSpacing.sm),
                TextButton.icon(
                  onPressed: vaultValid && !isExportingBackup
                      ? () async {
                          final outputDirectory =
                              await FilePicker.getDirectoryPath();
                          if (outputDirectory == null) return;
                          setD(() => isExportingBackup = true);
                          try {
                            final result = await const VaultBackupExporter()
                                .exportVault(
                                  vaultPath: path,
                                  outputDirectory: outputDirectory,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.vaultBackupSuccess(p.basename(result.archivePath), result.fileCount) ??
                                    '볼트 백업을 저장했습니다: ${p.basename(result.archivePath)} '
                                    '(${result.fileCount} files)',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.vaultBackupFailed(e.toString()) ?? '볼트 백업 실패: $e',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setD(() => isExportingBackup = false);
                            }
                          }
                        }
                      : null,
                  icon: isExportingBackup
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.archive_outlined, size: 16),
                  label: Text(l10n?.vaultBackupExport ?? '볼트 ZIP 백업 내보내기'),
                ),
                TextButton.icon(
                  onPressed: vaultValid
                      ? () async {
                          await showVaultTrashDialog(
                            ctx,
                            vaultPath: path,
                            onRestored: reloadItems,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n?.vaultViewTrash ?? 'Vault 휴지통 보기'),
                ),
                SizedBox(height: AkashaSpacing.md),
                Text(
                  l10n?.vaultArchivingNotice ??
                      '※ manga, game, animation 등 카테고리 폴더에 .md가 생성됩니다. work_id는 YAML에 기록됩니다.',
                  style: AkashaTypography.caption,
                ),
                SizedBox(height: AkashaSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n?.vaultAutoArchiveRegistry ?? '사전 작품 자동 아카이빙', style: AkashaTypography.body),
                  subtitle: Text(
                    l10n?.vaultAutoArchiveRegistryHelp ?? '켜면 현재 필터 범위의 사전 작품을 .md로 자동 생성합니다. (기본: 끔)',
                    style: AkashaTypography.caption,
                  ),
                  value: localAutoArchive,
                  onChanged: (value) async {
                    await UserPreferences.setAutoArchiveRegistryEnabled(value);
                    localAutoArchive = value;
                    onAutoArchiveChanged(value);
                    setD(() {});
                    if (value && vault.vaultPath != null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      await runAutoArchive(showFeedback: true);
                    }
                  },
                ),
                if (localAutoArchive)
                  Padding(
                    padding: EdgeInsets.only(top: AkashaSpacing.xs),
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await runAutoArchive(showFeedback: true);
                      },
                      icon: const Icon(Icons.archive_outlined, size: 16),
                      label: Text(l10n?.vaultAutoArchiveRegistryRunNow ?? '지금 사전 작품 아카이빙 실행'),
                    ),
                  ),
              ],
              SizedBox(height: AkashaSpacing.md),
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
                  l10n?.vaultHiddenRegistryManage(UserRegistryPreferences.instance.hiddenWorkIds.length) ??
                      '숨긴 사전 항목 관리 (${UserRegistryPreferences.instance.hiddenWorkIds.length})',
                  style: AkashaTypography.body,
                ),
              ),
              SizedBox(height: AkashaSpacing.lg),
              Text(l10n?.vaultDisplayNameLabel ?? '표시 이름 (워치리스트 등)', style: AkashaTypography.settingsLabel),
              SizedBox(height: AkashaSpacing.xs + 2),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: l10n?.vaultDisplayNameDefault ?? '사용자',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            if (path != null)
              TextButton(
                onPressed: () async {
                  await vault.setVaultPath('');
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    await reloadItems();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text(l10n?.vaultDisconnect ?? '연동 해제'),
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
              child: Text(l10n?.vaultSaveName ?? '이름 저장'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                selectVaultFolder();
              },
              child: Text(
                path != null
                    ? (l10n?.vaultChangeFolder ?? '폴더 변경')
                    : (l10n?.vaultLinkFolder ?? '폴더 연동'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.appPreferencesClose ?? '닫기'),
            ),
          ],
        );
      },
    ),
  );
}
