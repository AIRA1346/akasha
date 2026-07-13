/// Ordered vault-watch fan-out with dispose/generation cancellation.
///
/// Owns only fan-out sequencing and lifecycle gates — not vault subscription,
/// debounce, or workbench/navigation state.
class HomeVaultWatchReactor {
  int _generation = 0;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// Invalidates in-flight fan-outs and rejects new work.
  ///
  /// Safe to call more than once.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  /// Runs apply → recent refresh → entity-tab sync → timeline bump.
  ///
  /// Each `await` is followed by a generation check; disposed or superseded
  /// work stops before later side effects.
  Future<void> onVaultChanged({
    required Future<void> Function() applyVaultChange,
    required Future<void> Function() refreshRecentExploration,
    required Future<void> Function() syncEntityTabs,
    required void Function() bumpTimelineReload,
  }) async {
    if (_disposed) return;
    final generation = _generation;

    await applyVaultChange();
    if (!_isCurrent(generation)) return;

    await refreshRecentExploration();
    if (!_isCurrent(generation)) return;

    await syncEntityTabs();
    if (!_isCurrent(generation)) return;

    bumpTimelineReload();
  }
}
