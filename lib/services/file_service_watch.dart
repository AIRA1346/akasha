part of 'file_service.dart';

mixin _AkashaFileServiceWatch
    on _AkashaFileServiceBase, _AkashaFileServicePaths {
  void _notifyVaultUpdated([VaultChangeBatch? change]) {
    final resolvedChange = change ?? VaultChangeBatch.reconciliation;
    _vaultUpdateController?.add(null);
    _vaultChangeController?.add(resolvedChange);
  }

  /// timeline 등 VaultPort 외 경로로 vault 파일이 바뀐 뒤 UI 갱신용.
  Future<void> signalVaultChanged() async {
    _lastVaultFingerprint = null;
    _notifyVaultUpdated();
  }

  /// Publishes a source-path-aware app-originated change without scanning the
  /// complete Vault to rebuild a fingerprint.
  Future<void> signalVaultChange(VaultChangeBatch change) async {
    _lastVaultFingerprint = null;
    _notifyVaultUpdated(change);
  }

  void _scheduleVaultUpdateNotification() {
    _watchDebounce?.cancel();
    _watchDebounce = Timer(const Duration(milliseconds: 400), () {
      _notifyVaultUpdated(_drainWatchChangeBatch());
    });
  }

  Future<void> _refreshVaultFingerprint() async {
    _lastVaultFingerprint = await _computeVaultFingerprint();
  }

  Future<String> _computeVaultFingerprint() async {
    if (_vaultPath == null) return '';

    final parts = <String>[];
    try {
      final dir = Directory(_vaultPath!);
      if (!await dir.exists()) return '';

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !entity.path.endsWith('.md')) continue;
        if (_shouldSkipPath(entity.path)) continue;
        final stat = await entity.stat();
        parts.add(
          '${entity.path}|${stat.modified.millisecondsSinceEpoch}|${stat.size}',
        );
      }
    } catch (e) {
      appLog('[AkashaFileService] fingerprint error: $e');
    }
    parts.sort();
    return parts.join('\n');
  }

  Future<void> _pollVaultChanges() async {
    if (_vaultPath == null) return;
    final fp = await _computeVaultFingerprint();
    if (_lastVaultFingerprint == null) {
      _lastVaultFingerprint = fp;
      return;
    }
    if (fp != _lastVaultFingerprint) {
      _lastVaultFingerprint = fp;
      _notifyVaultUpdated();
    }
  }

  /// 볼트의 마크다운 파일 변경 감지를 위한 파일 감시를 시작합니다.
  void _startWatching() {
    _stopWatching();
    if (_vaultPath == null) return;

    final dir = Directory(_vaultPath!);
    if (!dir.existsSync()) return;

    _directoryWatchActive = false;
    var watchUnavailable = false;
    try {
      _watcherSubscription = dir
          .watch(recursive: true)
          .listen(
            (event) {
              if (_recordWatchEvent(event)) {
                _scheduleVaultUpdateNotification();
              }
            },
            onError: (error) {
              appLog('[AkashaFileService] Directory watch error: $error');
              _fallbackToPolling();
            },
            onDone: () {
              appLog('[AkashaFileService] Directory watch ended');
              _fallbackToPolling();
            },
          );
      _directoryWatchActive = true;
    } catch (e) {
      appLog('[AkashaFileService] Failed to start directory watch: $e');
      _directoryWatchActive = false;
      watchUnavailable = true;
    }

    if (watchUnavailable) {
      _notifyVaultUpdated();
    }
    _startPolling();
  }

  void _fallbackToPolling() {
    if (!_directoryWatchActive && _pollTimer != null) return;
    _directoryWatchActive = false;
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _pendingWatchChanges.clear();
    _pendingWatchReconciliation = false;
    _notifyVaultUpdated();
    _startPolling();
  }

  /// 테스트·watch 불안정 환경에서 fingerprint 폴링 fallback 강제.
  @visibleForTesting
  void forceVaultPollFallback() => _fallbackToPolling();

  bool _recordWatchEvent(FileSystemEvent event) {
    var recorded = false;
    if (event is FileSystemMoveEvent) {
      recorded = _recordWatchPath(event.path, VaultPathChangeKind.delete);
      final destination = event.destination;
      if (destination != null) {
        recorded =
            _recordWatchPath(destination, VaultPathChangeKind.upsert) ||
            recorded;
      } else {
        _pendingWatchReconciliation = true;
      }
      return recorded || _pendingWatchReconciliation;
    }

    final kind = event.type & FileSystemEvent.delete != 0
        ? VaultPathChangeKind.delete
        : VaultPathChangeKind.upsert;
    return _recordWatchPath(event.path, kind);
  }

  bool _recordWatchPath(String path, VaultPathChangeKind kind) {
    if (!_isTrackedVaultSourcePath(path)) return false;
    final relative = _relativeVaultPath(path);
    if (relative == null) {
      _pendingWatchReconciliation = true;
      return true;
    }
    _pendingWatchChanges[relative] = kind;
    return true;
  }

  VaultChangeBatch _drainWatchChangeBatch() {
    final changes = _pendingWatchChanges.entries
        .map(
          (entry) =>
              VaultPathChange(relativePath: entry.key, kind: entry.value),
        )
        .toList(growable: false);
    final reconciliationRequired = _pendingWatchReconciliation;
    _pendingWatchChanges.clear();
    _pendingWatchReconciliation = false;
    if (changes.isEmpty && !reconciliationRequired) {
      return VaultChangeBatch.reconciliation;
    }
    return VaultChangeBatch(
      changes: changes,
      reconciliationRequired: reconciliationRequired,
    );
  }

  bool _isTrackedVaultSourcePath(String path) {
    if (_shouldSkipPath(path)) return false;
    final lower = path.toLowerCase();
    if (lower.endsWith('.md')) return true;
    final parts = p.split(p.normalize(path));
    return p.basename(lower) == 'layout.json' && parts.contains('canvases');
  }

  String? _relativeVaultPath(String path) {
    final vaultPath = _vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return null;
    final root = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(path));
    if (!p.isWithin(root, target)) return null;
    final relative = p.relative(target, from: root).replaceAll('\\', '/');
    return relative.isEmpty || relative == '.' ? null : relative;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_vaultPath == null) return;

    if (!VaultWatchPollPolicy.shouldRunPeriodicPoll(
      directoryWatchActive: _directoryWatchActive,
    )) {
      return;
    }

    _lastVaultFingerprint = null;
    _pollTimer = Timer.periodic(AkashaFileService.vaultPollInterval, (_) {
      _pollVaultChanges();
    });
    unawaited(_pollVaultChanges());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastVaultFingerprint = null;
  }

  void _stopWatching() {
    _watchDebounce?.cancel();
    _watchDebounce = null;
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _directoryWatchActive = false;
    _pendingWatchChanges.clear();
    _pendingWatchReconciliation = false;
    _stopPolling();
  }

  void dispose() {
    _stopWatching();
    _vaultUpdateController?.close();
    _vaultUpdateController = null;
    _vaultChangeController?.close();
    _vaultChangeController = null;
  }
}
