/// Serializes one operation ID within one local Vault process.
///
/// Durable receipts remain the source of idempotency across restarts. This
/// small in-process coordinator closes the read-before-append race between
/// Gateway and app operation paths so two concurrent same-ID requests cannot
/// both become successful receipts.
class ArchiveOperationIdempotencyCoordinator {
  ArchiveOperationIdempotencyCoordinator._();

  static final Map<String, Future<void>> _tails = {};

  static Future<T> run<T>({
    required String vaultPath,
    required String operationId,
    required Future<T> Function() action,
  }) {
    final key = '${vaultPath.trim()}\u0000${operationId.trim()}';
    final previous = _tails[key] ?? Future<void>.value();
    final result = previous.then<T>(
      (_) => action(),
      onError: (_, _) => action(),
    );
    final tail = result.then<void>((_) {}, onError: (_, _) {});
    _tails[key] = tail;
    tail.whenComplete(() {
      if (identical(_tails[key], tail)) _tails.remove(key);
    });
    return result;
  }
}
