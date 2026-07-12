class ReconciliationCursor {
  const ReconciliationCursor({
    required this.provider,
    required this.highWaterMark,
    required this.updatedAt,
  });

  /// e.g. `steam_getreport`
  final String provider;

  /// Opaque cursor / last time / last row id processed.
  final String highWaterMark;
  final DateTime updatedAt;
}
