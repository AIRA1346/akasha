part of 'file_service.dart';

mixin _AkashaFileServiceSave
    on _AkashaFileServiceBase, _AkashaFileServicePaths, _AkashaFileServiceWatch {
  /// AkashaItem을 마크다운 파일로 저장합니다.
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) async {
    item.workId = MarkdownParser.ensureWorkId(item);
    _inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;

    if (_vaultPath == null) return;

    final useWorksLayout = await UserPreferences.isVaultWorksLayoutEnabled();

    if (oldTitle != null && oldTitle != item.title) {
      if (item.filePath != null && item.filePath!.isNotEmpty) {
        final oldFile = File(item.filePath!);
        if (oldFile.existsSync()) {
          _stopWatching();
          try {
            await oldFile.delete();
          } catch (e) {
            appLog('Error deleting old file: $e');
          } finally {
            _startWatching();
          }
        }
        item.filePath = VaultWorkJournalPaths.resolvePathAfterTitleChange(
          vaultRoot: _vaultPath!,
          item: item,
          useWorksLayout: useWorksLayout,
        );
      } else {
        await deleteItem(oldTitle, item.category);
      }
    }

    String targetPath;
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      targetPath = item.filePath!;
    } else {
      targetPath = VaultWorkJournalPaths.resolveNewPath(
        vaultRoot: _vaultPath!,
        item: item,
        useWorksLayout: useWorksLayout,
      );
      item.filePath = targetPath;
    }

    await Directory(p.dirname(targetPath)).create(recursive: true);

    final content = MarkdownParser.serialize(item);

    _stopWatching();
    try {
      await _writeAtomic(targetPath, content);
      await _refreshVaultFingerprint();
      _notifyVaultUpdated();
    } finally {
      _startWatching();
    }
  }

  Future<void> _writeAtomic(String targetPath, String content) async {
    final file = File(targetPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final tempPath = p.join(
      parent.path,
      '.akasha_${DateTime.now().microsecondsSinceEpoch}_${p.basename(targetPath)}.tmp',
    );
    final temp = File(tempPath);
    try {
      await temp.writeAsString(content, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(targetPath);
    } catch (e) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// AkashaItem을 볼트에서 제거(마크다운 파일 삭제)합니다.
  Future<bool> deleteAkashaItem(AkashaItem item) async {
    _inMemoryCache.remove(AkashaFileService.cacheKeyFor(item));

    if (_vaultPath == null) return true;

    final candidates = VaultWorkJournalPaths.resolveDeleteCandidates(
      vaultRoot: _vaultPath!,
      title: item.title,
      category: item.category,
      filePath: item.filePath,
    );
    return _deleteAtCandidatePaths(candidates);
  }

  /// 제목·카테고리 기반 삭제 (파일명 변경 시 saveItem 내부용)
  Future<void> deleteItem(String title, MediaCategory category) async {
    _inMemoryCache.removeWhere(
      (key, cached) => cached.title == title && cached.category == category,
    );

    if (_vaultPath == null) return;

    final candidates = VaultWorkJournalPaths.resolveDeleteCandidates(
      vaultRoot: _vaultPath!,
      title: title,
      category: category,
    );
    await _deleteAtCandidatePaths(candidates);
  }

  Future<bool> _deleteAtCandidatePaths(List<String> candidatePaths) async {
    final existing = <File>[];
    for (final path in candidatePaths) {
      final file = File(path);
      if (await file.exists()) {
        existing.add(file);
      }
    }
    if (existing.isEmpty) return false;

    _stopWatching();
    try {
      for (final file in existing) {
        await file.delete();
      }
      _notifyVaultUpdated();
      return true;
    } finally {
      _startWatching();
    }
  }

  /// 외부 이미지를 볼트의 posters 폴더로 복사하고 상대 경로를 반환합니다.
  Future<String?> importPosterImage(String sourceFilePath) async {
    if (_vaultPath == null) return null;

    final file = File(sourceFilePath);
    if (!await file.exists()) return null;

    final filename = p.basename(sourceFilePath);
    final uniqueFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
    final destinationPath = p.join(_vaultPath!, 'posters', uniqueFilename);

    await file.copy(destinationPath);
    return p.join('posters', uniqueFilename);
  }

  /// 클립보드·붙여넣기 바이트를 posters에 저장하고 상대 경로 반환.
  Future<String?> importPosterImageFromBytes(
    Uint8List bytes, {
    String extension = 'png',
  }) async {
    if (_vaultPath == null || bytes.isEmpty) return null;

    final ext = _normalizePosterExtension(extension);
    final uniqueFilename =
        '${DateTime.now().millisecondsSinceEpoch}_paste.$ext';
    final destinationPath = p.join(_vaultPath!, 'posters', uniqueFilename);
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    await File(destinationPath).writeAsBytes(bytes, flush: true);
    return p.join('posters', uniqueFilename);
  }

  /// URL 다운로드 바이트 등 — FNV-1a content hash 기반 파일명으로 posters에 저장 (dedupe).
  Future<String?> importPosterImageBytesDeduped(
    Uint8List bytes, {
    required String extension,
  }) async {
    if (_vaultPath == null || bytes.isEmpty) return null;

    final ext = _normalizePosterExtension(extension);
    final digest = _hashPosterBytes(bytes);
    final filename = '${digest.substring(0, 16)}.$ext';
    final postersDir = Directory(p.join(_vaultPath!, 'posters'));
    await postersDir.create(recursive: true);

    final destinationPath = p.join(postersDir.path, filename);
    final relative = p.join('posters', filename);
    if (await File(destinationPath).exists()) {
      return relative.replaceAll('\\', '/');
    }

    await File(destinationPath).writeAsBytes(bytes, flush: true);
    return relative.replaceAll('\\', '/');
  }

  String _normalizePosterExtension(String extension) {
    final raw = extension.startsWith('.') ? extension.substring(1) : extension;
    final lower = raw.toLowerCase();
    return switch (lower) {
      'jpeg' => 'jpg',
      'jpg' || 'png' || 'webp' || 'gif' || 'bmp' => lower,
      _ => 'jpg',
    };
  }

  String _hashPosterBytes(Uint8List bytes) {
    var hash = 0xcbf29ce484222325;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
