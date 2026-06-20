import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collectible_collection.dart';
import 'file_service.dart';

/// Entity collection list — vault `.akasha/collectible_collections.json`.
class CollectibleCollectionStorageService {
  static const collectionsPrefsKey = 'akasha_collectible_collections';
  static const akashaDirName = '.akasha';
  static const vaultFileName = 'collectible_collections.json';

  final AkashaFileService _fileService;

  CollectibleCollectionStorageService([AkashaFileService? fileService])
      : _fileService = fileService ?? AkashaFileService();

  String? get _vaultAkashaDir {
    final vault = _fileService.vaultPath;
    if (vault == null || vault.isEmpty) return null;
    return p.join(vault, akashaDirName);
  }

  String? get _vaultFilePath {
    final dir = _vaultAkashaDir;
    if (dir == null) return null;
    return p.join(dir, vaultFileName);
  }

  Future<List<CollectibleCollection>> load() async {
    final prefs = await SharedPreferences.getInstance();
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
    final encoded =
        jsonEncode(collections.map((e) => e.toJson()).toList());
    final vaultPath = _vaultFilePath;

    if (vaultPath != null) {
      final dir = Directory(_vaultAkashaDir!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await File(vaultPath).writeAsString(encoded);
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
        .map(
          (e) => CollectibleCollection.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
