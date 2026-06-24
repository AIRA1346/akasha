// ignore_for_file: avoid_print
/// Sprint 04 Phase B-2 ??HIGH risk disposition analysis (read-only).
///
/// Usage: dart run tool/archive/coverage_sprint_04_high_risk_analyze.dart [--write-json]

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../coverage_quality.dart';
import '../poster_verification.dart';
import '../quality_loop_utils.dart';

const _highRiskIds = [
  'wk_000000144',
  'wk_000000266',
  'wk_000000270',
  'wk_000000277',
];

const _relatedIds = ['wk_000000111', 'wk_000000075'];

void main(List<String> args) {
  final writeJson = args.contains('--write-json');
  final root = _root();
  final works = loadRegistryWorkMaps(root);
  final byId = {for (final w in works) w['workId']?.toString() ?? '': w};
  final tmdbCache = _loadTmdbPosterCache(root);
  final steamIndex = <String, List<String>>{};
  for (final w in works) {
    final id = w['workId']?.toString() ?? '';
    final steam = _ext(w)['steam'];
    if (steam != null) steamIndex.putIfAbsent(steam, () => []).add(id);
  }

  final analyses = <Map<String, dynamic>>[];
  for (final wid in _highRiskIds) {
    final work = byId[wid];
    if (work == null) {
      analyses.add({'workId': wid, 'error': 'NOT_FOUND'});
      continue;
    }
    analyses.add(_analyzeWork(work, byId, steamIndex, tmdbCache));
  }

  final related = <Map<String, dynamic>>[];
  for (final wid in _relatedIds) {
    final work = byId[wid];
    if (work != null) related.add(_snapshotWork(work));
  }

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'phase': 'Sprint 04 Phase B-2',
    'mode': 'analysis_only',
    'analyses': analyses,
    'relatedWorks': related,
  };

  print(jsonEncode({
    'analyzed': analyses.length,
    'ids': _highRiskIds,
  }));

  if (writeJson) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    )..createSync(recursive: true);
    final out = File(p.join(outDir.path, 'sprint_04_high_risk_disposition.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  }
}

Map<String, dynamic> _analyzeWork(
  Map<String, dynamic> work,
  Map<String, Map<String, dynamic>> byId,
  Map<String, List<String>> steamIndex,
  Map<int, String> tmdbCache,
) {
  final workId = work['workId']?.toString() ?? '';
  final titles = (work['titles'] as Map?)?.cast<String, dynamic>() ?? {};
  final titleKo = work['title']?.toString() ?? '';
  final titleEn = titles['en']?.toString() ?? '';
  final aliases = work['aliases'];
  final ext = _ext(work);
  final poster = work['posterPath']?.toString() ?? '';
  final legacy = work['legacyIds'];
  final posterApp = _steamFromPoster(poster);
  final legacyApp = _steamFromLegacy(legacy);
  final chosenApp = posterApp ?? legacyApp;

  final paths = {
    'slug': false,
    'search': false,
    'poster': posterApp != null,
    'fallback': posterApp == null && legacyApp != null,
    'posterAppId': posterApp,
    'legacyAppId': legacyApp,
    'chosenAppId': chosenApp,
    'chosenPath': posterApp != null ? 'poster' : (legacyApp != null ? 'fallback' : 'none'),
  };

  final dupOwners = (steamIndex[chosenApp ?? ''] ?? [])
      .where((id) => id != workId)
      .toList();

  final classification = _classify(
    workId: workId,
    titleKo: titleKo,
    titleEn: titleEn,
    poster: poster,
    posterApp: posterApp,
    legacyApp: legacyApp,
    dupOwners: dupOwners,
    ext: ext,
    work: work,
  );

  return {
    'workId': workId,
    'registry': _snapshotWork(work),
    'steamSelectionPaths': paths,
    'duplicateOwners': dupOwners,
    'duplicateOwnerSnapshots': dupOwners.map((id) => _snapshotWork(byId[id]!)).toList(),
    'classification': classification['categories'],
    'rootCause': classification['rootCause'],
    'fixDisposition': classification['fixDisposition'],
    'fixNotes': classification['fixNotes'],
  };
}

Map<String, dynamic> _classify({
  required String workId,
  required String titleKo,
  required String titleEn,
  required String poster,
  required String? posterApp,
  required String? legacyApp,
  required List<String> dupOwners,
  required Map<String, String> ext,
  required Map<String, dynamic> work,
}) {
  final categories = <String>[];
  final notes = <String>[];

  if (dupOwners.isNotEmpty) {
    categories.add('DUPLICATE_ERROR');
    notes.add('steam:$posterApp ?? $legacyApp already on $dupOwners');
  }

  final promoEn = RegExp(r'^save\s+\d+%\s+on\s+', caseSensitive: false).hasMatch(titleEn.trim());
  final siteError = titleEn.toLowerCase().contains('site error');
  final crossGame = (titleKo.contains('?ˆì?') && titleEn.toLowerCase().contains('wukong')) ||
      (titleKo.contains('ë¸”ë£¨ ?„ì¹´?´ë¸Œ') && titleEn.toLowerCase().contains('songs of conquest')) ||
      siteError;

  if (promoEn || siteError || crossGame) {
    categories.add('SOURCE_ERROR');
    notes.add('titles.en polluted by store scrape or fetch failure');
  }

  if (crossGame && !promoEn) {
    categories.add('MATCHING_ERROR');
    notes.add('poster-derived appId may be correct but surface identity diverges');
  }

  if (titleEn.isEmpty || titleEn == titleKo) {
    categories.add('DATA_ERROR');
  }

  if (poster.isEmpty && legacyApp == null) {
    categories.add('DATA_ERROR');
    notes.add('no steam signal on work');
  }

  // wk_144: duplicate only, titles ok
  if (workId == 'wk_000000144' && dupOwners.isNotEmpty && !crossGame && !promoEn) {
    categories.remove('SOURCE_ERROR');
    categories.remove('MATCHING_ERROR');
    if (!categories.contains('DUPLICATE_ERROR')) categories.add('DUPLICATE_ERROR');
  }

  final fix = _fixDisposition(workId, categories, dupOwners, promoEn, crossGame, siteError);

  return {
    'categories': categories.toSet().toList(),
    'rootCause': notes.join('; '),
    'fixDisposition': fix.$1,
    'fixNotes': fix.$2,
  };
}

(String, String) _fixDisposition(
  String workId,
  List<String> categories,
  List<String> dupOwners,
  bool promoEn,
  bool crossGame,
  bool siteError,
) {
  if (workId == 'wk_000000277') {
    return (
      'DO_NOT_APPLY',
      'Duplicate steam:2358720 on wk_000000075; titles.en cross-game (Wukong vs NIKKE). Merge or retire duplicate work before attach.',
    );
  }
  if (workId == 'wk_000000144') {
    return (
      'MANUAL_FIX',
      'Skyrim SE appId correct for this work but duplicate wk_000000111. Curator: pick canonical work or share franchise policy.',
    );
  }
  if (workId == 'wk_000000270') {
    return (
      'MANUAL_FIX',
      'titles.en Site Error ??fix titles/poster source before externalId attach.',
    );
  }
  if (workId == 'wk_000000266') {
    return (
      'RULE_FIX',
      'Block externalId attach when titles.en matches Steam promo pattern or game name mismatch vs ko title.',
    );
  }
  if (categories.contains('DUPLICATE_ERROR')) return ('DO_NOT_APPLY', 'Resolve duplicate steam key first');
  if (promoEn) return ('RULE_FIX', 'titles.en cleanup gate before attach');
  if (crossGame) return ('MANUAL_FIX', 'Identity reconciliation required');
  return ('AUTO_FIX', 'No blocker after review');
}

Map<String, dynamic> _snapshotWork(Map<String, dynamic> work) {
  final titles = (work['titles'] as Map?)?.cast<String, dynamic>() ?? {};
  return {
    'workId': work['workId'],
    'title': work['title'],
    'titles': titles,
    'aliases': work['aliases'],
    'externalIds': work['externalIds'] ?? {},
    'posterPath': work['posterPath'],
    'legacyIds': work['legacyIds'],
    'category': work['category'],
    'releaseYear': work['releaseYear'],
    'extensions': work['extensions'],
  };
}

Map<String, String> _ext(Map<String, dynamic> work) {
  final raw = work['externalIds'];
  if (raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((k, v) {
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty) out[k.toString()] = s;
  });
  return out;
}

String? _steamFromPoster(String poster) {
  return RegExp(r'/steam/apps/(\d+)/').firstMatch(poster)?.group(1);
}

String? _steamFromLegacy(dynamic legacyIds) {
  if (legacyIds is! List) return null;
  for (final raw in legacyIds) {
    final m = RegExp(r'appid(\d+)').firstMatch(raw?.toString() ?? '');
    if (m != null) return m.group(1);
  }
  return null;
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

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final p = dir.parent;
    if (p.path == dir.path) return Directory.current;
    dir = p;
  }
}
