part of 'file_service.dart';

mixin _AkashaFileServiceWatch on _AkashaFileServiceBase, _AkashaFileServicePaths {
  void _notifyVaultUpdated() {
    _vaultUpdateController?.add(null);
  }

  /// timeline 등 VaultPort 외 경로로 vault 파일이 바뀐 뒤 UI 갱신용.
  Future<void> signalVaultChanged() async {
    await _refreshVaultFingerprint();
    _notifyVaultUpdated();
  }

  void _scheduleVaultUpdateNotification() {
    _watchDebounce?.cancel();
    _watchDebounce = Timer(const Duration(milliseconds: 400), () async {
      await _refreshVaultFingerprint();
      _notifyVaultUpdated();
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

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
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
    try {
      _watcherSubscription = dir.watch(recursive: true).listen(
        (event) {
          if (_shouldNotifyForWatchEvent(event.path)) {
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
    }

    _startPolling();
  }

  void _fallbackToPolling() {
    if (!_directoryWatchActive && _pollTimer != null) return;
    _directoryWatchActive = false;
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _startPolling();
  }

  /// 테스트·watch 불안정 환경에서 fingerprint 폴링 fallback 강제.
  @visibleForTesting
  void forceVaultPollFallback() => _fallbackToPolling();

  bool _shouldNotifyForWatchEvent(String path) {
    if (_shouldSkipPath(path)) return false;
    final lower = path.toLowerCase();
    if (lower.endsWith('.md')) return true;
    // 에디터 atomic save 임시 파일
    if (lower.contains('.akasha_') || lower.endsWith('.tmp')) return true;
    return false;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_vaultPath == null) return;

    if (!VaultWatchPollPolicy.shouldRunPeriodicPoll(
      directoryWatchActive: _directoryWatchActive,
    )) {
      if (_lastVaultFingerprint == null) {
        unawaited(_refreshVaultFingerprint());
      }
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
    _stopPolling();
  }

  void dispose() {
    _stopWatching();
    _vaultUpdateController?.close();
    _vaultUpdateController = null;
  }
}
