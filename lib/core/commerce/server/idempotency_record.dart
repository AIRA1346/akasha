class IdempotencyRecord {
  const IdempotencyRecord({
    required this.key,
    required this.scope,
    required this.createdAt,
    this.resultRef,
  });

  final String key;
  final String scope;
  final DateTime createdAt;

  /// Optional pointer to order id / ledger entry id produced by the first call.
  final String? resultRef;
}
