import '../core/archiving/entity_journal_entry.dart';

/// Classification for one Entity vault Markdown load issue.
enum EntityVaultIssueSeverity {
  error,
  warning,
  ignored,
}

class EntityVaultLoadIssue {
  const EntityVaultLoadIssue({
    required this.relativePath,
    required this.errorCode,
    required this.severity,
    this.diagnostic,
  });

  /// Vault-relative path using forward slashes.
  final String relativePath;

  /// Stable machine-readable code (see loader docs / tests).
  final String errorCode;

  final EntityVaultIssueSeverity severity;

  /// Optional short token (never Markdown body / exception text).
  final String? diagnostic;

  @override
  String toString() =>
      'EntityVaultLoadIssue($errorCode, $relativePath, $severity'
      '${diagnostic == null ? '' : ', $diagnostic'})';
}

class EntityVaultLoadResult {
  const EntityVaultLoadResult({
    required this.entries,
    required this.issues,
  });

  const EntityVaultLoadResult.empty()
    : entries = const [],
      issues = const [];

  final List<EntityJournalEntry> entries;
  final List<EntityVaultLoadIssue> issues;

  bool get hasIssues => issues.isNotEmpty;
}
