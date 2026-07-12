part of 'file_service.dart';

mixin _AkashaFileServiceBootstrap
    on
        _AkashaFileServiceBase,
        _AkashaFileServicePaths,
        _AkashaFileServiceWatch {
  /// SharedPreferences에서 기존에 저장된 볼트 경로를 불러옵니다.
  ///
  /// Cold start must run the same index/fingerprint/notify side effects as
  /// [setVaultPath]. Otherwise Explore/Home stay incomplete until the user
  /// re-selects the folder (which calls [setVaultPath] + loadItems).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AkashaFileService._prefVaultKey);
    if (saved == null || saved.isEmpty) {
      _vaultPath = null;
      return;
    }

    if (await Directory(saved).exists()) {
      await _activateVaultPath(saved, persist: false, clearCache: false);
    } else {
      _vaultPath = null;
      await prefs.remove(AkashaFileService._prefVaultKey);
    }
  }

  /// 새로운 볼트 경로를 설정하고 저장합니다.
  Future<void> setVaultPath(String path) async {
    if (path.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _inMemoryCache.clear();
      _vaultPath = null;
      await prefs.remove(AkashaFileService._prefVaultKey);
      _stopWatching();
      await _refreshVaultFingerprint();
      _notifyVaultUpdated();
      return;
    }

    await _activateVaultPath(path, persist: true, clearCache: true);
  }

  /// Shared bind path for cold-start restore and explicit folder selection.
  Future<void> _activateVaultPath(
    String path, {
    required bool persist,
    required bool clearCache,
  }) async {
    if (clearCache) {
      _inMemoryCache.clear();
    }

    _vaultPath = path;

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AkashaFileService._prefVaultKey, path);
    }

    await _ensureFolderStructure();
    await VaultReadmeWriter().write(path);
    await VaultSpecWriter().write(path);
    await EntityPathIndexService().ensureIndex(path);
    await RecordSummaryIndexService().ensureIndex(path);
    await TitleAliasIndexService().ensureIndex(path);
    await const RecordPathIndexService().ensureIndex(path);
    _startWatching();
    await _refreshVaultFingerprint();
    _notifyVaultUpdated();
  }

  /// 볼트에 필요한 기본 폴더 구조(posters, 카테고리별)를 생성합니다.
  Future<void> _ensureFolderStructure() async {
    if (_vaultPath == null) return;

    await Directory(p.join(_vaultPath!, 'posters')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'timeline')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'catalog')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'works')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'journal')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'entities')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'system')).create(recursive: true);
    await Directory(
      p.join(_vaultPath!, 'system', 'logs'),
    ).create(recursive: true);
    await Directory(
      p.join(_vaultPath!, 'system', 'ops'),
    ).create(recursive: true);
    await Directory(
      p.join(_vaultPath!, 'system', 'candidates'),
    ).create(recursive: true);
    await Directory(
      p.join(_vaultPath!, VaultTrashService.trashDirName),
    ).create(recursive: true);
    for (final type in EntityAnchorType.values) {
      if (type == EntityAnchorType.work ||
          type == EntityAnchorType.phenomenon) {
        continue;
      }
      await Directory(
        p.join(_vaultPath!, 'entities', type.name),
      ).create(recursive: true);
    }

    for (final cat in MediaCategory.values) {
      await Directory(
        p.join(_vaultPath!, 'works', cat.name),
      ).create(recursive: true);
    }

    // TODO(remove): L4 — docs/draft/LEGACY_REMOVAL_POLICY.md §2.3
    for (final cat in MediaCategory.values) {
      await Directory(p.join(_vaultPath!, cat.name)).create(recursive: true);
    }
  }
}
