import 'package:path/path.dart' as p;

/// The semantic effect of one Vault-relative source-path change.
///
/// A move is represented as one [delete] and one [upsert] entry so consumers
/// can update path-keyed derived data without treating a filesystem path as a
/// durable record identity.
enum VaultPathChangeKind { upsert, delete }

class VaultPathChange {
  const VaultPathChange({required this.relativePath, required this.kind});

  /// Normalized, slash-separated path relative to the Vault root.
  final String relativePath;
  final VaultPathChangeKind kind;
}

/// A bounded description of a Vault change observed by the app or file watch.
///
/// [reconciliationRequired] means that the observer cannot safely describe the
/// complete change set (for example, a polling fallback or watch failure). It
/// is intentionally explicit: consumers must not pretend a path-specific
/// update is complete when it is not.
class VaultChangeBatch {
  const VaultChangeBatch({
    this.changes = const [],
    this.reconciliationRequired = false,
  }) : assert(reconciliationRequired || changes.length > 0);

  static const reconciliation = VaultChangeBatch(reconciliationRequired: true);

  final List<VaultPathChange> changes;
  final bool reconciliationRequired;

  bool get hasPrecisePaths => changes.isNotEmpty && !reconciliationRequired;

  factory VaultChangeBatch.fromAbsolutePaths({
    required String vaultPath,
    Iterable<String> upsertedPaths = const [],
    Iterable<String> deletedPaths = const [],
    bool reconciliationRequired = false,
  }) {
    final changes = <VaultPathChange>[];
    final seen = <String>{};

    void addAll(Iterable<String> paths, VaultPathChangeKind kind) {
      for (final path in paths) {
        final relative = _relativePath(vaultPath, path);
        final key = '${kind.name}:$relative';
        if (!seen.add(key)) continue;
        changes.add(VaultPathChange(relativePath: relative, kind: kind));
      }
    }

    addAll(deletedPaths, VaultPathChangeKind.delete);
    addAll(upsertedPaths, VaultPathChangeKind.upsert);
    return VaultChangeBatch(
      changes: List.unmodifiable(changes),
      reconciliationRequired: reconciliationRequired,
    );
  }

  static String _relativePath(String vaultPath, String absolutePath) {
    final root = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    if (!p.isWithin(root, target)) {
      throw ArgumentError.value(
        absolutePath,
        'absolutePath',
        'must stay within the Vault root',
      );
    }
    final relative = p.relative(target, from: root).replaceAll('\\', '/');
    if (relative.isEmpty || relative == '.') {
      throw ArgumentError.value(
        absolutePath,
        'absolutePath',
        'must identify a file below the Vault root',
      );
    }
    return relative;
  }
}
