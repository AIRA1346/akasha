// ignore_for_file: avoid_print
// Sprint 04 Phase A ??externalId baseline measurement (read-only).
//
// Usage: dart run tool/archive/coverage_sprint_04_baseline.dart [--write-json]
//
// ?�출: akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_baseline.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../coverage_quality.dart';
import '../poster_verification.dart';
import '../quality_loop_utils.dart';

const g2TargetRate = 0.50;

void main(List<String> args) {
  final writeJson = args.contains('--write-json');
  final root = _root();
  final works = loadRegistryWorkMaps(root);
  final total = works.length;
  final tmdbCache = _loadTmdbPosterCache(root);
  final tmdbReverse = _buildTmdbReverseCache(tmdbCache);

  final withExternal = <Map<String, dynamic>>[];
  final withoutExternal = <Map<String, dynamic>>[];

  final byCategory = <String, _Bucket>{};
  final providerWorks = <String, int>{};
  final providerIds = <String, int>{};

  for (final work in works) {
    final cat = work['category']?.toString() ?? 'unknown';
    byCategory.putIfAbsent(cat, () => _Bucket()).total++;

    final ext = _externalIds(work);
    if (ext.isEmpty) {
      withoutExternal.add(work);
      continue;
    }
    withExternal.add(work);
    byCategory[cat]!.withExternal++;

    for (final entry in ext.entries) {
      final key = _normalizeProvider(entry.key);
      providerWorks[key] = (providerWorks[key] ?? 0) + 1;
      providerIds[key] = (providerIds[key] ?? 0) + 1;
    }
  }

  final currentCount = withExternal.length;
  final currentRate = total == 0 ? 0.0 : currentCount / total;
  final g2TargetCount = (total * g2TargetRate).ceil();
  final gapToG2 = (g2TargetCount - currentCount).clamp(0, total);

  final e1 = <Map<String, dynamic>>[];
  final e2 = <Map<String, dynamic>>[];

  for (final work in withoutExternal) {
    final poster = work['posterPath']?.toString() ?? '';
    final tmdbId = _resolveTmdbFromPoster(poster, tmdbReverse);
    if (tmdbId != null) {
      e2.add(_candidateRow(work, 'E2', 'tmdb', tmdbId, tmdbCache));
      continue;
    }
    final steamId = _resolveSteamAppId(work);
    if (steamId != null) {
      e1.add(_candidateRow(work, 'E1', 'steam', steamId, tmdbCache));
    }
  }

  final e1Ok = e1.where((c) => c['audit'] == 'ok').length;
  final e2Ok = e2.where((c) => c['audit'] == 'ok').length;
  final projectedE1 = currentCount + e1Ok;
  final projectedE1E2 = currentCount + e1Ok + e2Ok;
  final rateE1 = total == 0 ? 0.0 : projectedE1 / total;
  final rateE1E2 = total == 0 ? 0.0 : projectedE1E2 / total;

  final categoryTable = <String, dynamic>{};
  for (final entry in byCategory.entries) {
    final b = entry.value;
    categoryTable[entry.key] = {
      'total': b.total,
      'withExternalId': b.withExternal,
      'withoutExternalId': b.total - b.withExternal,
      'coverageRate': b.total == 0 ? 0.0 : b.withExternal / b.total,
      'coveragePercent': b.total == 0
          ? '0.0'
          : (100 * b.withExternal / b.total).toStringAsFixed(1),
    };
  }

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'phase': 'Sprint 04 Phase A',
    'mode': 'measurement_only',
    'registry': {
      'totalWorks': total,
      'externalIdCount': currentCount,
      'externalIdCoverageRate': currentRate,
      'externalIdCoveragePercent': (100 * currentRate).toStringAsFixed(2),
      'withoutExternalId': withoutExternal.length,
    },
    'g2': {
      'targetRate': g2TargetRate,
      'targetCount': g2TargetCount,
      'gapWorks': gapToG2,
      'achievableE1Only': rateE1 >= g2TargetRate,
      'achievableE1E2': rateE1E2 >= g2TargetRate,
    },
    'byCategory': categoryTable,
    'providerDistribution': {
      'worksWithProvider': providerWorks,
      'note': '?�품 ?�위 ??복수 provider 보유 ??�?provider??1??집계',
    },
    'cohort': {
      'E1_steam': {
        'label': 'E1 Steam candidate',
        'candidates': e1.length,
        'auditOk': e1Ok,
        'auditBlocking': e1.length - e1Ok,
      },
      'E2_tmdb_poster': {
        'label': 'E2 TMDB poster candidate',
        'candidates': e2.length,
        'auditOk': e2Ok,
        'auditBlocking': e2.length - e2Ok,
      },
    },
    'projection': {
      'current': {
        'count': currentCount,
        'rate': currentRate,
        'percent': (100 * currentRate).toStringAsFixed(2),
      },
      'afterE1Only': {
        'add': e1Ok,
        'count': projectedE1,
        'rate': rateE1,
        'percent': (100 * rateE1).toStringAsFixed(2),
        'meetsG2': rateE1 >= g2TargetRate,
      },
      'afterE1E2': {
        'add': e1Ok + e2Ok,
        'count': projectedE1E2,
        'rate': rateE1E2,
        'percent': (100 * rateE1E2).toStringAsFixed(2),
        'meetsG2': rateE1E2 >= g2TargetRate,
      },
    },
    'samples': {
      'E1': e1.take(10).toList(),
      'E2': e2.take(10).toList(),
    },
  };

  final registry = report['registry'] as Map<String, dynamic>;
  print(jsonEncode({
    'totalWorks': total,
    'externalIdCoveragePercent': registry['externalIdCoveragePercent'],
    'g2TargetCount': g2TargetCount,
    'E1_ok': e1Ok,
    'E2_ok': e2Ok,
    'meetsG2_afterE1': rateE1 >= g2TargetRate,
  }));

  if (writeJson) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    )..createSync(recursive: true);
    final out = File(p.join(outDir.path, 'sprint_04_baseline.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  }
}

Map<String, dynamic> _candidateRow(
  Map<String, dynamic> work,
  String cohort,
  String provider,
  String externalId,
  Map<int, String> tmdbCache,
) {
  final reasons = <String>[];
  if (cohort == 'E1') {
    if ((work['category']?.toString() ?? '') != 'game') {
      reasons.add('steam_non_game_category');
    }
    final posterId = _steamAppIdFromPoster(work['posterPath']?.toString() ?? '');
    final legacyId = _steamAppIdFromLegacy(work['legacyIds']);
    if (posterId == null && legacyId == null) reasons.add('steam_appid_missing');
    if (posterId != null && legacyId != null && posterId != legacyId) {
      reasons.add('steam_poster_legacy_mismatch');
    }
  }
  if (cohort == 'E2') {
    final next = Map<String, dynamic>.from(work);
    next['externalIds'] = {'tmdb': externalId};
    if (!isPosterVerified(next, tmdbCache)) {
      reasons.add('tmdb_poster_not_verified');
    }
  }
  final title = work['title']?.toString().trim() ?? '';
  if (title.isEmpty) reasons.add('empty_title');

  return {
    'workId': work['workId']?.toString() ?? '',
    'title': title,
    'category': work['category']?.toString() ?? '',
    'cohort': cohort,
    'provider': provider,
    'externalId': externalId,
    'audit': reasons.isEmpty ? 'ok' : 'blocking',
    'reasons': reasons,
  };
}

String _normalizeProvider(String key) {
  final k = key.toLowerCase();
  if (k == 'steam' || k == 'tmdb' || k == 'igdb') return k;
  return 'other';
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

class _Bucket {
  int total = 0;
  int withExternal = 0;
}

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final p = dir.parent;
    if (p.path == dir.path) return Directory.current;
    dir = p;
  }
}
