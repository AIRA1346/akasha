import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_vault.dart';
import '../core/ports/vault_change.dart';
import '../core/ports/vault_port.dart';
import '../models/akasha_item.dart';
import 'local_derived_index_store.dart';
import 'local_derived_index_synchronizer.dart';
import 'record_summary_index_service.dart';

/// App-owned lifecycle boundary for the rebuildable Work-summary cache.
///
/// It never performs a hidden full Vault scan. Rebuild is explicit through
/// [rebuildWorkSummaries]; ordinary precise Vault changes update only their
/// reported source paths. An ambiguous change transitions a ready cache to
/// repair-required instead of guessing or calling `loadAllItems`.
class LocalDerivedIndexLifecycle {
  LocalDerivedIndexLifecycle({
    VaultPort? vault,
    LocalDerivedIndexStore? store,
    LocalDerivedIndexSynchronizer? synchronizer,
    Future<String> Function()? cacheRootResolver,
  }) : _vault = vault ?? AppVault.port,
       _store = store ?? LocalDerivedIndexStore(),
       _synchronizer =
           synchronizer ?? LocalDerivedIndexSynchronizer(store: store),
       _cacheRootResolver = cacheRootResolver ?? _resolveApplicationCacheRoot;

  static final LocalDerivedIndexLifecycle app = LocalDerivedIndexLifecycle();

  final VaultPort _vault;
  final LocalDerivedIndexStore _store;
  final LocalDerivedIndexSynchronizer _synchronizer;
  final Future<String> Function() _cacheRootResolver;
  final StreamController<LocalDerivedIndexLifecycleStatus> _statusController =
      StreamController<LocalDerivedIndexLifecycleStatus>.broadcast();

  StreamSubscription<VaultChangeBatch>? _vaultChanges;
  Future<void> _serial = Future.value();
  LocalDerivedIndexLifecycleStatus _status =
      const LocalDerivedIndexLifecycleStatus.inactive();
  _RebuildCancellation? _activeCancellation;
  String? _boundVaultPath;
  String? _cacheRoot;
  bool _started = false;
  bool _disposed = false;

  LocalDerivedIndexLifecycleStatus get status => _status;
  Stream<LocalDerivedIndexLifecycleStatus> get statuses =>
      _statusController.stream;

  /// Opens/binds the derived cache for the current Vault and begins listening
  /// for SA-01 detailed change batches. It never starts a rebuild by itself.
  Future<void> start() async {
    _ensureNotDisposed();
    if (!_started) {
      _started = true;
      _vaultChanges = _vault.onVaultChanges.listen(
        (change) => unawaited(handleVaultChange(change)),
        onError: (_, _) => unawaited(
          _enqueue(() => _markRepairRequired('vault_change_stream_error')),
        ),
      );
    }
    await _enqueue(_refreshBinding);
  }

  /// Re-reads the current Vault binding and derived-cache trust state.
  Future<void> refresh() {
    _ensureNotDisposed();
    return _enqueue(_refreshBinding);
  }

  /// Applies one detailed Vault change through the same serialized path used
  /// by the live watcher. Exposed for non-UI repair/import integrations.
  Future<void> handleVaultChange(VaultChangeBatch change) {
    _ensureNotDisposed();
    return _enqueue(() => _applyVaultChange(change));
  }

  /// Deliberately rebuilds Work summaries with progress and cancellation.
  Future<WorkSummaryRebuildResult> rebuildWorkSummaries({
    void Function(WorkSummaryRebuildProgress progress)? onProgress,
  }) {
    _ensureNotDisposed();
    return _enqueue(() async {
      await _refreshBinding();
      final vaultPath = _boundVaultPath;
      final cacheRoot = _cacheRoot;
      if (vaultPath == null || cacheRoot == null) {
        throw StateError('A linked Vault is required to rebuild summaries.');
      }

      final cancellation = _RebuildCancellation();
      _activeCancellation = cancellation;
      _setStatus(
        LocalDerivedIndexLifecycleStatus.rebuilding(vaultPath: vaultPath),
      );
      try {
        final result = await _synchronizer.rebuildWorkSummaries(
          cacheRoot: cacheRoot,
          vaultPath: vaultPath,
          onProgress: onProgress,
          isCancelled: () => cancellation.isCancelled,
        );
        await _refreshBinding();
        return result;
      } catch (_) {
        await _refreshBinding();
        rethrow;
      } finally {
        if (identical(_activeCancellation, cancellation)) {
          _activeCancellation = null;
        }
      }
    });
  }

  /// Requests cancellation of the active explicit rebuild.
  ///
  /// The synchronizer marks the derived cache repair-required, so any partial
  /// batch cannot be queried as if it were an archive result.
  void cancelRebuild() => _activeCancellation?.cancel();

  /// Reads one bounded summary page only when the cache is verified ready.
  Future<WorkSummaryPage> queryWorkSummaries({
    WorkSummaryQuery query = const WorkSummaryQuery(),
  }) {
    _ensureNotDisposed();
    return _enqueue(() async {
      await _refreshBinding();
      final vaultPath = _boundVaultPath;
      final cacheRoot = _cacheRoot;
      if (_status.state != LocalDerivedIndexLifecycleState.ready ||
          vaultPath == null ||
          cacheRoot == null) {
        throw StateError('Work summary cache is not ready for queries.');
      }
      final database = await _store.open(
        cacheRoot: cacheRoot,
        vaultPath: vaultPath,
      );
      try {
        return await _store.queryWorkSummaries(
          database: database,
          query: query,
        );
      } finally {
        await database.close();
      }
    });
  }

  /// Resolves a stable Work ID to its cached locator, then reads exactly that
  /// canonical Markdown source. The returned item is never a partial summary.
  Future<SelectedWorkHydration> hydrateSelectedWork(String workId) {
    _ensureNotDisposed();
    return _enqueue(() async {
      await _refreshBinding();
      final vaultPath = _boundVaultPath;
      final cacheRoot = _cacheRoot;
      if (_status.state != LocalDerivedIndexLifecycleState.ready ||
          vaultPath == null ||
          cacheRoot == null) {
        return const SelectedWorkHydration.cacheUnavailable();
      }
      final database = await _store.open(
        cacheRoot: cacheRoot,
        vaultPath: vaultPath,
      );
      VaultRecordSummary? summary;
      try {
        summary = await _store.findWorkSummaryById(
          database: database,
          workId: workId,
        );
      } finally {
        await database.close();
      }
      if (summary == null) return const SelectedWorkHydration.notFound();

      final item = await _vault.loadItemByRelativePath(summary.relativePath);
      if (item == null) {
        await _markRepairRequired('selected_source_unreadable');
        return SelectedWorkHydration.sourceUnavailable(
          relativePath: summary.relativePath,
        );
      }
      if (item.workId != summary.id) {
        await _markRepairRequired('selected_source_identity_mismatch');
        return SelectedWorkHydration.identityMismatch(
          relativePath: summary.relativePath,
        );
      }
      return SelectedWorkHydration.hydrated(
        item: item,
        relativePath: summary.relativePath,
      );
    });
  }

  /// Resolves a bounded set of visual Work summaries for card-level
  /// enrichment. It never opens Markdown sources or returns editable Works.
  Future<List<VaultRecordSummary>> findWorkSummariesByIds(
    Iterable<String> workIds,
  ) {
    _ensureNotDisposed();
    return _enqueue(() async {
      await _refreshBinding();
      final vaultPath = _boundVaultPath;
      final cacheRoot = _cacheRoot;
      if (_status.state != LocalDerivedIndexLifecycleState.ready ||
          vaultPath == null ||
          cacheRoot == null) {
        throw StateError('Work summary cache is not ready for queries.');
      }
      final database = await _store.open(
        cacheRoot: cacheRoot,
        vaultPath: vaultPath,
      );
      try {
        return await _store.findWorkSummariesByIds(
          database: database,
          workIds: workIds,
        );
      } finally {
        await database.close();
      }
    });
  }

  Future<void> _applyVaultChange(VaultChangeBatch change) async {
    await _refreshBinding();
    final vaultPath = _boundVaultPath;
    final cacheRoot = _cacheRoot;
    if (vaultPath == null || cacheRoot == null) return;

    if (change.reconciliationRequired) {
      if (_status.state == LocalDerivedIndexLifecycleState.rebuildRequired) {
        return;
      }
      await _markRepairRequired('vault_reconciliation_required');
      return;
    }
    if (_status.state != LocalDerivedIndexLifecycleState.ready) {
      return;
    }

    try {
      for (final pathChange in change.changes) {
        final absolutePath = p.joinAll([
          vaultPath,
          ...p.split(pathChange.relativePath),
        ]);
        await _synchronizer.syncSourcePath(
          cacheRoot: cacheRoot,
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
      }
      await _refreshBinding();
    } catch (_) {
      await _refreshBinding();
      rethrow;
    }
  }

  Future<void> _refreshBinding() async {
    final rawVaultPath = _vault.vaultPath?.trim();
    if (rawVaultPath == null || rawVaultPath.isEmpty) {
      _boundVaultPath = null;
      _cacheRoot = null;
      _setStatus(const LocalDerivedIndexLifecycleStatus.inactive());
      return;
    }

    final vaultPath = LocalDerivedIndexStore.normalizedVaultRoot(rawVaultPath);
    try {
      _cacheRoot ??= await _cacheRootResolver();
      _boundVaultPath = vaultPath;
      final database = await _store.open(
        cacheRoot: _cacheRoot!,
        vaultPath: vaultPath,
      );
      try {
        final cacheStatus = await _store.readWorkSummaryCacheStatus(
          database: database,
        );
        if (cacheStatus.state == WorkSummaryCacheState.rebuilding) {
          await _store.markWorkSummaryRepairRequired(
            database: database,
            failureReason: 'rebuild_interrupted',
            generation: cacheStatus.generation,
          );
          _setStatus(
            LocalDerivedIndexLifecycleStatus.repairRequired(
              vaultPath: vaultPath,
              reason: 'rebuild_interrupted',
            ),
          );
          return;
        }
        _setStatus(
          LocalDerivedIndexLifecycleStatus.fromCacheStatus(
            vaultPath: vaultPath,
            cacheStatus: cacheStatus,
          ),
        );
      } finally {
        await database.close();
      }
    } catch (_) {
      _setStatus(
        LocalDerivedIndexLifecycleStatus.repairRequired(
          vaultPath: vaultPath,
          reason: 'cache_open_failed',
        ),
      );
      rethrow;
    }
  }

  Future<void> _markRepairRequired(String reason) async {
    final vaultPath = _boundVaultPath;
    final cacheRoot = _cacheRoot;
    if (vaultPath == null || cacheRoot == null) return;
    try {
      final database = await _store.open(
        cacheRoot: cacheRoot,
        vaultPath: vaultPath,
      );
      try {
        await _store.markWorkSummaryRepairRequired(
          database: database,
          failureReason: reason,
        );
      } finally {
        await database.close();
      }
    } finally {
      _setStatus(
        LocalDerivedIndexLifecycleStatus.repairRequired(
          vaultPath: vaultPath,
          reason: reason,
        ),
      );
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _serial.then((_) => operation());
    _serial = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  void _setStatus(LocalDerivedIndexLifecycleStatus next) {
    _status = next;
    if (!_disposed) _statusController.add(next);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _activeCancellation?.cancel();
    await _vaultChanges?.cancel();
    await _statusController.close();
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('LocalDerivedIndexLifecycle is disposed.');
  }

  static Future<String> _resolveApplicationCacheRoot() async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }
}

enum LocalDerivedIndexLifecycleState {
  inactive,
  rebuildRequired,
  rebuilding,
  ready,
  repairRequired,
}

class LocalDerivedIndexLifecycleStatus {
  const LocalDerivedIndexLifecycleStatus._({
    required this.state,
    this.vaultPath,
    this.reason,
  });

  const LocalDerivedIndexLifecycleStatus.inactive()
    : this._(state: LocalDerivedIndexLifecycleState.inactive);

  const LocalDerivedIndexLifecycleStatus.rebuilding({required String vaultPath})
    : this._(
        state: LocalDerivedIndexLifecycleState.rebuilding,
        vaultPath: vaultPath,
      );

  const LocalDerivedIndexLifecycleStatus.repairRequired({
    required String vaultPath,
    required String reason,
  }) : this._(
         state: LocalDerivedIndexLifecycleState.repairRequired,
         vaultPath: vaultPath,
         reason: reason,
       );

  factory LocalDerivedIndexLifecycleStatus.fromCacheStatus({
    required String vaultPath,
    required WorkSummaryCacheStatus cacheStatus,
  }) {
    final state = switch (cacheStatus.state) {
      WorkSummaryCacheState.rebuildRequired =>
        LocalDerivedIndexLifecycleState.rebuildRequired,
      WorkSummaryCacheState.rebuilding =>
        LocalDerivedIndexLifecycleState.repairRequired,
      WorkSummaryCacheState.ready => LocalDerivedIndexLifecycleState.ready,
      WorkSummaryCacheState.repairRequired =>
        LocalDerivedIndexLifecycleState.repairRequired,
    };
    return LocalDerivedIndexLifecycleStatus._(
      state: state,
      vaultPath: vaultPath,
      reason:
          cacheStatus.failureReason ??
          (cacheStatus.state == WorkSummaryCacheState.rebuilding
              ? 'rebuild_interrupted'
              : null),
    );
  }

  final LocalDerivedIndexLifecycleState state;
  final String? vaultPath;
  final String? reason;
}

enum SelectedWorkHydrationState {
  hydrated,
  cacheUnavailable,
  notFound,
  sourceUnavailable,
  identityMismatch,
}

class SelectedWorkHydration {
  const SelectedWorkHydration._({
    required this.state,
    this.item,
    this.relativePath,
  });

  const SelectedWorkHydration.cacheUnavailable()
    : this._(state: SelectedWorkHydrationState.cacheUnavailable);

  const SelectedWorkHydration.notFound()
    : this._(state: SelectedWorkHydrationState.notFound);

  const SelectedWorkHydration.sourceUnavailable({required String relativePath})
    : this._(
        state: SelectedWorkHydrationState.sourceUnavailable,
        relativePath: relativePath,
      );

  const SelectedWorkHydration.identityMismatch({required String relativePath})
    : this._(
        state: SelectedWorkHydrationState.identityMismatch,
        relativePath: relativePath,
      );

  const SelectedWorkHydration.hydrated({
    required AkashaItem item,
    required String relativePath,
  }) : this._(
         state: SelectedWorkHydrationState.hydrated,
         item: item,
         relativePath: relativePath,
       );

  final SelectedWorkHydrationState state;
  final AkashaItem? item;
  final String? relativePath;
}

class _RebuildCancellation {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() => _isCancelled = true;
}
