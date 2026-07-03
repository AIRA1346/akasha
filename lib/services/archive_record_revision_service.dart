import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_operation.dart';
import '../core/archiving/entity_anchor.dart';
import '../core/archiving/record_kind.dart';
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

    final modified = (await file.lastModified()).toUtc();
    final bytes = await file.readAsBytes();
    final digest = _fnv1a64(bytes);
    return ArchiveRecordRevision(
      value: 'v1:${modified.microsecondsSinceEpoch}:${bytes.length}:$digest',
      exists: true,
      absolutePath: path,
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

  static String _fnv1a64(List<int> bytes) {
    var hash = 0xcbf29ce484222325;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
