/// Boundary for multi-step persistence (orders + ledger + idempotency + audit).
abstract class CommerceUnitOfWork {
  Future<T> runInTransaction<T>(Future<T> Function() body);
}
