/// Wave 6 W6-1 — append-only vault event ledger entry.
enum VaultLedgerEventType {
  recordSaved,
  recordDeleted,
  linkIndexRebuilt,
  vaultReloaded,
  catalogUpdated,
}

class VaultLedgerEvent {
  const VaultLedgerEvent({
    this.version = schemaVersion,
    required this.type,
    required this.at,
    this.path,
    this.meta = const {},
  });

  static const int schemaVersion = 1;

  final int version;
  final VaultLedgerEventType type;
  final DateTime at;
  final String? path;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toJson() => {
        'version': version,
        'type': type.name,
        'at': at.toUtc().toIso8601String(),
        if (path != null && path!.isNotEmpty) 'path': path,
        if (meta.isNotEmpty) 'meta': meta,
      };

  factory VaultLedgerEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? '';
    final type = VaultLedgerEventType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => VaultLedgerEventType.recordSaved,
    );
    return VaultLedgerEvent(
      version: (json['version'] as num?)?.toInt() ?? schemaVersion,
      type: type,
      at: DateTime.tryParse(json['at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      path: json['path']?.toString(),
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : const {},
    );
  }
}
