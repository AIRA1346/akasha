import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_operation.dart';
import '../core/archiving/entity_anchor.dart';
import '../core/archiving/record_kind.dart';
import '../core/archiving/vault_file_revision.dart';
import '../models/enums.dart';
import 'record_summary_index_service.dart';
import 'vault_record_path_resolver.dart';

class ArchiveRecordRevision {
  const ArchiveRecordRevision({
    required this.value,
    required this.exists,
    this.absolutePath,
  });

  static const String missing = 'missing';

  final String value;
  final bool exists;
  final String? absolutePath;
}

/// Computes lightweight optimistic-concurrency revisions for vault records.
///
/// Revisions are derived from the Markdown file on disk, not from indexes.
/// They are intentionally opaque to callers; agents should echo the value they
/// observed through a future scoped read/query surface.
class ArchiveRecordRevisionService {
  const ArchiveRecordRevisionService();

  Future<ArchiveRecordRevision> currentForOperation({
    required String vaultPath,
    required ArchiveOperation operation,
  }) async {
    final targetPath = await _resolveTargetPath(
      vaultPath: vaultPath,
      operation: operation,
    );
    if (targetPath == null || targetPath.trim().isEmpty) {
      return const ArchiveRecordRevision(
        value: ArchiveRecordRevision.missing,
        exists: false,
      );
    }
    return currentForPath(targetPath);
  }

  Future<ArchiveRecordRevision> currentForPath(String absolutePath) async {
    final path = absolutePath.trim();
    if (path.isEmpty) {
      return const ArchiveRecordRevision(
        value: ArchiveRecordRevision.missing,
        exists: false,
      );
    }

    final file = File(path);
    if (!await file.exists()) {
      return ArchiveRecordRevision(
        value: ArchiveRecordRevision.missing,
        exists: false,
        absolutePath: path,
      );
    }

    final revision = await VaultFileRevision.fromFile(file);
    return ArchiveRecordRevision(
      // The user-visible expected revision intentionally excludes mtime. A
      // cloud-sync touch or metadata-only timestamp change must not create a
      // semantic write conflict when SHA-256 and byte length are unchanged.
      value: 'v2:sha256:${revision.sha256};bytes:${revision.byteLength}',
      exists: true,
      absolutePath: path,
    );
  }

  /// Resolves one already-indexed record and reads its current on-disk
  /// revision. This deliberately does not fall back to a Vault-wide scan:
  /// Gateway requests must name an explicit, bounded source record.
  Future<ArchiveRecordRevision> currentForRecordId({
    required String vaultPath,
    required String recordId,
  }) async {
    final id = recordId.trim();
    if (vaultPath.trim().isEmpty || id.isEmpty) {
      return const ArchiveRecordRevision(
        value: ArchiveRecordRevision.missing,
        exists: false,
      );
    }

    final summary = await RecordSummaryIndexService().lookupById(vaultPath, id);
    if (summary == null || summary.relativePath.trim().isEmpty) {
      return const ArchiveRecordRevision(
        value: ArchiveRecordRevision.missing,
        exists: false,
      );
    }
    return currentForPath(
      p.joinAll([vaultPath, ...summary.relativePath.split('/')]),
    );
  }

  Future<String?> _resolveTargetPath({
    required String vaultPath,
    required ArchiveOperation operation,
  }) async {
    final entity = operation.targetEntity;
    if (entity != null) {
      final byEntity = _pathForEntity(vaultPath, operation, entity);
      if (byEntity != null) return byEntity;
    }

    final recordId = operation.effectiveRecordId;
    if (recordId == null || recordId.trim().isEmpty) return null;
    final summary = await RecordSummaryIndexService().lookupById(
      vaultPath,
      recordId,
    );
    if (summary == null || summary.relativePath.trim().isEmpty) return null;
    return p.joinAll([vaultPath, ...summary.relativePath.split('/')]);
  }

  String? _pathForEntity(
    String vaultPath,
    ArchiveOperation operation,
    EntityAnchor entity,
  ) {
    if (operation.recordKind == RecordKind.entityJournal &&
        entity.type != EntityAnchorType.work) {
      return VaultRecordPathResolver.resolveEntityPath(
        vaultRoot: vaultPath,
        entityType: entity.type,
        entityId: entity.entityId,
        title: operation.title ?? entity.entityId,
      );
    }

    if (operation.recordKind == RecordKind.workJournal &&
        entity.type == EntityAnchorType.work) {
      return VaultRecordPathResolver.resolveWorkPath(
        vaultRoot: vaultPath,
        workId: entity.entityId,
        category: _categoryFromPayload(operation.payload),
        title: operation.title ?? entity.entityId,
        useWorksLayout: true,
      );
    }

    return null;
  }

  static MediaCategory _categoryFromPayload(Map<String, dynamic> payload) {
    final raw = payload['category']?.toString();
    for (final category in MediaCategory.values) {
      if (category.name == raw) return category;
    }
    return MediaCategory.manga;
  }
}
