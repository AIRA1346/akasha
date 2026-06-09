// ignore_for_file: avoid_print
/// Coverage Sprint 02 — Registry-wide Coverage Economics (운영 규모 추정).
///
/// Usage: dart run tool/coverage_sprint_02_economics.dart
///
/// 산출물: akasha-db/pipeline/artifacts/coverage_dashboard/sprint_02_economics.json

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'dedupe_utils.dart';

const _targetRate = 0.90;
const _milestones = [0.50, 0.75, 0.90];

/// Sprint 01 보정: 작품당 최소 enrich( titles.en · romaji · alias ) 검수 포함 분
const _minutesAutoHigh = 2.0; // tmdb/steam — 배치 fetch + spot check
const _minutesAutoMedium = 5.0; // 기타 externalId
const _minutesManualLow = 8.0; // partial titles · 동일 franchise 템플릿
const _minutesManualHigh = 15.0; // externalId 없음 · 수동 조사

void main() {
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
  );
  outDir.createSync(recursive: true);

  final works = _loadWorks(root);
  final gapPanel = _gapPanelAudit(works);
  final economics = _registryWideEconomics(works);
  final calibration = _sprint01Calibration();

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sprint': 'Coverage Sprint 02: Coverage Economics',
    'registryWorkCount': works.length,
    'targetRate': _targetRate,
    'calibration': calibration,
    'gapPanel': gapPanel,
    'registryWide': economics,
    'composite': _compositeEstimate(economics),
    'method': {
      'purpose': 'Registry-wide Coverage 90% 운영 비용 추정 — 구조 검증 아님',
      'costUnit': 'maintainer_minutes per work (Sprint 01 보정)',
      'automationTier': {
        'auto_high': 'externalIds.tmdb|steam|igdb — 기존 도구로 titles.en·ja 후보',
        'auto_medium': '기타 externalId — 소스별 반자동',
        'manual_low': 'partial titles 또는 franchise 형제 템플릿 복제',
        'manual_high': 'externalId 없음 — 수동 조사',
      },
      'sprint01Evidence':
          '17 works minimal enrich → SW1/URV 81.6%→100% without structure change',
    },
  };

  final outFile = File(p.join(outDir.path, 'sprint_02_economics.json'));
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  _printReport(report);
  print('Wrote: ${outFile.path}');
}

Map<String, dynamic> _sprint01Calibration() => {
      'worksEnriched': 17,
      'fieldsPerWorkAvg': 5.2,
      'sw1DeltaPp': 18.4,
      'urvDeltaPp': 18.4,
      'gapPanelDelta': '0% → 100%',
      'structureChange': false,
      'impliedMinutesPerWorkManual': 8.0,
      'note': 'Sprint 01 패치 작성·적용·회귀 합산 ~2.3h / 17작 ≈ 8분/작 (검수 포함)',
    };

Map<String, dynamic> _gapPanelAudit(List<_Work> works) {
  final cases = _gapPanelCases();
  var hits = 0;
  final failures = <String>[];
  for (final c in cases) {
    final variant = c['variant'] as String;
    final ids = (c['workIds'] as List).cast<String>();
    final norms = normalizeTitle(variant);
    var ok = false;
    for (final id in ids) {
      final w = works.where((x) => x.workId == id).firstOrNull;
      if (w == null) continue;
      if (w.allSurfaces.contains(norms)) ok = true;
    }
    if (ok) {
      hits++;
    } else {
      failures.add(c['id'] as String);
    }
  }
  return {
    'panelCount': cases.length,
    'hits': hits,
    'remainingGap': cases.length - hits,
    'rate': hits / cases.length,
    'failures': failures,
    'status': hits == cases.length ? 'PASS' : 'FAIL',
  };
}

Map<String, dynamic> _registryWideEconomics(List<_Work> works) {
  final total = works.length;
  final kpis = <String, Map<String, dynamic>>{};

  kpis['titles_en'] = _axisEconomics(
    works,
    total,
    (w) => _has(w.titles['en']),
    _enrichTier,
    'titles.en',
  );

  kpis['romanized_alias'] = _axisEconomics(
    works.where((w) => w.needsRoman).toList(),
    works.where((w) => w.needsRoman).length,
    (w) => w.hasRoman,
    _enrichTier,
    'romanized (romaji|en|latin alias)',
  );

  kpis['titles_zh'] = _axisEconomics(
    works,
    total,
    (w) => _has(w.titles['zh']),
    _enrichTier,
    'titles.zh',
  );

  kpis['alias_field'] = _axisEconomics(
    works,
    total,
    (w) => w.aliases.isNotEmpty,
    _enrichTier,
    'aliases[]',
  );

  kpis['external_id'] = _axisEconomics(
    works,
    total,
    (w) => w.externalIds.isNotEmpty,
    _enrichTier,
    'externalIds',
  );

  final animDrama = works.where((w) => w.category == 'animation' || w.category == 'drama').toList();
  kpis['season_extensions'] = _axisEconomics(
    animDrama,
    animDrama.length,
    (w) => w.seasons.isNotEmpty,
    _enrichTier,
    'extensions.seasons',
    targetRate: 0.80,
  );

  return kpis;
}

Map<String, dynamic> _axisEconomics(
  List<_Work> pool,
  int denominator,
  bool Function(_Work) satisfied,
  String Function(_Work) tierOf,
  String label, {
  double targetRate = _targetRate,
}) {
  final missing = pool.where((w) => !satisfied(w)).toList();
  final current = denominator - missing.length;
  final currentRate = denominator == 0 ? 0.0 : current / denominator;

  final milestones = <String, Map<String, dynamic>>{};
  for (final m in _milestones) {
    final effectiveTarget = m == 0.90 ? targetRate : m;
    final need = max(0, (denominator * effectiveTarget).ceil() - current);
    final subset = missing.take(need).toList();
    final cost = _sumMinutes(subset, tierOf);
    milestones['${(effectiveTarget * 100).round()}%'] = {
      'targetCount': (denominator * effectiveTarget).ceil(),
      'currentCount': current,
      'additionalWorks': min(need, missing.length),
      'estimatedMinutes': cost,
      'estimatedHours': (cost / 60).toStringAsFixed(1),
    };
  }

  final tierBreakdown = _tierBreakdown(missing, tierOf);
  final automation = _automationRatio(missing, tierOf);

  return {
    'label': label,
    'denominator': denominator,
    'currentCount': current,
    'currentRate': currentRate,
    'targetRate': targetRate,
    'remainingToTarget': max(0, (denominator * targetRate).ceil() - current),
    'missingCount': missing.length,
    'milestones': milestones,
    'tierBreakdown': tierBreakdown,
    'automation': automation,
    'avgMinutesPerMissingWork': missing.isEmpty
        ? 0.0
        : _sumMinutes(missing, tierOf) / missing.length,
  };
}

Map<String, dynamic> _compositeEstimate(Map<String, dynamic> registryWide) {
  // Binding axis: titles.en @ 90% (largest SW1/identity lever per Sprint 01)
  final en = registryWide['titles_en'] as Map<String, dynamic>;
  final missing = en['missingCount'] as int;
  final to90 = en['remainingToTarget'] as int;

  final pool = _loadWorks(_findProjectRoot());
  final missingWorks =
      pool.where((w) => !_has(w.titles['en'])).toList();
  final for90 = missingWorks.take(to90).toList();

  final totalMin = _sumMinutes(for90, _enrichTier);
  final auto = _automationRatio(for90, _enrichTier);

  return {
    'bindingKpi': 'titles.en @ 90%',
    'worksToTarget': to90,
    'estimatedTotalMinutes': totalMin,
    'estimatedTotalHours': (totalMin / 60).toStringAsFixed(1),
    'estimatedMaintainerDays_4h': (totalMin / 240).toStringAsFixed(1),
    'avgMinutesPerWork': for90.isEmpty ? 0 : totalMin / for90.length,
    'automation': auto,
    'allAxesRemainingTo90': {
      'titles_en': en['remainingToTarget'],
      'romanized': (registryWide['romanized_alias'] as Map)['remainingToTarget'],
      'titles_zh': (registryWide['titles_zh'] as Map)['remainingToTarget'],
      'alias_field': (registryWide['alias_field'] as Map)['remainingToTarget'],
      'external_id': (registryWide['external_id'] as Map)['remainingToTarget'],
    },
    'note':
        '축별 작업 중복 가능 — composite는 titles.en 90% 단일 축 보수 추정',
  };
}

Map<String, dynamic> _automationRatio(List<_Work> works, String Function(_Work) tierOf) {
  if (works.isEmpty) {
    return {'automatableWorks': 0, 'manualWorks': 0, 'automatableRate': 0.0};
  }
  var auto = 0;
  for (final w in works) {
    final t = tierOf(w);
    if (t == 'auto_high' || t == 'auto_medium') auto++;
  }
  return {
    'automatableWorks': auto,
    'manualWorks': works.length - auto,
    'automatableRate': auto / works.length,
    'automatablePercent': ((auto / works.length) * 100).toStringAsFixed(1),
  };
}

Map<String, int> _tierBreakdown(List<_Work> works, String Function(_Work) tierOf) {
  final counts = <String, int>{};
  for (final w in works) {
    final t = tierOf(w);
    counts[t] = (counts[t] ?? 0) + 1;
  }
  return counts;
}

double _sumMinutes(List<_Work> works, String Function(_Work) tierOf) {
  var sum = 0.0;
  for (final w in works) {
    sum += _minutesForTier(tierOf(w));
  }
  return sum;
}

double _minutesForTier(String tier) => switch (tier) {
      'auto_high' => _minutesAutoHigh,
      'auto_medium' => _minutesAutoMedium,
      'manual_low' => _minutesManualLow,
      'manual_high' => _minutesManualHigh,
      _ => _minutesManualHigh,
    };

String _enrichTier(_Work w) {
  final ext = w.externalIds;
  if (ext.containsKey('tmdb') || ext.containsKey('steam') || ext.containsKey('igdb')) {
    return 'auto_high';
  }
  if (ext.isNotEmpty) return 'auto_medium';
  if (_has(w.titles['ja']) ||
      _has(w.titles['en']) ||
      _has(w.titles['romaji']) ||
      w.aliases.isNotEmpty) {
    return 'manual_low';
  }
  return 'manual_high';
}

bool _has(String? s) => s != null && s.trim().isNotEmpty;

void _printReport(Map<String, dynamic> report) {
  print('Coverage Sprint 02 — Economics');
  print('  works: ${report['registryWorkCount']}');
  final gap = report['gapPanel'] as Map;
  print('  GAP panel remaining: ${gap['remainingGap']}/${gap['panelCount']}');
  print('');
  final rw = report['registryWide'] as Map<String, dynamic>;
  for (final entry in rw.entries) {
    final e = entry.value as Map<String, dynamic>;
    print('  ${entry.key}: ${(e['currentRate'] as double).toStringAsFixed(3)} '
        '→ 90% needs +${e['remainingToTarget']} works '
        '(avg ${(e['avgMinutesPerMissingWork'] as double).toStringAsFixed(1)} min/missing)');
    final auto = e['automation'] as Map;
    print('    automation: ${auto['automatablePercent']}% of missing');
  }
  print('');
  final c = report['composite'] as Map;
  print('  composite (titles.en 90%): ${c['estimatedTotalHours']}h '
      '(${c['estimatedMaintainerDays_4h']} maintainer-days @4h) '
      'automation ${(c['automation'] as Map)['automatablePercent']}%');
}

// --- gap panel cases (mirror coverage_dashboard) ---

List<Map<String, dynamic>> _gapPanelCases() => [
      {'id': 'GAP-romaji-01', 'variant': 'Demon Slayer', 'workIds': ['wk_000000343', 'wk_000000188']},
      {'id': 'GAP-romaji-02', 'variant': 'Kimetsu no Yaiba', 'workIds': ['wk_000000343', 'wk_000000188']},
      {'id': 'GAP-romaji-03', 'variant': 'Spy x Family', 'workIds': ['wk_000000387', 'wk_000000239']},
      {'id': 'GAP-romaji-04', 'variant': 'Fullmetal Alchemist', 'workIds': ['wk_000000325', 'wk_000000194']},
      {'id': 'GAP-romaji-05', 'variant': 'Mushoku Tensei', 'workIds': ['wk_000000354', 'wk_000000257']},
      {'id': 'GAP-romaji-06', 'variant': 'Re:Zero', 'workIds': ['wk_000000230', 'wk_000000375']},
      {'id': 'GAP-romaji-07', 'variant': '20th Century Boys', 'workIds': ['wk_000000291']},
      {'id': 'GAP-cjk-01', 'variant': '鬼滅の刃', 'workIds': ['wk_000000343', 'wk_000000188']},
      {'id': 'GAP-cjk-02', 'variant': '鬼灭之刃', 'workIds': ['wk_000000343', 'wk_000000188']},
      {'id': 'GAP-cjk-03', 'variant': '死亡笔记', 'workIds': ['wk_000000187']},
      {'id': 'GAP-cjk-04', 'variant': '火影忍者', 'workIds': ['wk_000000218']},
      {'id': 'GAP-alias-01', 'variant': 'Re:ゼロ', 'workIds': ['wk_000000230']},
      {'id': 'GAP-alias-02', 'variant': 'FMA', 'workIds': ['wk_000000194', 'wk_000000325']},
      {'id': 'GAP-series-01', 'variant': 'Lord of the Rings', 'workIds': ['wk_000000010', 'wk_000000158']},
      {'id': 'GAP-series-02', 'variant': 'The Fellowship of the Ring', 'workIds': ['wk_000000010']},
      {'id': 'GAP-series-03', 'variant': 'Dandadan', 'workIds': ['wk_000000310', 'wk_000000185']},
    ];

class _Work {
  final String workId;
  final String category;
  final Map<String, String> titles;
  final List<String> aliases;
  final Map<String, String> externalIds;
  final List<dynamic> seasons;
  final bool needsRoman;
  final bool hasRoman;
  final Set<String> allSurfaces;

  _Work({
    required this.workId,
    required this.category,
    required this.titles,
    required this.aliases,
    required this.externalIds,
    required this.seasons,
    required this.needsRoman,
    required this.hasRoman,
    required this.allSurfaces,
  });
}

List<_Work> _loadWorks(Directory root) {
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;

  final latinAlias = RegExp(r"^[A-Za-z][A-Za-z0-9 :.'\-]{2,}$");
  final out = <_Work>[];

  for (final shardMeta in manifest['shards'] as List) {
    final path = p.join(root.path, 'akasha-db', (shardMeta as Map)['path'] as String);
    final shard = jsonDecode(File(path).readAsStringSync()) as Map;
    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final w = Map<String, dynamic>.from(entry.value as Map);
      final workId = w['workId']?.toString() ?? entry.key.toString();
      final title = w['title']?.toString() ?? workId;

      final titles = <String, String>{};
      if (w['titles'] is Map) {
        (w['titles'] as Map).forEach((k, v) {
          final s = v?.toString().trim();
          if (s != null && s.isNotEmpty) titles[k.toString()] = s;
        });
      }

      final aliases = <String>[];
      if (w['aliases'] is List) {
        for (final a in w['aliases'] as List) {
          final s = a?.toString().trim();
          if (s != null && s.isNotEmpty) aliases.add(s);
        }
      }

      final externalIds = <String, String>{};
      if (w['externalIds'] is Map) {
        (w['externalIds'] as Map).forEach((k, v) {
          final s = v?.toString().trim();
          if (s != null && s.isNotEmpty) externalIds[k.toString()] = s;
        });
      }

      final seasons = <dynamic>[];
      if (w['extensions'] is Map && (w['extensions'] as Map)['seasons'] is List) {
        seasons.addAll((w['extensions'] as Map)['seasons'] as List);
      }

      final surfaces = <String>{};
      void add(String? t) {
        if (t == null || t.isEmpty) return;
        final n = normalizeTitle(t);
        if (n.isNotEmpty) surfaces.add(n);
      }

      add(title);
      titles.values.forEach(add);
      aliases.forEach(add);

      final cjk = RegExp(r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]').hasMatch(title);
      final needsRoman = cjk || _has(titles['ja']);
      var hasRoman = _has(titles['romaji']) || _has(titles['en']);
      if (!hasRoman) {
        hasRoman = aliases.any(latinAlias.hasMatch);
      }

      out.add(
        _Work(
          workId: workId,
          category: w['category']?.toString() ?? 'unknown',
          titles: titles,
          aliases: aliases,
          externalIds: externalIds,
          seasons: seasons,
          needsRoman: needsRoman,
          hasRoman: hasRoman,
          allSurfaces: surfaces,
        ),
      );
    }
  }
  return out;
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
