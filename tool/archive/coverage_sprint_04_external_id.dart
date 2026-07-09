// ignore_for_file: avoid_print
// Sprint 04 externalId G2 enrich runner.
//
// Usage:
//   dart run tool/archive/coverage_sprint_04_external_id.dart --dry-run
//   dart run tool/archive/coverage_sprint_04_external_id.dart --apply --phase tmdb
//   dart run tool/archive/coverage_sprint_04_external_id.dart --apply --phase steam --batch-size 50
//
// Scope:
// - E2 TMDB poster cohort: posterPath resolved through tmdb_poster_cache.json.
// - E1 Steam cohort: posterPath or legacyIds appid.
// - No network fetch, no new provider, no schema change.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../poster_verification.dart';
import '../quality_loop_utils.dart';

const _targetExternalIdCount = 201;

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || !args.contains('--apply');
  final apply = args.contains('--apply');
  final phase = _argValue(args, '--phase') ?? 'auto';
  final batchSize = int.tryParse(_argValue(args, '--batch-size') ?? '') ?? 9999;

  if (!{'auto', 'tmdb', 'steam'}.contains(phase)) {
    stderr.writeln('ERROR: --phase must be one of auto, tmdb, steam');
    exit(64);
  }
  if (batchSize <= 0) {
    stderr.writeln('ERROR: --batch-size must be > 0');
    exit(64);
  }

  final root = _findProjectRoot();
  final manifest = _loadManifest(root);
  final shardFiles = _loadShardFiles(root, manifest);
  final tmdbCache = _loadTmdbPosterCache(root);
  final tmdbReverse = _buildTmdbReverseCache(tmdbCache);

  final works =
      shardFiles
          .expand(
            (s) => s.works.entries.map((e) {
              final work = Map<String, dynamic>.from(e.value as Map);
              final workId = work['workId']?.toString() ?? e.key;
              return _WorkRef(s, workId, work);
            }),
          )
          .toList()
        ..sort((a, b) => a.workId.compareTo(b.workId));

  final currentExternal = works
      .where((w) => _externalIds(w.work).isNotEmpty)
      .length;
  final remaining = (_targetExternalIdCount - currentExternal).clamp(
    0,
    works.length,
  );
  final candidates = _buildCandidates(
    works,
    tmdbReverse,
  ).where((c) => phase == 'auto' || c.phase == phase).toList();

  final batchLimit = apply
      ? [batchSize, remaining].reduce((a, b) => a < b ? a : b)
      : batchSize;
  final selected = candidates.take(batchLimit).toList();
  final audit = selected.map((c) => _auditCandidate(c, tmdbCache)).toList();
  final blockingAudit = audit
      .where((a) => a['severity'] == 'blocking')
      .toList();

  final outDir = Directory(
    p.join(
      root.path,
      'akasha-db',
      'pipeline',
      'artifacts',
      'coverage_dashboard',
    ),
  )..createSync(recursive: true);

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'mode': apply ? 'apply' : 'dry-run',
    'phase': phase,
    'batchSize': batchSize,
    'targetExternalIdCount': _targetExternalIdCount,
    'currentExternalIdCount': currentExternal,
    'remainingToTarget': remaining,
    'candidateCounts': {
      'tmdb': candidates.where((c) => c.phase == 'tmdb').length,
      'steam': candidates.where((c) => c.phase == 'steam').length,
      'total': candidates.length,
    },
    'selectedCount': selected.length,
    'selectedByPhase': {
      'tmdb': selected.where((c) => c.phase == 'tmdb').length,
      'steam': selected.where((c) => c.phase == 'steam').length,
    },
    'audit': {
      'checked': audit.length,
      'blockingCount': blockingAudit.length,
      'items': audit,
    },
    'selected': selected.map((c) => c.toJson()).toList(),
  };

  File(
    p.join(outDir.path, 'sprint_04_externalid_report.json'),
  ).writeAsStringSync(_pretty(report));
  File(
    p.join(outDir.path, 'externalid_audit_sample.json'),
  ).writeAsStringSync(_pretty({'items': audit}));

  if (blockingAudit.isNotEmpty) {
    stderr.writeln('ERROR: blocking audit issue(s): ${blockingAudit.length}');
    for (final item in blockingAudit.take(10)) {
      stderr.writeln('  - ${item['workId']}: ${item['reason']}');
    }
    exit(2);
  }

  if (apply && selected.isNotEmpty) {
    for (final c in selected) {
      final result = applyFixToWork(c.workRef.work, {
        'externalIds': {c.provider: c.externalId},
      });
      final next = Map<String, dynamic>.from(result.work);
      final extensions = next['extensions'] is Map
          ? Map<String, dynamic>.from(next['extensions'] as Map)
          : <String, dynamic>{};
      extensions['coverageSprint04ExternalId'] = c.phase;
      next['extensions'] = extensions;
      c.workRef.shard.works[c.workRef.entryKey] = next;
    }

    for (final shard in shardFiles.where(
      (s) => selected.any((c) => c.workRef.shard == s),
    )) {
      shard.write();
    }
  }

  print(
    jsonEncode({
      'mode': apply ? 'apply' : 'dry-run',
      'phase': phase,
      'currentExternalIdCount': currentExternal,
      'remainingToTarget': remaining,
      'selectedCount': selected.length,
      'selectedByPhase': report['selectedByPhase'],
      'blockingAuditCount': blockingAudit.length,
      'report': p.relative(
        p.join(outDir.path, 'sprint_04_externalid_report.json'),
        from: root.path,
      ),
    }),
  );
}

List<_Candidate> _buildCandidates(
  List<_WorkRef> works,
  Map<String, String> tmdbReverse,
) {
  final out = <_Candidate>[];
  for (final ref in works) {
    if (_externalIds(ref.work).isNotEmpty) continue;

    final poster = ref.work['posterPath']?.toString() ?? '';
    final tmdbId = _resolveTmdbFromPoster(poster, tmdbReverse);
    if (tmdbId != null) {
      out.add(
        _Candidate(
          phase: 'tmdb',
          provider: 'tmdb',
          externalId: tmdbId,
          method: 'poster_cache',
          workRef: ref,
        ),
      );
      continue;
    }

    final steamId = _resolveSteamAppId(ref.work);
    if (steamId != null) {
      out.add(
        _Candidate(
          phase: 'steam',
          provider: 'steam',
          externalId: steamId,
          method: 'poster_or_legacy_appid',
          workRef: ref,
        ),
      );
    }
  }

  out.sort((a, b) {
    final phaseOrder = a.phase.compareTo(b.phase);
    if (phaseOrder != 0) return phaseOrder;
    return a.workRef.workId.compareTo(b.workRef.workId);
  });
  return out;
}

Map<String, dynamic> _auditCandidate(_Candidate c, Map<int, String> tmdbCache) {
  final work = Map<String, dynamic>.from(c.workRef.work);
  final reasons = <String>[];

  if (c.phase == 'tmdb') {
    final next = Map<String, dynamic>.from(work);
    next['externalIds'] = {'tmdb': c.externalId};
    final verified = isPosterVerified(next, tmdbCache);
    if (!verified) reasons.add('tmdb_poster_not_verified');
  }

  if (c.phase == 'steam') {
    final posterId = _steamAppIdFromPoster(
      work['posterPath']?.toString() ?? '',
    );
    final legacyId = _steamAppIdFromLegacy(work['legacyIds']);
    if (posterId == null && legacyId == null)
      reasons.add('steam_appid_missing');
    if (posterId != null && legacyId != null && posterId != legacyId) {
      reasons.add('steam_poster_legacy_mismatch');
    }
    if ((work['category']?.toString() ?? '') != 'game') {
      reasons.add('steam_non_game_category');
    }
  }

  final title = work['title']?.toString().trim() ?? '';
  if (title.isEmpty) reasons.add('empty_title');

  return {
    'workId': c.workRef.workId,
    'title': title,
    'category': work['category']?.toString() ?? '',
    'phase': c.phase,
    'provider': c.provider,
    'externalId': c.externalId,
    'method': c.method,
    'severity': reasons.isEmpty ? 'ok' : 'blocking',
    'reason': reasons.isEmpty ? 'ok' : reasons.join(','),
  };
}

String? _resolveTmdbFromPoster(String poster, Map<String, String> reverse) {
  if (!poster.contains(tmdbImageHost)) return null;
  return reverse[normalizePosterUrl(poster)];
}

String? _resolveSteamAppId(Map<String, dynamic> work) {
  return _steamAppIdFromPoster(work['posterPath']?.toString() ?? '') ??
      _steamAppIdFromLegacy(work['legacyIds']);
}

String? _steamAppIdFromPoster(String poster) {
  final match = RegExp(r'/steam/apps/(\d+)/').firstMatch(poster);
  return match?.group(1);
}

String? _steamAppIdFromLegacy(dynamic legacyIds) {
  if (legacyIds is! List) return null;
  for (final raw in legacyIds) {
    final match = RegExp(r'appid(\d+)').firstMatch(raw?.toString() ?? '');
    if (match != null) return match.group(1);
  }
  return null;
}

Map<String, String> _externalIds(Map<String, dynamic> work) {
  final raw = work['externalIds'];
  if (raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((k, v) {
    final id = v?.toString().trim() ?? '';
    if (id.isNotEmpty) out[k.toString()] = id;
  });
  return out;
}

Map<String, String> _buildTmdbReverseCache(Map<int, String> cache) {
  return {
    for (final entry in cache.entries)
      normalizePosterUrl(buildTmdbPosterUrl(entry.value)): entry.key.toString(),
  };
}

Map<int, String> _loadTmdbPosterCache(Directory root) {
  final file = File(p.join(root.path, 'akasha-db', 'tmdb_poster_cache.json'));
  final decoded = jsonDecode(file.readAsStringSync()) as Map;
  final out = <int, String>{};
  decoded.forEach((k, v) {
    final id = int.tryParse(k.toString());
    final path = v?.toString() ?? '';
    if (id != null && path.isNotEmpty) out[id] = path;
  });
  return out;
}

Map<String, dynamic> _loadManifest(Directory root) {
  return jsonDecode(
        File(
          p.join(root.path, 'akasha-db', 'manifest.json'),
        ).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

List<_ShardFile> _loadShardFiles(
  Directory root,
  Map<String, dynamic> manifest,
) {
  final out = <_ShardFile>[];
  for (final raw in manifest['shards'] as List) {
    final meta = raw as Map;
    final path = p.join(root.path, 'akasha-db', meta['path'] as String);
    final file = File(path);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    out.add(_ShardFile(file, decoded));
  }
  return out;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('ERROR: project root not found');
      exit(1);
    }
    dir = parent;
  }
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

String _pretty(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value);

class _ShardFile {
  _ShardFile(this.file, this.works);

  final File file;
  final Map<String, dynamic> works;

  void write() {
    file.writeAsStringSync('${_pretty(works)}\n');
  }
}

class _WorkRef {
  _WorkRef(this.shard, this.entryKey, this.work);

  final _ShardFile shard;
  final String entryKey;
  final Map<String, dynamic> work;

  String get workId => work['workId']?.toString() ?? entryKey;
}

class _Candidate {
  _Candidate({
    required this.phase,
    required this.provider,
    required this.externalId,
    required this.method,
    required this.workRef,
  });

  final String phase;
  final String provider;
  final String externalId;
  final String method;
  final _WorkRef workRef;

  Map<String, dynamic> toJson() => {
    'workId': workRef.workId,
    'title': workRef.work['title']?.toString() ?? '',
    'category': workRef.work['category']?.toString() ?? '',
    'phase': phase,
    'provider': provider,
    'externalId': externalId,
    'method': method,
  };
}
