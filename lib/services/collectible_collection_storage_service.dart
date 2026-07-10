import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_vault.dart';
import '../core/ports/vault_port.dart';
import '../models/collectible_collection.dart';
import 'vault_recovery_write_service.dart';

/// Entity collection list — vault `system/collectible_collections.json`.
///
/// Data boundary: user-owned canonical data (not rebuildable).
/// Previously stored at `.akasha/collectible_collections.json` — migrated to
/// `system/` to keep `.akasha/` 100% disposable.
class CollectibleCollectionStorageService {
  static const collectionsPrefsKey = 'akasha_collectible_collections';
  static const systemDirName = 'system';
  static const vaultFileName = 'collectible_collections.json';
  // Legacy path kept for migration only.
  static const _legacyDirName = '.akasha';

  final VaultPort _vault;

  CollectibleCollectionStorageService([VaultPort? vault])
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
      reason: 'migrate_collectible_collections_to_system',
    );
    // Old file is intentionally left at .akasha/ (not deleted).
  }

  Future<List<CollectibleCollection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded();
    final vaultPath = _vaultFilePath;

    if (vaultPath != null) {
      final vaultFile = File(vaultPath);
      if (await vaultFile.exists()) {
        final decoded = await _readJsonList(vaultFile);
        await prefs.remove(collectionsPrefsKey);
        return decoded;
      }

      final prefsJson = prefs.getString(collectionsPrefsKey);
      if (prefsJson != null) {
        final decoded = _decodeJsonList(prefsJson);
        await save(decoded);
        await prefs.remove(collectionsPrefsKey);
        return decoded;
      }

      return const [];
    }

    final prefsJson = prefs.getString(collectionsPrefsKey);
    if (prefsJson != null) {
      return _decodeJsonList(prefsJson);
    }

    return const [];
  }

  Future<void> save(List<CollectibleCollection> collections) async {
    final encoded = jsonEncode(collections.map((e) => e.toJson()).toList());
    final vaultPath = _vaultFilePath;

    if (vaultPath != null) {
      await VaultRecoveryWriteService().writeText(
        vaultPath: _vault.vaultPath!,
        targetPath: vaultPath,
        content: encoded,
        reason: 'save_collectible_collections',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(collectionsPrefsKey);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(collectionsPrefsKey, encoded);
  }

  Future<List<CollectibleCollection>> _readJsonList(File file) async {
    final content = await file.readAsString();
    return _decodeJsonList(content);
  }

  List<CollectibleCollection> _decodeJsonList(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as List;
    return decoded
        .map((e) => CollectibleCollection.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
