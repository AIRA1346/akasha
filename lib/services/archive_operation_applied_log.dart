import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_operation.dart';
import 'vault_recovery_write_service.dart';

class ArchiveOperationAppliedEntry {
  const ArchiveOperationAppliedEntry({
    required this.operationId,
    required this.operationType,
    required this.source,
    required this.appliedAt,
    required this.result,
    this.targetRecordId,
    this.targetEntityId,
    this.candidateId,
    this.recordPath,
  });

  static const int schemaVersion = 1;

  final String operationId;
  final ArchiveOperationType operationType;
  final ArchiveOperationSource source;
  final DateTime appliedAt;
  final String result;
  final String? targetRecordId;
  final String? targetEntityId;
  final String? candidateId;
  final String? recordPath;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'operationId': operationId,
    'operationType': operationType.name,
    'source': source.name,
    'appliedAt': appliedAt.toUtc().toIso8601String(),
    'result': result,
    if (targetRecordId != null && targetRecordId!.isNotEmpty)
      'targetRecordId': targetRecordId,
    if (targetEntityId != null && targetEntityId!.isNotEmpty)
      'targetEntityId': targetEntityId,
    if (candidateId != null && candidateId!.isNotEmpty)
      'candidateId': candidateId,
    if (recordPath != null && recordPath!.isNotEmpty) 'recordPath': recordPath,
  };

  factory ArchiveOperationAppliedEntry.fromJson(Map<String, dynamic> json) {
    return ArchiveOperationAppliedEntry(
      operationId: json['operationId']?.toString() ?? '',
      operationType: _enumByName(
        ArchiveOperationType.values,
        json['operationType']?.toString(),
        ArchiveOperationType.createRecord,
      ),
      source: _enumByName(
        ArchiveOperationSource.values,
        json['source']?.toString(),
        ArchiveOperationSource.app,
      ),
      appliedAt:
          DateTime.tryParse(json['appliedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      result: json['result']?.toString() ?? '',
      targetRecordId: json['targetRecordId']?.toString(),
      targetEntityId: json['targetEntityId']?.toString(),
      candidateId: json['candidateId']?.toString(),
      recordPath: json['recordPath']?.toString(),
    );
  }

  static T _enumByName<T extends Enum>(
    Iterable<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

/// Append-only operation ledger at `{vault}/system/ops/applied.jsonl`.
///
/// Data boundary: idempotency guard — not rebuildable from Markdown.
/// Previously stored at `.akasha/ops/applied.jsonl` — migrated to
/// `system/ops/` to keep `.akasha/` 100% disposable.
///
/// Only successful operations are recorded here. Failed validation or rejected
/// writes stay out of the applied log so retries can still repair the archive.
class ArchiveOperationAppliedLog {
  const ArchiveOperationAppliedLog();

  static const String systemDirName = 'system';
  static const String opsDirName = 'ops';
  static const String appliedFileName = 'applied.jsonl';
  static const String appliedResult = 'applied';
  // Legacy path kept for migration only.
  static const String _legacyDirName = '.akasha';

  Future<ArchiveOperationAppliedEntry?> lookup(
    String vaultPath,
    String operationId,
  ) async {
    final id = operationId.trim();
    if (vaultPath.trim().isEmpty || id.isEmpty) return null;
    final file = _file(vaultPath);
    if (!await file.exists()) return null;

    ArchiveOperationAppliedEntry? match;
    for (final line in await file.readAsLines()) {
      try {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map) continue;
        final entry = ArchiveOperationAppliedEntry.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (entry.operationId == id) {
          match = entry;
        }
      } catch (_) {
        // A torn final JSONL append must not hide earlier applied operations.
      }
    }
    return match;
  }

  File _legacyFile(String vaultPath) =>
      File(p.join(vaultPath, _legacyDirName, opsDirName, appliedFileName));

  /// Copies old `.akasha/ops/applied.jsonl` to `system/ops/` without deleting original.
  Future<void> _migrateIfNeeded(String vaultPath) async {
    final newFile = _file(vaultPath);
    final oldFile = _legacyFile(vaultPath);

    if (await newFile.exists()) return; // already migrated
    if (!await oldFile.exists()) return; // no legacy file

    // copy → verify → leave old in place
    await VaultRecoveryWriteService().writeText(
      vaultPath: vaultPath,
      targetPath: newFile.path,
      content: await oldFile.readAsString(),
      reason: 'migrate_legacy_applied_operations_log',
      expectedRevision: const VaultFileRevision.missing(),
    );
    // Old file intentionally left at .akasha/ (not deleted).
  }

  Future<List<ArchiveOperationAppliedEntry>> load(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return const [];
    await _migrateIfNeeded(vaultPath);
    final file = _file(vaultPath);
    if (!await file.exists()) return const [];

    final entries = <ArchiveOperationAppliedEntry>[];
    for (final line in await file.readAsLines()) {
      try {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map) continue;
        final entry = ArchiveOperationAppliedEntry.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (entry.operationId.isNotEmpty) entries.add(entry);
      } catch (_) {
        // Keep valid earlier entries when an append was interrupted.
      }
    }
    return entries;
  }

  Future<ArchiveOperationAppliedEntry> appendApplied({
    required String vaultPath,
    required ArchiveOperation operation,
    String? recordPath,
    DateTime? appliedAt,
  }) async {
    await _migrateIfNeeded(vaultPath);
    final existing = await lookup(vaultPath, operation.operationId);
    if (existing != null) return existing;

    final entry = ArchiveOperationAppliedEntry(
      operationId: operation.operationId,
      operationType: operation.type,
      source: operation.source,
      appliedAt: appliedAt ?? DateTime.now().toUtc(),
      result: appliedResult,
      targetRecordId: operation.effectiveRecordId,
      targetEntityId: operation.targetEntity?.entityId,
      candidateId: operation.payload['candidateId']?.toString(),
      recordPath: _relativePathOrNull(vaultPath, recordPath),
    );

    await VaultRecoveryWriteService().appendJsonLine(
      vaultPath: vaultPath,
      targetPath: _file(vaultPath).path,
      entry: entry.toJson(),
    );
    return entry;
  }

  File _file(String vaultPath) =>
      File(p.join(vaultPath, systemDirName, opsDirName, appliedFileName));

  static String? _relativePathOrNull(String vaultPath, String? recordPath) {
    final path = recordPath?.trim();
    if (path == null || path.isEmpty) return null;
    return p.relative(path, from: vaultPath).replaceAll('\\', '/');
  }
}
