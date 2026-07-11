part of 'file_service.dart';

mixin _AkashaFileServiceScan
    on _AkashaFileServiceBase, _AkashaFileServicePaths {
  void _syncCacheFromItems(List<AkashaItem> items) {
    _inMemoryCache.clear();
    for (final item in items) {
      _inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;
    }
  }

  /// 볼트 내의 모든 마크다운 파일을 로드하여 AkashaItem 리스트를 반환합니다.
  Future<List<AkashaItem>> loadAllItems() async {
    if (_vaultPath == null) return [];

    final parsed = <AkashaItem>[];

    try {
      final dir = Directory(_vaultPath!);
      if (await dir.exists()) {
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File || !entity.path.endsWith('.md')) continue;
          if (_shouldSkipPath(entity.path)) continue;

          try {
            final content = await entity.readAsString();
            final filename = p.basenameWithoutExtension(entity.path);
            final item = MarkdownParser.deserialize(content, filename);
            item.filePath = entity.path;
            item.openedRevision = VaultFileRevision.fromText(
              content,
              modifiedAtUtc: (await entity.lastModified()).toUtc(),
            );
            parsed.add(item);
          } catch (e) {
            appLog('Error reading file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      appLog('Error loading items recursively from vault: $e');
    }

    final items = AkashaFileService.dedupeItems(parsed);
    _syncCacheFromItems(items);
    return items;
  }

  /// 볼트 내 .md 파일 개수 (파싱 없이 스캔)
  /// Reads one canonical Markdown file without enumerating the Vault.
  Future<AkashaItem?> loadItemByRelativePath(String relativePath) async {
    final vaultPath = _vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return null;
    final raw = relativePath.trim();
    if (raw.isEmpty || p.isAbsolute(raw)) return null;

    final root = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(p.join(root, raw)));
    if (!p.isWithin(root, target) ||
        !target.toLowerCase().endsWith('.md') ||
        _shouldSkipPath(target)) {
      return null;
    }

    final file = File(target);
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final item = MarkdownParser.deserialize(
        content,
        p.basenameWithoutExtension(target),
      );
      item.filePath = target;
      item.openedRevision = VaultFileRevision.fromText(
        content,
        modifiedAtUtc: (await file.lastModified()).toUtc(),
      );
      return item;
    } catch (error) {
      appLog('Error reading selected vault file $target: $error');
      return null;
    }
  }

  Future<int> countMarkdownFiles() async {
    if (_vaultPath == null) return 0;
    var count = 0;
    try {
      final dir = Directory(_vaultPath!);
      if (!await dir.exists()) return 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File &&
            entity.path.endsWith('.md') &&
            !_shouldSkipPath(entity.path)) {
          count++;
        }
      }
    } catch (e) {
      appLog('[AkashaFileService] countMarkdownFiles error: $e');
    }
    return count;
  }

  /// 볼트 경로가 유효한지 확인합니다.
  Future<bool> isVaultPathValid() async {
    if (_vaultPath == null || _vaultPath!.isEmpty) return false;
    return Directory(_vaultPath!).exists();
  }
}
