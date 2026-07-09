// ignore_for_file: avoid_print
// Coverage Sprint 03 ??titles.en 50% milestone (+101 works) + Economics ?れ浮.
//
// Usage:
//   dart run tool/archive/coverage_sprint_03_titles_en.dart                    # dry-run cohort
//   dart run tool/archive/coverage_sprint_03_titles_en.dart --apply            # enrich + report
//   dart run tool/archive/coverage_sprint_03_titles_en.dart --remediate --apply # fix invalid en
//
// ?办稖氍? akasha-db/pipeline/artifacts/coverage_dashboard/sprint_03_report.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../coverage_quality.dart';
import '../dedupe_utils.dart';
import '../poster_verification.dart';

const _milestoneCount = 101;
const _targetRate = 0.50;

/// Sprint 02 氤挫爼 ?? (maintainer-minutes / work)
const _minutesAuto = 2.0;
const _minutesSemi = 5.0;
const _minutesManual = 15.0;

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final remediate = args.contains('--remediate');
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
  );
  outDir.createSync(recursive: true);

  final franchisePeers = _loadFranchisePeers(root);
  _primePeerEnCache(root);
  final cohort = remediate ? _selectRemediateCohort(root) : _selectCohort(root);
  print('Sprint 03 ??titles.en 50% (+$_milestoneCount works)${remediate ? ' [remediate]' : ''}');
  print('  cohort: ${cohort.length} works');
  print('  tiers: ${_countBy(cohort, (c) => c.tier)}');
  print('  categories: ${_countBy(cohort, (c) => c.category)}');
  print('');

  if (!apply) {
    print('Dry-run. Use --apply to enrich and write sprint_03_report.json');
    return;
  }

  final sprintStart = DateTime.now();
  final client = createTmdbHttpClient();
  final results = <Map<String, dynamic>>[];
  var autoOk = 0;
  var semiOk = 0;
  var manualOk = 0;
  var failed = 0;

  for (final item in cohort) {
    final sw = Stopwatch()..start();
    final enrich = await _enrichWork(client, item, franchisePeers);
    sw.stop();

    final ok = enrich.success;
    if (ok) {
      switch (enrich.bucket) {
        case 'auto':
          autoOk++;
        case 'semi':
          semiOk++;
        case 'manual':
          manualOk++;
      }
      _writeWork(root, item.shardPath, item.workId, enrich.titlesEn!, enrich.method);
    } else {
      failed++;
    }

    results.add({
      'workId': item.workId,
      'category': item.category,
      'tier': item.tier,
      'title': item.title,
      'method': enrich.method,
      'bucket': enrich.bucket,
      'success': ok,
      'elapsedMs': sw.elapsedMilliseconds,
      'titlesEn': enrich.titlesEn,
      'note': enrich.note,
    });

    if (enrich.method == 'tmdb_fetch') {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } else if (enrich.method == 'steam_fetch') {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }
  client.close();

  final sprintWallMs = DateTime.now().difference(sprintStart).inMilliseconds;

  print('Running registry_builder...');
  final buildStart = DateTime.now();
  final buildCode = await _runDart(root, [
    'run',
    'tool/registry_builder.dart',
    '--sync-assets',
    '--bundle-eager-only',
  ]);
  final buildMs = DateTime.now().difference(buildStart).inMilliseconds;
  if (buildCode != 0) {
    stderr.writeln('registry_builder failed: $buildCode');
    exit(buildCode);
  }

  final metricsStart = DateTime.now();
  await _runDart(root, ['run', 'tool/coverage_dashboard.dart']);
  await _runDart(root, ['run', 'tool/sw1_a_validation.dart']);
  await _runDart(root, ['run', 'tool/urv_a_validation.dart']);
  final metricsMs = DateTime.now().difference(metricsStart).inMilliseconds;

  final snapshotBefore = _readJsonIfExists(
    p.join(outDir.path, 'sprint_02_economics.json'),
  );
  final coverageAfter = _readJsonIfExists(p.join(outDir.path, 'coverage_snapshot.json'));
  final sw1After = _readJsonIfExists(
    p.join(root.path, 'akasha-db/pipeline/artifacts/global_search_validation/sw1_a_report.json'),
  );
  final urvAfter = _readJsonIfExists(
    p.join(
      root.path,
      'akasha-db/pipeline/artifacts/universal_registry_validation/urv_a_report.json',
    ),
  );

  final titlesEnKpi = coverageAfter?['kpis']?['titles_en'] as Map<String, dynamic>?;
  final byCategory = <String, Map<String, dynamic>>{};
  for (final cat in ['manga', 'animation', 'game', 'book', 'movie', 'drama', 'webtoon']) {
    final items = results.where((r) => r['category'] == cat).toList();
    if (items.isEmpty) continue;
    final okItems = items.where((r) => r['success'] == true).toList();
    final ms = okItems.map((r) => r['elapsedMs'] as int).toList();
    byCategory[cat] = {
      'count': items.length,
      'success': okItems.length,
      'avgMs': ms.isEmpty ? 0 : ms.reduce((a, b) => a + b) / ms.length,
      'totalMs': ms.fold<int>(0, (a, b) => a + b),
    };
  }

  final enrichMs = results.fold<int>(0, (a, r) => a + (r['elapsedMs'] as int));
  final successCount = autoOk + semiOk + manualOk;
  final sprint02EstimateMin = snapshotBefore?['registryWide']?['titles_en']?['milestones']?['50%']
      ?['estimatedMinutes'] as num?;
  final humanEquivalentMin =
      autoOk * _minutesAuto + semiOk * _minutesSemi + manualOk * _minutesManual;

  final report = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sprint': 'Coverage Sprint 03: titles.en 50%',
    'targetWorks': _milestoneCount,
    'timing': {
      'enrichWallMs': sprintWallMs,
      'enrichWallMinutes': (sprintWallMs / 60000).toStringAsFixed(2),
      'enrichActiveMs': enrichMs,
      'registryBuildMs': buildMs,
      'metricsMs': metricsMs,
      'totalWallMs': sprintWallMs + buildMs + metricsMs,
      'totalWallMinutes': ((sprintWallMs + buildMs + metricsMs) / 60000).toStringAsFixed(2),
    },
    'economicsValidation': {
      'sprint02EstimateMinutes_50pct': sprint02EstimateMin,
      'sprint02EstimateHours_50pct': snapshotBefore?['registryWide']?['titles_en']?['milestones']?['50%']
          ?['estimatedHours'],
      'sprint03WallMinutes_enrichOnly': (sprintWallMs / 60000).toStringAsFixed(2),
      'sprint03WallMinutes_totalPipeline':
          ((sprintWallMs + buildMs + metricsMs) / 60000).toStringAsFixed(2),
      'sprint03HumanEquivalentMinutes':
          humanEquivalentMin.toStringAsFixed(1),
      'deltaWallVsEstimateMinutes':
          sprint02EstimateMin == null
              ? null
              : ((sprintWallMs / 60000) - sprint02EstimateMin.toDouble()).toStringAsFixed(1),
      'deltaHumanEquivalentVsEstimateMinutes':
          sprint02EstimateMin == null
              ? null
              : (humanEquivalentMin - sprint02EstimateMin.toDouble()).toStringAsFixed(1),
      'interpretation':
          'Sprint 02 = tier-weighted manual model (~13.6min avg); Sprint 03 wall = script runtime; humanEquivalent = Sprint02 tier rates applied to actual method mix',
    },
    'automation': {
      'successTotal': successCount,
      'failed': failed,
      'auto': autoOk,
      'semi': semiOk,
      'manual': manualOk,
      'automationRate': successCount == 0 ? 0.0 : (autoOk + semiOk) / successCount,
      'automationPercent': successCount == 0
          ? '0'
          : (((autoOk + semiOk) / successCount) * 100).toStringAsFixed(1),
    },
    'byCategory': byCategory,
    'coverage': {
      'titles_en_before': '100/402 (24.9%)',
      'titles_en_after': titlesEnKpi == null
          ? null
          : '${titlesEnKpi['numerator']}/${titlesEnKpi['denominator']} (${titlesEnKpi['percent']}%)',
      'gap_panel': coverageAfter?['kpis']?['gap_panel_coverage'],
    },
    'regression': {
      'sw1_recallAt10': sw1After?['overall']?['recallAt10'],
      'urv_convergence': urvAfter?['summary']?['queryConvergenceRate'],
    },
    'perWork': results,
  };

  final outFile = File(p.join(outDir.path, 'sprint_03_report.json'));
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  print('');
  print('Sprint 03 complete');
  print('  enriched: $successCount/$_milestoneCount (auto $autoOk 路 semi $semiOk 路 manual $manualOk 路 fail $failed)');
  final automation = report['automation'] as Map<String, dynamic>;
  final timing = report['timing'] as Map<String, dynamic>;
  final economics = report['economicsValidation'] as Map<String, dynamic>;
  final coverage = report['coverage'] as Map<String, dynamic>;
  final regression = report['regression'] as Map<String, dynamic>;
  print('  automation rate: ${automation['automationPercent']}%');
  print('  wall time enrich: ${timing['enrichWallMinutes']} min');
  print('  wall time total: ${timing['totalWallMinutes']} min');
  print('  Sprint02 estimate: ${sprint02EstimateMin ?? '?'} min');
  print('  wall vs estimate: ${economics['deltaWallVsEstimateMinutes']} min 路 human-eq vs estimate: ${economics['deltaHumanEquivalentVsEstimateMinutes']} min');
  print('  titles.en: ${coverage['titles_en_after']}');
  print('  SW1: ${regression['sw1_recallAt10']} 路 URV: ${regression['urv_convergence']}');
  print('Wrote: ${outFile.path}');
}

class _CohortItem {
  final String workId;
  final String category;
  final String tier;
  final String title;
  final String shardPath;
  final Map<String, dynamic> work;

  _CohortItem({
    required this.workId,
    required this.category,
    required this.tier,
    required this.title,
    required this.shardPath,
    required this.work,
  });
}

class _EnrichResult {
  final bool success;
  final String method;
  final String bucket;
  final String? titlesEn;
  final String? note;

  _EnrichResult({
    required this.success,
    required this.method,
    required this.bucket,
    this.titlesEn,
    this.note,
  });
}

List<_CohortItem> _selectCohort(Directory root) {
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;

  final missing = <_CohortItem>[];
  for (final shardMeta in manifest['shards'] as List) {
    final rel = (shardMeta as Map)['path'] as String;
    final path = p.join(root.path, 'akasha-db', rel);
    final shard = jsonDecode(File(path).readAsStringSync()) as Map;
    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      if (_hasEn(work)) continue;
      missing.add(
        _CohortItem(
          workId: workId,
          category: work['category']?.toString() ?? 'unknown',
          tier: _tierOf(work),
          title: work['title']?.toString() ?? workId,
          shardPath: rel,
          work: work,
        ),
      );
    }
  }

  final order = {'auto_high': 0, 'auto_medium': 1, 'manual_low': 2, 'manual_high': 3};
  missing.sort((a, b) => order[a.tier]!.compareTo(order[b.tier]!));
  return missing.take(_milestoneCount).toList();
}

Future<_EnrichResult> _enrichWork(
  HttpClient client,
  _CohortItem item,
  Map<String, Set<String>> franchisePeers,
) async {
  final work = item.work;

  final tmdbId = resolveTmdbId(work);
  if (tmdbId != null) {
    final page = await fetchTmdbPageTitle(client, tmdbId);
    if (page != null) {
      final en = _extractEnglishFromTmdb(page);
      if (en != null &&
          isValidEnTitle(en) &&
          (titlesMatchWork(work, page) || _plausibleEn(work, en))) {
        return _EnrichResult(
          success: true,
          method: 'tmdb_fetch',
          bucket: 'auto',
          titlesEn: en,
          note: page,
        );
      }
    }
  }

  final steamAppId = _resolveSteamAppId(work);
  if (steamAppId != null) {
    final name = await _fetchSteamStoreTitle(client, steamAppId);
    if (name != null && isValidEnTitle(name)) {
      return _EnrichResult(
        success: true,
        method: 'steam_fetch',
        bucket: 'auto',
        titlesEn: name,
      );
    }
  }

  if (_isMostlyLatin(item.title) || _isAsciiCanonicalTitle(item.title)) {
    return _EnrichResult(
      success: true,
      method: 'latin_title',
      bucket: 'semi',
      titlesEn: item.title.trim(),
    );
  }

  final slugEn = _englishFromLegacySlug(work);
  if (slugEn != null) {
    return _EnrichResult(
      success: true,
      method: 'legacy_slug',
      bucket: 'semi',
      titlesEn: slugEn,
    );
  }

  final peerEn = _franchisePeerEnLoaded(item.workId, franchisePeers);
  if (peerEn != null) {
    return _EnrichResult(
      success: true,
      method: 'franchise_copy',
      bucket: 'semi',
      titlesEn: peerEn,
    );
  }

  final descEn = _englishFromDescription(work);
  if (descEn != null) {
    return _EnrichResult(
      success: true,
      method: 'description_parse',
      bucket: 'semi',
      titlesEn: descEn,
    );
  }

  final curated = _curatedTitlesEn[item.workId];
  if (curated != null) {
    return _EnrichResult(
      success: true,
      method: 'curated_manual',
      bucket: 'manual',
      titlesEn: curated,
    );
  }

  return _EnrichResult(
    success: false,
    method: 'unresolved',
    bucket: 'manual',
    note: 'no automated candidate',
  );
}

String? _extractEnglishFromTmdb(String page) {
  final parts = page.split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  for (final part in parts) {
    if (!isValidEnTitle(part)) continue;
    if (_isMostlyLatin(part)) return part;
  }
  for (final part in parts) {
    if (isValidEnTitle(part)) return part;
  }
  return null;
}

bool _isAsciiCanonicalTitle(String s) {
  final t = s.trim();
  if (t.isEmpty || t.length > 80) return false;
  return RegExp(r'^[\x20-\x7E]+$').hasMatch(t);
}

bool _plausibleEn(Map<String, dynamic> work, String en) {
  if (en.length < 2) return false;
  if (_isMostlyLatin(en)) return true;
  return titlesMatchWork(work, en);
}

String? _englishFromLegacySlug(Map<String, dynamic> work) {
  final legacy = work['legacyIds'];
  if (legacy is! List) return null;
  for (final id in legacy) {
    final stem = legacySlugStem(id.toString());
    if (stem == null || stem.length < 3) continue;
    if (stem.startsWith('appid')) continue;
    if (!RegExp(r'[a-z]').hasMatch(stem)) continue;
    return _humanizeSlug(stem);
  }
  return null;
}

String _humanizeSlug(String slug) {
  return slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => w.length <= 3 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String? _englishFromDescription(Map<String, dynamic> work) {
  final desc = work['description']?.toString() ?? '';
  final m = RegExp(r'^(.+?)\s*[?斺�?]\s*Steam').firstMatch(desc);
  if (m != null) {
    final t = m.group(1)!.trim();
    if (_isMostlyLatin(t)) return t;
  }
  return null;
}

int? _resolveSteamAppId(Map<String, dynamic> work) {
  final poster = work['posterPath']?.toString() ?? '';
  final m = RegExp(r'steam/apps/(\d+)').firstMatch(poster);
  if (m != null) return int.tryParse(m.group(1)!);
  final legacy = work['legacyIds'];
  if (legacy is List) {
    for (final id in legacy) {
      final mm = RegExp(r'appid(\d+)').firstMatch(id.toString());
      if (mm != null) return int.tryParse(mm.group(1)!);
    }
  }
  return null;
}

Future<String?> _fetchSteamStoreTitle(HttpClient client, int appId) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://store.steampowered.com/app/$appId'),
    );
    request.headers.set(
      'User-Agent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    );
    request.headers.set('Accept-Language', 'en-US,en;q=0.9');
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final html = await response.transform(utf8.decoder).join();
    final og = RegExp(
      r'property="og:title" content="([^"]+)"',
    ).firstMatch(html);
    if (og != null) {
      var t = og.group(1)!.trim();
      t = t.replaceAll(RegExp(r'\s+on Steam$'), '').trim();
      if (t.isNotEmpty) return t;
    }
    final appName = RegExp(
      r'class="apphub_AppName"[^>]*>([^<]+)<',
    ).firstMatch(html);
    if (appName != null) return appName.group(1)!.trim();
  } catch (_) {}
  return null;
}

final _peerEnCache = <String, String>{};

String? _franchisePeerEnLoaded(String workId, Map<String, Set<String>> peers) {
  final group = peers[workId];
  if (group == null) return null;
  for (final pid in group) {
    if (pid == workId) continue;
    final en = _peerEnCache[pid];
    if (en != null && en.isNotEmpty) return en;
  }
  return null;
}

void _primePeerEnCache(Directory root) {
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map;
  for (final s in manifest['shards'] as List) {
    final shard = jsonDecode(
      File(p.join(root.path, 'akasha-db', (s as Map)['path'])).readAsStringSync(),
    ) as Map;
    for (final e in shard.entries) {
      if (e.value is! Map) continue;
      final w = e.value as Map;
      final id = w['workId']?.toString() ?? e.key.toString();
      final titles = w['titles'];
      if (titles is Map) {
        final en = titles['en']?.toString().trim();
        if (en != null && en.isNotEmpty && isValidEnTitle(en)) _peerEnCache[id] = en;
      }
    }
  }
}

/// Sprint 03 cohort ?旍棳 ?橂彊 毵ろ晳 (unresolved fallback).
const _curatedTitlesEn = <String, String>{
  'wk_000000253': '86 -Eighty-Six-',
  'wk_000004322': 'X (2022 film)',
  'wk_000004603': 'Arithmetic in the Five Classics',
  'wk_000004913': 'Essentials of Agriculture and Sericulture',
  'wk_000005155': 'Collected Edicts and Decrees of the Tang Dynasty',
  'wk_000005249': 'Diary of the Founding of the Tang Dynasty',
};

void _writeWork(Directory root, String shardRel, String workId, String en, String method) {
  final file = File(p.join(root.path, 'akasha-db', shardRel));
  final shard = Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
  final work = Map<String, dynamic>.from(shard[workId] as Map);
  final titles = work['titles'] is Map
      ? Map<String, dynamic>.from(work['titles'] as Map)
      : <String, dynamic>{};
  titles['en'] = en;
  if (!titles.containsKey('ko') && work['title'] != null) {
    titles['ko'] = work['title'];
  }
  work['titles'] = titles;
  final ext = work['extensions'] is Map
      ? Map<String, dynamic>.from(work['extensions'] as Map)
      : <String, dynamic>{};
  ext['coverageSprint03'] = method;
  work['extensions'] = ext;
  shard[workId] = work;
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(shard)}\n');
}

bool _hasEn(Map<String, dynamic> work) {
  final titles = work['titles'];
  if (titles is! Map) return false;
  final en = titles['en']?.toString().trim();
  return en != null && en.isNotEmpty && isValidEnTitle(en);
}

List<_CohortItem> _selectRemediateCohort(Directory root) {
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;

  final items = <_CohortItem>[];
  for (final shardMeta in manifest['shards'] as List) {
    final rel = (shardMeta as Map)['path'] as String;
    final path = p.join(root.path, 'akasha-db', rel);
    final shard = jsonDecode(File(path).readAsStringSync()) as Map;
    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      final ext = work['extensions'];
      final sprint03 = ext is Map && ext['coverageSprint03'] != null;
      final enBad = !_hasEn(work);
      if (!sprint03 && enBad) continue;
      if (sprint03 && enBad) {
        items.add(
          _CohortItem(
            workId: workId,
            category: work['category']?.toString() ?? 'unknown',
            tier: _tierOf(work),
            title: work['title']?.toString() ?? workId,
            shardPath: rel,
            work: work,
          ),
        );
        continue;
      }
      if (sprint03) {
        final en = (work['titles'] as Map)['en']?.toString() ?? '';
        if (!isValidEnTitle(en)) {
          items.add(
            _CohortItem(
              workId: workId,
              category: work['category']?.toString() ?? 'unknown',
              tier: _tierOf(work),
              title: work['title']?.toString() ?? workId,
              shardPath: rel,
              work: work,
            ),
          );
        }
      }
    }
  }

  final missing = _selectCohort(root);
  final seen = items.map((e) => e.workId).toSet();
  for (final m in missing) {
    if (!seen.contains(m.workId)) items.add(m);
  }
  return items;
}

String _tierOf(Map<String, dynamic> work) {
  final ext = work['externalIds'] is Map ? work['externalIds'] as Map : {};
  if (ext.containsKey('tmdb') || ext.containsKey('steam') || ext.containsKey('igdb')) {
    return 'auto_high';
  }
  if (ext.isNotEmpty) return 'auto_medium';
  final titles = work['titles'];
  if (titles is Map && (titles['ja'] != null || titles['romaji'] != null)) {
    return 'manual_low';
  }
  return 'manual_high';
}

bool _isMostlyLatin(String s) {
  if (s.isEmpty) return false;
  final latin = RegExp(r'[A-Za-z]').allMatches(s).length;
  return latin >= s.replaceAll(' ', '').length * 0.5;
}

Map<String, Set<String>> _loadFranchisePeers(Directory root) {
  final raw = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'franchise_groups.json')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final peers = <String, Set<String>>{};
  raw.forEach((key, value) {
    if (key.startsWith('_') || value is! Map) return;
    final members = (value['members'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    for (final m in members) {
      peers.putIfAbsent(m, () => {}).addAll(members.where((x) => x != m));
    }
  });
  return peers;
}

Map<String, int> _countBy(List<_CohortItem> items, String Function(_CohortItem) fn) {
  final m = <String, int>{};
  for (final i in items) {
    final k = fn(i);
    m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

Future<int> _runDart(Directory root, List<String> args) async {
  final result = await Process.run(
    _dartBin(),
    args,
    workingDirectory: root.path,
    runInShell: true,
  );
  if (result.stdout.toString().isNotEmpty) stdout.write(result.stdout);
  if (result.stderr.toString().isNotEmpty) stderr.write(result.stderr);
  return result.exitCode;
}

String _dartBin() {
  const flutter = r'C:\src\flutter\bin\dart.bat';
  if (File(flutter).existsSync()) return flutter;
  return 'dart';
}

Map<String, dynamic>? _readJsonIfExists(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('project root not found');
}
