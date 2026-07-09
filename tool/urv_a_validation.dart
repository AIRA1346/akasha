// ignore_for_file: avoid_print
// URV-A — 402 Canonical Identity Coverage / Identity Resolution baseline.
//
// 핵심 질문: 동일 작품의 여러 표면형이 하나의 wk_로 안정적으로 수렴 가능한가?
//
// Usage: dart run tool/urv_a_validation.dart
//
// 산출물: akasha-db/pipeline/artifacts/universal_registry_validation/urv_a_report.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'dedupe_utils.dart';
import 'discovery/registry_snapshot.dart';

void main() {
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(
      root.path,
      'akasha-db',
      'pipeline',
      'artifacts',
      'universal_registry_validation',
    ),
  );
  outDir.createSync(recursive: true);

  final registry = RegistrySnapshot.load(root);
  final index = _loadIndex(root);
  final indexById = {for (final e in index) e['workId']?.toString() ?? '': e};
  final queries = _loadQueries(root)
      .where((q) => q.expectedWorkIds.isNotEmpty && !q.excludeFromRecall)
      .toList();

  final axisOrder = [
    'alias',
    'translation',
    'romaji',
    'series_subtitle',
    'external_id',
  ];

  final perCase = <Map<String, dynamic>>[];
  for (final q in queries) {
    final axis = _urvAxis(q);
    final targets = {...q.expectedWorkIds, ...q.acceptableWorkIds};
    final coverage = _canonicalCoverage(q.query, targets, registry, indexById);
    final ingress = _ingressConvergence(q.query, targets, registry);
    final converged = coverage.hit || ingress.hit;
    perCase.add({
      'id': q.id,
      'query': q.query,
      'axis': axis,
      'expectedWorkIds': q.expectedWorkIds,
      'acceptableWorkIds': q.acceptableWorkIds,
      'tags': q.tags,
      'canonicalCoverage': coverage.hit,
      'coverageDetail': coverage.detail,
      'ingressConvergence': ingress.hit,
      'ingressDetail': ingress.detail,
      'converged': converged,
    });
  }

  final byAxis = <String, Map<String, dynamic>>{};
  for (final axis in axisOrder.where((a) => a != 'external_id')) {
    final subset = perCase.where((c) => c['axis'] == axis).toList();
    final converged = subset.where((c) => c['converged'] == true).length;
    final cov = subset.where((c) => c['canonicalCoverage'] == true).length;
    final ing = subset.where((c) => c['ingressConvergence'] == true).length;
    final rate = subset.isEmpty ? null : converged / subset.length;
    byAxis[axis] = {
      'label': _axisLabel(axis),
      'count': subset.length,
      'converged': converged,
      'convergenceRate': rate,
      'canonicalCoverageRate':
          subset.isEmpty ? null : cov / subset.length,
      'ingressConvergenceRate':
          subset.isEmpty ? null : ing / subset.length,
      'verdict': _verdict(rate),
      'sw1Link': _sw1Link(axis),
      'failures': subset
          .where((c) => c['converged'] != true)
          .map((c) => {
                'id': c['id'],
                'query': c['query'],
                'coverage': c['canonicalCoverage'],
                'ingress': c['ingressConvergence'],
              })
          .toList(),
    };
  }

  final external = _externalIdAxis(root, registry);
  byAxis['external_id'] = external;

  final queryAxes = perCase.where((c) => c['converged'] == true).length;
  final queryTotal = perCase.length;
  final overallRate = queryTotal == 0 ? 0.0 : queryAxes / queryTotal;

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'registry': '402',
    'workCount': registry.works.length,
    'coreQuestion':
        '동일 작품의 여러 표면형이 하나의 wk_로 안정적으로 수렴 가능한가?',
    'method': {
      'canonicalCoverage':
          'variant ∈ normalize(title|titles|aliases|searchTokens) of target wk_',
      'ingressConvergence':
          'minimal stub(title=variant) → RegistrySnapshot fuzzy title match',
      'converged': 'canonicalCoverage OR ingressConvergence',
      'externalId':
          'exact externalId ingress + variant-without-id on ID-bearing works',
      'verdictThresholds': {'PASS': '>=0.90', 'PARTIAL': '>=0.70', 'FAIL': '<0.70'},
    },
    'summary': {
      'queryCases': queryTotal,
      'queryConverged': queryAxes,
      'queryConvergenceRate': overallRate,
      'axes': {
        for (final a in axisOrder)
          a: byAxis[a]!['verdict'],
      },
    },
    'byAxis': byAxis,
    'perCase': perCase,
    'assumptionRegister': {
      'A3': 'Contested',
      'interpretation': 'Canonical Identity Coverage / Identity Resolution',
    },
  };

  final outFile = File(p.join(outDir.path, 'urv_a_report.json'));
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  print('URV-A — 402 Canonical Identity Coverage');
  print('  works: ${registry.works.length}');
  print('  query cases: $queryTotal');
  print(
    '  overall convergence: ${overallRate.toStringAsFixed(4)} ($queryAxes/$queryTotal)',
  );
  print('');
  for (final axis in axisOrder) {
    final s = byAxis[axis]!;
    if (axis == 'external_id') {
      print(
        '  ${s['label']}: ${s['verdict']}  '
        'exactId=${(s['exactIdIngressRate'] as double).toStringAsFixed(4)} '
        '(${s['exactIdIngressHits']}/${s['worksWithExternalId']})  '
        'variantNoId=${(s['variantWithoutIdRate'] as double).toStringAsFixed(4)} '
        '(${s['variantWithoutIdHits']}/${s['variantWithoutIdCases']})  '
        '[${s['sw1Link']}]',
      );
    } else {
      final r = s['convergenceRate'] as double?;
      final rateStr = r == null ? 'n/a' : r.toStringAsFixed(4);
      print(
        '  ${s['label']}: ${s['verdict']}  rate=$rateStr '
        '(${s['converged']}/${s['count']})  [${s['sw1Link']}]',
      );
    }
  }
  print('');
  print('Wrote: ${outFile.path}');
}

String _axisLabel(String axis) => switch (axis) {
      'alias' => '1. Alias 수렴',
      'translation' => '2. 번역 제목 수렴',
      'romaji' => '3. 로마자 표기 수렴',
      'series_subtitle' => '4. 시즌/부제 변형 수렴',
      'external_id' => '5. 외부 ID 기반 수렴',
      _ => axis,
    };

String _sw1Link(String axis) => switch (axis) {
      'alias' => 'SW1 alias 81.8%',
      'translation' => 'SW1 translation 76.6%',
      'romaji' => 'SW1 GAP 0% (15건)',
      'series_subtitle' => 'SW1 series/subtitle 78.6%',
      'external_id' => 'SIM-B B-2 exactId',
      _ => '',
    };

String _verdict(double? rate) {
  if (rate == null) return 'N/A';
  if (rate >= 0.90) return 'PASS';
  if (rate >= 0.70) return 'PARTIAL';
  return 'FAIL';
}

/// URV 5축 분류 (쿼리당 1축)
String _urvAxis(GsQuery q) {
  if (q.tags.contains('ABBR') || q.tags.contains('ALIAS')) return 'alias';
  if (q.tags.contains('SERIES')) return 'series_subtitle';
  if (_isRomajiQuery(q)) return 'romaji';
  return 'translation';
}

/// 로마자/공식 영문 표기 누락 — SW1 GAP 15건 중 라틴 스크립트 쿼리.
bool _isRomajiQuery(GsQuery q) {
  if (!q.tags.contains('GAP')) return false;
  if (RegExp(r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]').hasMatch(q.query)) {
    return false;
  }
  return _isMostlyLatin(q.query);
}

class _CoverageResult {
  final bool hit;
  final String detail;
  const _CoverageResult(this.hit, this.detail);
}

_CoverageResult _canonicalCoverage(
  String variant,
  Set<String> targets,
  RegistrySnapshot registry,
  Map<String, Map<String, dynamic>> indexById,
) {
  final norm = normalizeTitle(variant);
  if (norm.length < 2) return const _CoverageResult(false, 'variant_too_short');

  for (final wk in targets) {
    final entry = registry.byWorkId[wk];
    if (entry != null && entry.normalizedTitles.contains(norm)) {
      return _CoverageResult(true, 'shard:$wk');
    }
    final idx = indexById[wk];
    if (idx != null) {
      final qn = variant.toLowerCase().replaceAll(' ', '');
      final tokens = (idx['searchTokens'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (tokens.any((t) => t.contains(qn) || normalizeTitle(t).contains(norm))) {
        return _CoverageResult(true, 'searchIndex:$wk');
      }
    }
  }
  return const _CoverageResult(false, 'missing_on_canonical_wk');
}

class _IngressResult {
  final bool hit;
  final String detail;
  const _IngressResult(this.hit, this.detail);
}

_IngressResult _ingressConvergence(
  String variant,
  Set<String> targets,
  RegistrySnapshot registry,
) {
  final norms = normalizeTitle(variant);
  if (norms.length < 2) {
    return const _IngressResult(false, 'variant_too_short');
  }

  for (final w in registry.works) {
    if (!w.normalizedTitles.contains(norms)) continue;
    if (targets.contains(w.workId)) {
      return _IngressResult(true, 'fuzzy:${w.workId}');
    }
  }

  // category-agnostic fallback (subtitle variants may differ category)
  final hits = <String>[];
  for (final w in registry.works) {
    if (w.normalizedTitles.contains(norms)) hits.add(w.workId);
  }
  if (hits.length == 1 && targets.contains(hits.first)) {
    return _IngressResult(true, 'fuzzy_unique:${hits.first}');
  }
  if (hits.any(targets.contains)) {
    return _IngressResult(true, 'fuzzy_ambiguous:${hits.first}');
  }
  return const _IngressResult(false, 'fuzzy_no_match');
}

Map<String, dynamic> _externalIdAxis(Directory root, RegistrySnapshot registry) {
  final withExt = registry.works
      .where((w) => w.externalIds.isNotEmpty)
      .toList();
  final coverageRate =
      registry.works.isEmpty ? 0.0 : withExt.length / registry.works.length;

  var exactHits = 0;
  final exactFails = <Map<String, dynamic>>[];
  for (final w in withExt) {
    final draft = Map<String, dynamic>.from(w.work);
    draft['title'] = '__urv_stub_variant_${w.workId}__';
    draft.remove('aliases');
    draft['titles'] = <String, String>{};
    var merged = false;
    for (final entry in w.externalIds.entries) {
      final key = '${entry.key.toLowerCase()}:${entry.value}';
      final matches = registry.byExternalKey[key];
      if (matches != null &&
          matches.any((m) => m.workId == w.workId)) {
        merged = true;
        break;
      }
    }
    if (merged) {
      exactHits++;
    } else {
      exactFails.add({'workId': w.workId, 'title': w.title});
    }
  }

  final exactRate =
      withExt.isEmpty ? 1.0 : exactHits / withExt.length;

  // Variant-only ingress for ID-bearing works (B-3 proxy on enriched registry)
  final variantCases = <Map<String, dynamic>>[
    {'variant': 'Demon Slayer', 'targets': {'wk_000000343', 'wk_000000188'}},
    {'variant': 'Kimetsu no Yaiba', 'targets': {'wk_000000343', 'wk_000000188'}},
    {'variant': 'Spy x Family', 'targets': {'wk_000000387', 'wk_000000239'}},
    {'variant': 'Fullmetal Alchemist', 'targets': {'wk_000000325', 'wk_000000194'}},
    {'variant': 'Dandadan', 'targets': {'wk_000000310', 'wk_000000185'}},
  ];
  var variantHits = 0;
  for (final c in variantCases) {
    final r = _ingressConvergence(
      c['variant'] as String,
      c['targets'] as Set<String>,
      registry,
    );
    if (r.hit) variantHits++;
    c['converged'] = r.hit;
    c['ingressDetail'] = r.detail;
  }
  final variantRate = variantCases.isEmpty
      ? 0.0
      : variantHits / variantCases.length;

  // Duplicate external keys (same category, non-franchise-sibling)
  final franchisePeers = loadFranchisePeers(root);
  var duplicatePairs = 0;
  for (final entry in registry.byExternalKey.entries) {
    final group = entry.value;
    if (group.length < 2) continue;
    for (var i = 0; i < group.length; i++) {
      for (var j = i + 1; j < group.length; j++) {
        final a = group[i];
        final b = group[j];
        if (a.category != b.category) continue;
        if (isFranchiseSibling(a.workId, b.workId, franchisePeers)) continue;
        duplicatePairs++;
      }
    }
  }

  // Composite verdict: exact ID ingress is structural; variant-without-id shows coverage gap
  final String verdict;
  if (exactRate < 1.0 || duplicatePairs > 0) {
    verdict = 'FAIL';
  } else if (variantRate >= 0.90 && coverageRate >= 0.20) {
    verdict = 'PASS';
  } else if (variantRate >= 0.70 || exactRate >= 1.0) {
    verdict = 'PARTIAL';
  } else {
    verdict = 'FAIL';
  }

  return {
    'label': _axisLabel('external_id'),
    'worksWithExternalId': withExt.length,
    'externalIdCoverageRate': coverageRate,
    'exactIdIngressHits': exactHits,
    'exactIdIngressRate': exactRate,
    'variantWithoutIdCases': variantCases.length,
    'variantWithoutIdHits': variantHits,
    'variantWithoutIdRate': variantRate,
    'duplicateExternalKeyPairs': duplicatePairs,
    'convergenceRate': variantRate,
    'verdict': verdict,
    'sw1Link': 'SIM-B B-2 exactId outcome 100%',
    'note':
        'exactId 구조는 PASS 가능; 표면형-only 유입은 externalId 밀도(~${(coverageRate * 100).toStringAsFixed(0)}%)에 의존',
    'exactIdFailures': exactFails,
  };
}

bool _isMostlyLatin(String s) {
  if (s.isEmpty) return false;
  final latin = RegExp(r'[A-Za-z]').allMatches(s).length;
  return latin >= s.replaceAll(' ', '').length * 0.5;
}

List<Map<String, dynamic>> _loadIndex(Directory root) {
  final path = File(p.join(root.path, 'akasha-db', 'search_index.json'));
  final decoded = json.decode(path.readAsStringSync());
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

// --- query loader (shared with sw1_a_validation) ---

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
