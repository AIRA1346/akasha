import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/personal_library_config.dart';
import 'file_service.dart';

/// 나만의 서재 목록 영속화 — 볼트 `.akasha/` 우선, 데모는 prefs (D8)
class PersonalLibraryStorageService {
  static const librariesPrefsKey = 'akasha_personal_libraries';
  static const akashaDirName = '.akasha';
  static const vaultFileName = 'personal_libraries.json';

  final AkashaFileService _fileService;

  PersonalLibraryStorageService([AkashaFileService? fileService])
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

  Future<List<PersonalLibraryConfig>> load() async {
    final prefs = await SharedPreferences.getInstance();
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
      final dir = Directory(_vaultAkashaDir!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await File(vaultPath).writeAsString(encoded);
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
        .map(
          (e) => PersonalLibraryConfig.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
