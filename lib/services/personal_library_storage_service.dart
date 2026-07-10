import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_vault.dart';
import '../core/ports/vault_port.dart';
import '../models/personal_library_config.dart';
import 'vault_recovery_write_service.dart';

/// 나만의 서재 목록 영속화 — 볼트 `system/` 우선, 데모는 prefs (D8)
///
/// Data boundary: user-owned canonical data (not rebuildable).
/// Previously stored at `.akasha/personal_libraries.json` — migrated to
/// `system/` to keep `.akasha/` 100% disposable.
class PersonalLibraryStorageService {
  static const librariesPrefsKey = 'akasha_personal_libraries';
  static const systemDirName = 'system';
  static const vaultFileName = 'personal_libraries.json';
  // Legacy path kept for migration only.
  static const _legacyDirName = '.akasha';

  final VaultPort _vault;

  PersonalLibraryStorageService([VaultPort? vault])
    : _vault = vault ?? AppVault.port;

  String? get _vaultSystemDir {
    final vault = _vault.vaultPath;
    if (vault == null || vault.isEmpty) return null;
    return p.join(vault, systemDirName);
  }

  String? get _vaultFilePath {
    final dir = _vaultSystemDir;
    if (dir == null) return null;
    return p.join(dir, vaultFileName);
  }

  String? get _legacyFilePath {
    final vault = _vault.vaultPath;
    if (vault == null || vault.isEmpty) return null;
    return p.join(vault, _legacyDirName, vaultFileName);
  }

  /// Copies old `.akasha/` file to `system/` without deleting the original.
  /// If both exist already, does nothing (conflict preserved, system/ wins).
  Future<void> _migrateIfNeeded() async {
    final newPath = _vaultFilePath;
    final oldPath = _legacyFilePath;
    if (newPath == null || oldPath == null) return;

    final newFile = File(newPath);
    final oldFile = File(oldPath);

    if (await newFile.exists()) return; // already migrated, nothing to do
    if (!await oldFile.exists()) return; // no legacy file, new install

    await VaultRecoveryWriteService().writeText(
      vaultPath: _vault.vaultPath!,
      targetPath: newPath,
      content: await oldFile.readAsString(),
      reason: 'migrate_personal_libraries_to_system',
    );
    // Old file is intentionally left at .akasha/ (not deleted).
  }

  Future<List<PersonalLibraryConfig>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded();
    final vaultPath = _vaultFilePath;

    if (vaultPath != null) {
      final vaultFile = File(vaultPath);
      if (await vaultFile.exists()) {
        final decoded = await _readJsonList(vaultFile);
        await prefs.remove(librariesPrefsKey);
        return PersonalLibraryConfig.normalizeLibraries(decoded);
      }

      final prefsJson = prefs.getString(librariesPrefsKey);
      if (prefsJson != null) {
        final decoded = _decodeJsonList(prefsJson);
        final normalized = PersonalLibraryConfig.normalizeLibraries(decoded);
        await save(normalized);
        await prefs.remove(librariesPrefsKey);
        return normalized;
      }

      final defaults = PersonalLibraryConfig.defaultLibraries();
      await save(defaults);
      return defaults;
    }

    final prefsJson = prefs.getString(librariesPrefsKey);
    if (prefsJson != null) {
      final decoded = _decodeJsonList(prefsJson);
      return PersonalLibraryConfig.normalizeLibraries(decoded);
    }

    return PersonalLibraryConfig.defaultLibraries();
  }

  Future<void> save(List<PersonalLibraryConfig> libraries) async {
    final encoded = jsonEncode(libraries.map((e) => e.toJson()).toList());
    final vaultPath = _vaultFilePath;

    if (vaultPath != null) {
      await VaultRecoveryWriteService().writeText(
        vaultPath: _vault.vaultPath!,
        targetPath: vaultPath,
        content: encoded,
        reason: 'save_personal_libraries',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(librariesPrefsKey);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(librariesPrefsKey, encoded);
  }

  Future<List<PersonalLibraryConfig>> _readJsonList(File file) async {
    final content = await file.readAsString();
    return _decodeJsonList(content);
  }

  List<PersonalLibraryConfig> _decodeJsonList(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as List;
    return decoded
        .map((e) => PersonalLibraryConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
