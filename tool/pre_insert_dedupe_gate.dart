/// Pre-insert dedupe gate — wk_ · legacyIds · fuzzyTitle (dedupe_linter 정합).
library;

import 'dart:io';

import 'dedupe_utils.dart';
import 'discovery/registry_snapshot.dart';
import 'wk_id_utils.dart';

class PreInsertConflict {
  final String signal;
  final String candidateWorkId;
  final String matchedWorkId;
  final String detail;

  const PreInsertConflict({
    required this.signal,
    required this.candidateWorkId,
    required this.matchedWorkId,
    required this.detail,
  });

  @override
  String toString() =>
      '[$signal] $candidateWorkId -> $matchedWorkId ($detail)';
}

class PreInsertDedupeGate {
  final RegistrySnapshot registry;
  final Set<String> allowedPairs;
  final Map<String, Set<String>> franchisePeers;
  final Map<String, String> _legacyIdOwner;

  PreInsertDedupeGate({
    required this.registry,
    required this.allowedPairs,
    required this.franchisePeers,
  }) : _legacyIdOwner = _buildLegacyIndex(registry);

  static PreInsertDedupeGate load(Directory projectRoot) {
    return PreInsertDedupeGate(
      registry: RegistrySnapshot.load(projectRoot),
      allowedPairs: loadDedupeAllowedPairs(projectRoot),
      franchisePeers: loadFranchisePeers(projectRoot),
    );
  }

  /// Returns empty if insert is allowed.
  List<PreInsertConflict> check(Map<String, dynamic> candidate) {
    final workId = candidate['workId']?.toString() ?? '';
    if (workId.isEmpty) {
      return [
        const PreInsertConflict(
          signal: 'invalid',
          candidateWorkId: '',
          matchedWorkId: '',
          detail: 'missing workId',
        ),
      ];
    }

    final conflicts = <PreInsertConflict>[];

    if (registry.byWorkId.containsKey(workId)) {
      conflicts.add(
        PreInsertConflict(
          signal: 'workId',
          candidateWorkId: workId,
          matchedWorkId: workId,
          detail: 'workId already in registry',
        ),
      );
    }

    final legacyOwner = _legacyIdOwner[workId];
    if (legacyOwner != null && legacyOwner != workId) {
      conflicts.add(
        PreInsertConflict(
          signal: 'legacyIds',
          candidateWorkId: workId,
          matchedWorkId: legacyOwner,
          detail: 'workId listed as legacyIds on existing work',
        ),
      );
    }

    final candidateLegacy = _legacyIdsFrom(candidate);
    for (final legacy in candidateLegacy) {
      if (registry.byWorkId.containsKey(legacy)) {
        conflicts.add(
          PreInsertConflict(
            signal: 'legacyIds',
            candidateWorkId: workId,
            matchedWorkId: legacy,
            detail: 'legacyId already a registry workId',
          ),
        );
      }
      final owner = _legacyIdOwner[legacy];
      if (owner != null && owner != workId) {
        conflicts.add(
          PreInsertConflict(
            signal: 'legacyIds',
            candidateWorkId: workId,
            matchedWorkId: owner,
            detail: 'legacyId already claimed',
          ),
        );
      }
    }

    final extConflict = _checkExternalIds(workId, candidate);
    if (extConflict != null) conflicts.add(extConflict);

    final fuzzyConflict = _checkFuzzyTitle(workId, candidate);
    if (fuzzyConflict != null) conflicts.add(fuzzyConflict);

    return _dedupeConflicts(conflicts);
  }

  PreInsertConflict? _checkExternalIds(
    String workId,
    Map<String, dynamic> candidate,
  ) {
    final ext = candidate['externalIds'];
    if (ext is! Map) return null;
    final category = candidate['category']?.toString() ?? '';

    for (final entry in ext.entries) {
      final source = entry.key.toString().toLowerCase();
      final id = entry.value?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final key = '$source:$id';
      final hits = registry.byExternalKey[key] ?? const [];
      for (final hit in hits) {
        if (hit.category != category) continue;
        if (isPairAllowed(workId, hit.workId, allowedPairs)) continue;
        if (isFranchiseSibling(workId, hit.workId, franchisePeers)) continue;
        return PreInsertConflict(
          signal: 'externalId',
          candidateWorkId: workId,
          matchedWorkId: hit.workId,
          detail: key,
        );
      }
    }
    return null;
  }

  PreInsertConflict? _checkFuzzyTitle(
    String workId,
    Map<String, dynamic> candidate,
  ) {
    final category = candidate['category']?.toString() ?? '';
    final year = candidate['releaseYear'] is int
        ? candidate['releaseYear'] as int
        : int.tryParse(candidate['releaseYear']?.toString() ?? '');
    final norms = _normalizedTitlesFrom(candidate);

    for (final norm in norms) {
      if (norm.length < 2) continue;
      final key = '$category::$norm';
      final hits = registry.byTitleKey[key] ?? const [];
      for (final hit in hits) {
        if (hit.workId == workId) continue;
        if (!releaseYearsCompatible(year, hit.releaseYear)) continue;
        if (isPairAllowed(workId, hit.workId, allowedPairs)) continue;
        if (isFranchiseSibling(workId, hit.workId, franchisePeers)) continue;
        return PreInsertConflict(
          signal: 'fuzzyTitle',
          candidateWorkId: workId,
          matchedWorkId: hit.workId,
          detail: norm,
        );
      }
    }
    return null;
  }

  static Map<String, String> _buildLegacyIndex(RegistrySnapshot registry) {
    final index = <String, String>{};
    for (final w in registry.works) {
      for (final legacy in w.legacyIds) {
        index.putIfAbsent(legacy, () => w.workId);
      }
      if (!isWkId(w.workId)) {
        index.putIfAbsent(w.workId, () => w.workId);
      }
    }
    return index;
  }

  static List<String> _legacyIdsFrom(Map<String, dynamic> work) {
    final legacyIds = <String>[];
    final legacy = work['legacyIds'];
    if (legacy is List) {
      for (final id in legacy) {
        final s = id.toString();
        if (s.isNotEmpty) legacyIds.add(s);
      }
    }
    return legacyIds;
  }

  static Set<String> _normalizedTitlesFrom(Map<String, dynamic> work) {
    final normalized = <String>{};
    void addTitle(String? t) {
      if (t == null || t.isEmpty) return;
      final n = normalizeTitle(t);
      if (n.isNotEmpty) normalized.add(n);
    }

    addTitle(work['title']?.toString());
    final titles = work['titles'];
    if (titles is Map) {
      titles.forEach((_, v) => addTitle(v?.toString()));
    }
    final aliases = work['aliases'];
    if (aliases is List) {
      for (final a in aliases) {
        addTitle(a?.toString());
      }
    }
    return normalized;
  }

  static List<PreInsertConflict> _dedupeConflicts(
    List<PreInsertConflict> conflicts,
  ) {
    final seen = <String>{};
    final out = <PreInsertConflict>[];
    for (final c in conflicts) {
      final key = '${c.signal}|${c.candidateWorkId}|${c.matchedWorkId}';
      if (seen.add(key)) out.add(c);
    }
    return out;
  }
}
