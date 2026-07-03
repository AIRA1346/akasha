import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_candidate.dart';
import '../core/archiving/archive_candidate_validator.dart';
import '../core/archiving/entity_anchor.dart';

/// Durable candidate layer — `{vault}/catalog/candidates.json`.
///
/// This keeps agent/import extraction separate from first-class archived
/// Entity journals until the user or operation service promotes it.
class ArchiveCandidateStore {
  ArchiveCandidateStore();

  static const int schemaVersion = 1;
  static const String catalogDirName = 'catalog';
  static const String fileName = 'candidates.json';

  Future<List<ArchiveCandidate>> load(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return const [];
    final file = _file(vaultPath);
    if (!await file.exists()) return const [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];
      final raw = decoded['candidates'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (entry) =>
                ArchiveCandidate.fromJson(Map<String, dynamic>.from(entry)),
          )
          .where(
            (candidate) =>
                ArchiveCandidateValidator.validateCandidate(candidate).isValid,
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<ArchiveCandidate>> openCandidates(String vaultPath) async {
    final candidates = await load(vaultPath);
    return candidates
        .where(
          (candidate) => candidate.status == ArchiveCandidateStatus.candidate,
        )
        .toList(growable: false);
  }

  Future<ArchiveCandidate?> lookup(String vaultPath, String candidateId) async {
    final id = candidateId.trim();
    if (id.isEmpty) return null;
    for (final candidate in await load(vaultPath)) {
      if (candidate.candidateId == id) return candidate;
    }
    return null;
  }

  Future<void> upsert({
    required String vaultPath,
    required ArchiveCandidate candidate,
  }) async {
    final validation = ArchiveCandidateValidator.validateCandidate(candidate);
    if (!validation.isValid) {
      throw ArgumentError(
        'Invalid archive candidate: '
        '${validation.errors.map((e) => e.code).join(', ')}',
      );
    }

    final candidates = await load(vaultPath);
    final next = <ArchiveCandidate>[
      for (final existing in candidates)
        if (existing.candidateId != candidate.candidateId) existing,
      candidate,
    ]..sort(_compare);
    await _write(vaultPath, next);
  }

  Future<void> markPromoted({
    required String vaultPath,
    required String candidateId,
    required String entityId,
    DateTime? updatedAt,
  }) async {
    await _updateCandidate(
      vaultPath: vaultPath,
      candidateId: candidateId,
      update: (candidate) =>
          candidate.markPromoted(entityId: entityId, updatedAt: updatedAt),
    );
  }

  Future<void> dismiss({
    required String vaultPath,
    required String candidateId,
    DateTime? updatedAt,
  }) async {
    await _updateCandidate(
      vaultPath: vaultPath,
      candidateId: candidateId,
      update: (candidate) => candidate.markDismissed(updatedAt: updatedAt),
    );
  }

  Future<void> markMerged({
    required String vaultPath,
    required String candidateId,
    required String duplicateOfEntityId,
    DateTime? updatedAt,
  }) async {
    await _updateCandidate(
      vaultPath: vaultPath,
      candidateId: candidateId,
      update: (candidate) => candidate.markMerged(
        duplicateOfEntityId: duplicateOfEntityId,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> _updateCandidate({
    required String vaultPath,
    required String candidateId,
    required ArchiveCandidate Function(ArchiveCandidate candidate) update,
  }) async {
    final candidates = await load(vaultPath);
    var changed = false;
    final next = <ArchiveCandidate>[
      for (final candidate in candidates)
        if (candidate.candidateId == candidateId.trim()) ...[
          _validateUpdated(update(candidate)),
        ] else
          candidate,
    ];
    changed = next.any(
      (candidate) =>
          candidate.candidateId == candidateId.trim() &&
          candidate.status != ArchiveCandidateStatus.candidate,
    );
    if (!changed) return;
    next.sort(_compare);
    await _write(vaultPath, next);
  }

  Future<void> _write(
    String vaultPath,
    List<ArchiveCandidate> candidates,
  ) async {
    if (vaultPath.trim().isEmpty) return;
    final dir = Directory(p.join(vaultPath, catalogDirName));
    await dir.create(recursive: true);

    final payload = <String, dynamic>{
      'version': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
    };

    final file = _file(vaultPath);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  File _file(String vaultPath) =>
      File(p.join(vaultPath, catalogDirName, fileName));

  static ArchiveCandidate _validateUpdated(ArchiveCandidate candidate) {
    final validation = ArchiveCandidateValidator.validateCandidate(candidate);
    if (!validation.isValid) {
      throw ArgumentError(
        'Invalid archive candidate update: '
        '${validation.errors.map((e) => e.code).join(', ')}',
      );
    }
    return candidate;
  }

  static int _compare(ArchiveCandidate a, ArchiveCandidate b) {
    final status = a.status.name.compareTo(b.status.name);
    if (status != 0) return status;
    final type = _entityTypeOrder(
      a.entityType,
    ).compareTo(_entityTypeOrder(b.entityType));
    if (type != 0) return type;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static int _entityTypeOrder(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.work => 0,
      EntityAnchorType.person => 1,
      EntityAnchorType.organization => 2,
      EntityAnchorType.place => 3,
      EntityAnchorType.event => 4,
      EntityAnchorType.concept => 5,
      EntityAnchorType.custom => 6,
      EntityAnchorType.phenomenon => 7,
    };
  }
}
