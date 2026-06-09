// ignore_for_file: avoid_print
/// SW1-A — 402 baseline recall@10 (Phase A 수동 계약 자동 실행).
///
/// Usage: dart run tool/sw1_a_validation.dart
///
/// 산출물: akasha-db/pipeline/artifacts/global_search_validation/sw1_a_report.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'registry_v3_utils.dart';

void main() {
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'global_search_validation'),
  );
  outDir.createSync(recursive: true);

  final index = _loadIndex(root);
  final queries = _loadQueries(root);
  final eval = queries.where((q) => !q.excludeFromRecall && q.expectedWorkIds.isNotEmpty).toList();

  final overallHits = <String, dynamic>{};
  var totalHits = 0;
  final perQuery = <Map<String, dynamic>>[];

  for (final q in eval) {
    final topK = _searchTopK(index, q.query, k: 10);
    final ok = _hit(q, topK);
    if (ok) totalHits++;
    final bucket = _sw1Bucket(q);
    perQuery.add({
      'id': q.id,
      'query': q.query,
      'bucket': bucket,
      'tags': q.tags,
      'hypothesis402': q.hypothesis402,
      'hitAt10': ok,
      'rank': _rank(q, topK),
      'top3': topK.take(3).toList(),
      'failureTag': ok ? null : _failureTag(q, topK, index),
    });
  }

  overallHits['recallAt10'] = eval.isEmpty ? 0.0 : totalHits / eval.length;
  overallHits['hits'] = totalHits;
  overallHits['evalCount'] = eval.length;

  final bucketOrder = [
    'original',
    'english',
    'translation',
    'series_subtitle',
    'alias',
  ];
  final byBucket = <String, Map<String, dynamic>>{};
  for (final b in bucketOrder) {
    final subset = perQuery.where((r) => r['bucket'] == b).toList();
    final hits = subset.where((r) => r['hitAt10'] == true).length;
    byBucket[b] = {
      'label': _bucketLabel(b),
      'count': subset.length,
      'hits': hits,
      'recallAt10': subset.isEmpty ? null : hits / subset.length,
      'b3b4Link': _b3b4Link(b),
    };
  }

  // GAP subset (translation/identity — B-3 proxy)
  final gapQueries = perQuery.where((r) => (r['tags'] as List).contains('GAP')).toList();
  final gapHits = gapQueries.where((r) => r['hitAt10'] == true).length;

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'registry': '402',
    'indexPath': 'akasha-db/search_index.json',
    'overall': overallHits,
    'byBucket': byBucket,
    'gapDiagnostic': {
      'count': gapQueries.length,
      'hits': gapHits,
      'recallAt10': gapQueries.isEmpty ? null : gapHits / gapQueries.length,
      'note': 'B-3 identity-resolution proxy — EN/ZH query vs missing titles.en/alias',
    },
    'perQuery': perQuery,
  };

  final outFile = File(p.join(outDir.path, 'sw1_a_report.json'));
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  print('SW1-A — 402 baseline recall@10');
  print('  eval: ${eval.length} queries');
  print('  overall recall@10: ${(overallHits['recallAt10'] as double).toStringAsFixed(4)} '
      '(${overallHits['hits']}/${overallHits['evalCount']})');
  print('');
  for (final b in bucketOrder) {
    final s = byBucket[b]!;
    final r = s['recallAt10'];
    print('  ${s['label']}: ${r == null ? 'n/a' : (r as double).toStringAsFixed(4)} '
        '(${s['hits']}/${s['count']})  [${s['b3b4Link']}]');
  }
  print('');
  print('  GAP diagnostic (B-3 proxy): ${gapQueries.isEmpty ? 'n/a' : '${(gapHits / gapQueries.length).toStringAsFixed(4)} ($gapHits/${gapQueries.length})'}');
  print('Wrote: ${outFile.path}');
}

String _bucketLabel(String b) => switch (b) {
      'original' => '1. 원제 검색',
      'english' => '2. 영어 제목 검색',
      'translation' => '3. 번역 제목 검색',
      'series_subtitle' => '4. 시즌/부제 검색',
      'alias' => '5. Alias 검색',
      _ => b,
    };

String _b3b4Link(String b) => switch (b) {
      'translation' => 'B-3 다국어 표면형',
      'series_subtitle' => 'B-4 부제/시즌 변형',
      'alias' => 'B-3/B-4 alias 보강',
      'original' => 'B-2 title 보존',
      'english' => 'B-2 en 표기',
      _ => '',
    };

/// SW1-A 5버킷 — 쿼리당 1개 (우선순위: alias > series > translation > english > original)
String _sw1Bucket(GsQuery q) {
  final tags = q.tags;
  if (tags.contains('ABBR') || tags.contains('ALIAS')) return 'alias';
  if (tags.contains('SERIES')) return 'series_subtitle';

  if (tags.contains('GAP')) return 'translation';

  if (tags.contains('EN_ZH') ||
      tags.contains('EN_JA') ||
      tags.contains('EN_KO') ||
      tags.contains('JA_EN') ||
      tags.contains('KO_EN')) {
    return 'translation';
  }

  if (tags.contains('ORIG_LOC')) {
    if (_hasCjk(q.query)) return 'original';
    return 'english';
  }

  if (_isMostlyLatin(q.query)) return 'english';
  return 'original';
}

bool _hasCjk(String s) =>
    RegExp(r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]').hasMatch(s);

bool _isMostlyLatin(String s) {
  if (s.isEmpty) return false;
  final latin = RegExp(r'[A-Za-z]').allMatches(s).length;
  return latin >= s.replaceAll(' ', '').length * 0.5;
}

bool _hit(GsQuery q, List<String> topK) {
  final expected = {...q.expectedWorkIds, ...q.acceptableWorkIds};
  return expected.any(topK.contains);
}

int? _rank(GsQuery q, List<String> topK) {
  final expected = {...q.expectedWorkIds, ...q.acceptableWorkIds};
  for (var i = 0; i < topK.length; i++) {
    if (expected.contains(topK[i])) return i + 1;
  }
  return null;
}

String? _failureTag(GsQuery q, List<String> topK, List<Map<String, dynamic>> index) {
  final expected = q.expectedWorkIds.isNotEmpty ? q.expectedWorkIds.first : null;
  if (expected == null) return 'NO_EXPECTED';

  final entry = index.cast<Map<String, dynamic>?>().firstWhere(
        (e) => e!['workId'] == expected,
        orElse: () => null,
      );
  if (entry == null) return 'MISSING_WORK';

  final tokens = (entry['searchTokens'] as List?)?.map((e) => e.toString()).toList() ?? [];
  final tokenHit = tokens.any((t) => registryTokenMatchesQuery(t, q.query));
  if (!tokenHit) {
    if (tagsContainGap(q)) return 'MISSING_LOCALE';
    return 'MISSING_TOKEN';
  }
  return 'RANKING';
}

bool tagsContainGap(GsQuery q) => q.tags.contains('GAP');

List<String> _searchTopK(List<Map<String, dynamic>> index, String query, {required int k}) {
  final q = normalizeRegistryQuery(query);
  if (q.isEmpty) return [];

  final hits = <_Hit>[];
  for (final entry in index) {
    final tokens = (entry['searchTokens'] as List?)?.map((e) => e.toString()).toList() ?? [];
    var match = false;
    for (final token in tokens) {
      if (registryTokenMatchesQuery(token, query)) {
        match = true;
        break;
      }
    }
    if (!match) {
      final title = entry['title']?.toString() ?? '';
      if (registryTokenMatchesQuery(title, query)) match = true;
    }
    if (!match) continue;
    hits.add(_Hit(
      entry['workId']?.toString() ?? '',
      (entry['qualityScore'] as num?)?.toInt() ?? 0,
      entry['title']?.toString() ?? '',
    ));
  }

  hits.sort((a, b) {
    final sc = b.score.compareTo(a.score);
    if (sc != 0) return sc;
    return a.title.compareTo(b.title);
  });
  return hits.take(k).map((h) => h.workId).where((id) => id.isNotEmpty).toList();
}

class _Hit {
  final String workId;
  final int score;
  final String title;
  const _Hit(this.workId, this.score, this.title);
}

class GsQuery {
  final String id;
  final String query;
  final List<String> expectedWorkIds;
  final List<String> acceptableWorkIds;
  final List<String> tags;
  final String persona;
  final String hypothesis402;
  final bool excludeFromRecall;

  const GsQuery({
    required this.id,
    required this.query,
    required this.expectedWorkIds,
    this.acceptableWorkIds = const [],
    this.tags = const [],
    this.persona = '',
    this.hypothesis402 = '',
    this.excludeFromRecall = false,
  });
}

List<Map<String, dynamic>> _loadIndex(Directory root) {
  final path = File(p.join(root.path, 'akasha-db', 'search_index.json'));
  final decoded = json.decode(path.readAsStringSync());
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<GsQuery> _loadQueries(Directory root) {
  final path = File(p.join(root.path, 'docs', 'global-search-query-set.md'));
  final lines = path.readAsLinesSync();
  final out = <GsQuery>[];

  for (final line in lines) {
    if (!line.startsWith('| GS')) continue;
    if (line.contains('id | query')) continue;

    final parts = line.split('|').map((s) => s.trim()).toList();
    if (parts.length < 8) continue;

    final id = parts[1];
    final query = parts[2].replaceAll('`', '');

    // Section G: | id | query | expected | acceptable | tags | W | persona | hyp |
    String expectedRaw;
    String tagsRaw;
    String persona;
    String hyp;
    List<String> acceptable = const [];

    final isSeriesRow = parts.length >= 9 && RegExp(r'^W\d').hasMatch(parts[6]);
    if (isSeriesRow) {
      expectedRaw = parts[3];
      acceptable = parts[4] == '—' ? [] : _wkIds(parts[4]);
      tagsRaw = parts[5];
      persona = parts[7];
      hyp = parts[8].replaceAll('*', '').replaceAll('†', '').replaceAll('‡', '').trim();
    } else {
      expectedRaw = parts[3];
      tagsRaw = parts[4];
      persona = parts.length > 6 ? parts[6] : '';
      hyp = parts.length > 7
          ? parts[7].replaceAll('*', '').replaceAll('†', '').replaceAll('‡', '').trim()
          : '';
    }

    final exclude = expectedRaw.contains('미수록') ||
        expectedRaw.contains('402에') && !expectedRaw.contains('wk_') ||
        expectedRaw.trim() == '—' ||
        hyp == 'FAIL';

    final tags = tagsRaw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    out.add(GsQuery(
      id: id,
      query: query,
      expectedWorkIds: _wkIds(expectedRaw),
      acceptableWorkIds: acceptable,
      tags: tags,
      persona: persona,
      hypothesis402: hyp,
      excludeFromRecall: exclude,
    ));
  }
  return out;
}

List<String> _wkIds(String raw) =>
    RegExp(r'wk_\d+').allMatches(raw).map((m) => m.group(0)!).toList();

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
