part of 'file_service.dart';

mixin _AkashaFileServiceBootstrap
    on
        _AkashaFileServiceBase,
        _AkashaFileServicePaths,
        _AkashaFileServiceWatch {
  /// SharedPreferences에서 기존에 저장된 볼트 경로를 불러옵니다.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AkashaFileService._prefVaultKey);
    if (saved == null || saved.isEmpty) {
      _vaultPath = null;
      return;
    }

    if (await Directory(saved).exists()) {
      _vaultPath = saved;
      _startWatching();
    } else {
      _vaultPath = null;
      await prefs.remove(AkashaFileService._prefVaultKey);
    }
  }

  /// 새로운 볼트 경로를 설정하고 저장합니다.
  Future<void> setVaultPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    _inMemoryCache.clear();

    if (path.isEmpty) {
      _vaultPath = null;
      await prefs.remove(AkashaFileService._prefVaultKey);
      _stopWatching();
    } else {
      _vaultPath = path;
      await prefs.setString(AkashaFileService._prefVaultKey, path);
      await _ensureFolderStructure();
      await VaultReadmeWriter().write(path);
      await VaultSpecWriter().write(path);
      await EntityPathIndexService().ensureIndex(path);
      await RecordSummaryIndexService().ensureIndex(path);
      _startWatching();
    }
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
