// ignore_for_file: avoid_print
// Canonical Identity Coverage Dashboard — 402 baseline KPI 측정.
//
// Usage: dart run tool/coverage_dashboard.dart
//
// 산출물:
//   akasha-db/pipeline/artifacts/coverage_dashboard/coverage_snapshot.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'coverage_quality.dart';
import 'dedupe_utils.dart';

void main() {
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(
      root.path,
      'akasha-db',
      'pipeline',
      'artifacts',
      'coverage_dashboard',
    ),
  );
  outDir.createSync(recursive: true);

  final works = _loadWorks(root);
  final franchise = _loadFranchise(root);
  final panel = _gapPanelCases();

  final total = works.length;
  var titlesEn = 0;
  var titlesKo = 0;
  var titlesJa = 0;
  var titlesZh = 0;
  var titlesRomaji = 0;
  var aliasField = 0;
  var aliasSurface = 0;
  var externalId = 0;
  var seasonExt = 0;
  var animDrama = 0;
  var needsRoman = 0;
  var hasRoman = 0;
  var franchiseNonPrimary = 0;
  var franchiseNonPrimaryEn = 0;

  final latinAlias = RegExp(r"^[A-Za-z][A-Za-z0-9 :.'\-]{2,}$");
  for (final w in works) {
    final titles = w.titles;
    if (_nonEmpty(titles['en'])) titlesEn++;
    if (_nonEmpty(titles['ko']) || _nonEmpty(w.title)) titlesKo++;
    if (_nonEmpty(titles['ja'])) titlesJa++;
    if (_nonEmpty(titles['zh'])) titlesZh++;
    if (_nonEmpty(titles['romaji'])) titlesRomaji++;

    if (w.aliases.isNotEmpty) aliasField++;
    if (w.hasAliasSurface(latinAlias)) aliasSurface++;
    if (w.externalIds.isNotEmpty) externalId++;

    final isAnimDrama = w.category == 'animation' || w.category == 'drama';
    if (isAnimDrama) {
      animDrama++;
      if (w.seasons.isNotEmpty) seasonExt++;
    }

    if (w.needsRomanization) {
      needsRoman++;
      if (w.hasRomanizationSurface(latinAlias)) hasRoman++;
    }

    final fr = franchise.primaryByMember[w.workId];
    if (fr != null && fr != w.workId) {
      franchiseNonPrimary++;
      if (_nonEmpty(titles['en']) || w.aliases.any(latinAlias.hasMatch)) {
        franchiseNonPrimaryEn++;
      }
    }
  }

  final panelResults = <Map<String, dynamic>>[];
  var panelHit = 0;
  for (final c in panel) {
    final hit = _panelVariantPresent(c, works);
    if (hit) panelHit++;
    panelResults.add({...c, 'covered': hit});
  }

  final aliasPanel = _aliasPanelCases();
  var aliasPanelHit = 0;
  final aliasPanelResults = <Map<String, dynamic>>[];
  for (final c in aliasPanel) {
    final hit = _panelVariantPresent(c, works);
    if (hit) aliasPanelHit++;
    aliasPanelResults.add({...c, 'covered': hit});
  }

  final subtitlePanel = _subtitlePanelCases();
  var subtitlePanelHit = 0;
  final subtitlePanelResults = <Map<String, dynamic>>[];
  for (final c in subtitlePanel) {
    final hit = _panelVariantPresent(c, works);
    if (hit) subtitlePanelHit++;
    subtitlePanelResults.add({...c, 'covered': hit});
  }

  final qualityScan = scanTitlesEnQuality(loadRegistryWorkMaps(root));

  final kpis = <String, Map<String, dynamic>>{
    'titles_ko': _kpi(titlesKo, total, target: 0.99),
    'titles_en': _kpi(titlesEn, total, target: 0.90),
    'titles_ja': _kpi(titlesJa, total, target: 0.85),
    'titles_zh': _kpi(titlesZh, total, target: 0.90),
    'romanized_alias': _kpi(hasRoman, needsRoman, target: 0.90),
    'titles_romaji_field': _kpi(titlesRomaji, total, target: 0.70),
    'alias_field': _kpi(aliasField, total, target: 0.90),
    'alias_surface': _kpi(aliasSurface, total, target: 0.90),
    'alias_panel': _kpi(aliasPanelHit, aliasPanel.length, target: 0.90),
    'subtitle_panel': _kpi(
      subtitlePanelHit,
      subtitlePanel.length,
      target: 0.90,
    ),
    'franchise_spinoff_en': _kpi(
      franchiseNonPrimaryEn,
      franchiseNonPrimary,
      target: 0.90,
    ),
    'season_extensions': _kpi(seasonExt, animDrama, target: 0.80),
    'external_id': _kpi(externalId, total, target: 0.90, phaseTarget: 0.50),
    'gap_panel_coverage': _kpi(panelHit, panel.length, target: 0.90),
  };

  final snapshot = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'registry': '402',
    'workCount': total,
    'kpis': kpis,
    'quality': {
      'invalid_en_count': qualityScan.invalidEnCount,
      'invalid_en_rate': qualityScan.invalidEnRate,
      'invalid_en_percent': (qualityScan.invalidEnRate * 100).toStringAsFixed(
        2,
      ),
      'titles_en_populated': qualityScan.titlesEnPopulated,
      'source_breakage_count': qualityScan.sourceBreakageCount,
      'status': qualityScan.status,
      'by_reason': qualityScan.byReason,
      'invalid_en_samples': qualityScan.samples,
      'release_block':
          qualityScan.invalidEnCount > 0 || qualityScan.sourceBreakageCount > 0,
    },
    'gapPanel': {
      'description': 'URV-A/SW1 GAP 표면형 — target wk_에 variant 부착 여부',
      'hits': panelHit,
      'count': panel.length,
      'cases': panelResults,
    },
    'aliasPanel': {
      'description': 'SW1 ABBR/ALIAS 쿼리 — 약칭 표면형 부착 여부',
      'hits': aliasPanelHit,
      'count': aliasPanel.length,
      'cases': aliasPanelResults,
    },
    'subtitlePanel': {
      'description': 'SW1 SERIES/부제 쿼리 — 부제·시리즈 표면형 부착 여부',
      'hits': subtitlePanelHit,
      'count': subtitlePanel.length,
      'cases': subtitlePanelResults,
    },
    'notes': {
      'romanized_alias':
          '분모=로마자 필요 작품(CJK primary 또는 titles.ja). 분자=romaji|en|latin alias',
      'titles_ko':
          '분자=titles.ko 또는 primary title 비어 있지 않음 (E3-B 글로벌 ko 표시 minimum)',
      'alias_surface': 'aliases[] 또는 titles.romaji 또는 latin 약칭형 alias',
      'alias_panel': '운영 게이트 — SW1 alias 버킷(81.8%)과 동일 축',
      'external_id_phaseTarget': 'G2 interim 50% · G3+ 90%',
      'gap_panel': '운영 게이트 — SW1 GAP 15건 표면형 직접 추적',
      'quality':
          'Coverage와 분리 — titles.en syntactic validity (quality-gate-mvp.md)',
    },
  };

  final outFile = File(p.join(outDir.path, 'coverage_snapshot.json'));
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(snapshot),
  );

  print('Coverage Dashboard — 402 snapshot');
  print('  works: $total\n');
  for (final entry in kpis.entries) {
    final k = entry.value;
    print(
      '  ${entry.key}: ${(k['rate'] as double).toStringAsFixed(4)} '
      '(${k['numerator']}/${k['denominator']})  '
      'target=${k['target']}  status=${k['status']}',
    );
  }
  print('\nQuality KPI:');
  print(
    '  invalid_en: ${qualityScan.invalidEnCount}/${qualityScan.titlesEnPopulated} '
    '(${qualityScan.invalidEnRate.toStringAsFixed(4)})  status=${qualityScan.status}',
  );
  print('  source_breakage_count: ${qualityScan.sourceBreakageCount}');
  print(
    '  release_block: ${qualityScan.invalidEnCount > 0 || qualityScan.sourceBreakageCount > 0}',
  );
  print('\nWrote: ${outFile.path}');
}

Map<String, dynamic> _kpi(
  int num,
  int den, {
  required double target,
  double? phaseTarget,
}) {
  final rate = den == 0 ? 0.0 : num / den;
  final effectiveTarget = phaseTarget ?? target;
  final status = rate >= target
      ? 'PASS'
      : rate >= effectiveTarget
      ? 'PARTIAL'
      : 'FAIL';
  return {
    'numerator': num,
    'denominator': den,
    'rate': rate,
    'percent': (rate * 100).toStringAsFixed(1),
    'target': target,
    if (phaseTarget != null) 'phaseTarget': phaseTarget,
    'status': status,
  };
}

bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;

bool _panelVariantPresent(Map<String, dynamic> c, List<_Work> works) {
  final variant = c['variant'] as String;
  final norms = normalizeTitle(variant);
  final ids = (c['workIds'] as List).cast<String>();
  final byId = {for (final w in works) w.workId: w};
  for (final id in ids) {
    final w = byId[id];
    if (w == null) continue;
    if (w.allNormalizedSurfaces.contains(norms)) return true;
    final qn = variant.toLowerCase().replaceAll(' ', '');
    if (w.searchSurfaces.any((s) => s.contains(qn))) return true;
  }
  return false;
}

List<Map<String, dynamic>> _subtitlePanelCases() => [
  {
    'id': 'GS075',
    'variant': '귀멸의 칼날',
    'workIds': ['wk_000000343'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS076',
    'variant': '무한열차',
    'workIds': ['wk_000000404', 'wk_000000405'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS077',
    'variant': '스파이 패밀리',
    'workIds': ['wk_000000387'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS079',
    'variant': '무직전생',
    'workIds': ['wk_000000354'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS080',
    'variant': '반지의 제왕',
    'workIds': ['wk_000000010'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS081',
    'variant': 'Lord of the Rings',
    'workIds': ['wk_000000010', 'wk_000000158'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS082',
    'variant': 'The Fellowship of the Ring',
    'workIds': ['wk_000000010'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS083',
    'variant': '단다단',
    'workIds': ['wk_000000310'],
    'axis': 'subtitle',
  },
  {
    'id': 'GS084',
    'variant': 'Dandadan',
    'workIds': ['wk_000000310', 'wk_000000185'],
    'axis': 'subtitle',
  },
];

List<Map<String, dynamic>> _aliasPanelCases() => [
  {
    'id': 'GS065',
    'variant': 'SAO',
    'workIds': ['wk_000000241'],
    'axis': 'alias',
  },
  {
    'id': 'GS066',
    'variant': 'DanMachi',
    'workIds': ['wk_000000186'],
    'axis': 'alias',
  },
  {
    'id': 'GS067',
    'variant': 'GTO',
    'workIds': ['wk_000000333'],
    'axis': 'alias',
  },
  {
    'id': 'GS068',
    'variant': 'Dr. Stone',
    'workIds': ['wk_000000189'],
    'axis': 'alias',
  },
  {
    'id': 'GS069',
    'variant': 'Shokugeki',
    'workIds': ['wk_000000382'],
    'axis': 'alias',
  },
  {
    'id': 'GS070',
    'variant': '食戟',
    'workIds': ['wk_000000382'],
    'axis': 'alias',
  },
  {
    'id': 'GS071',
    'variant': 'Re:ゼロ',
    'workIds': ['wk_000000230'],
    'axis': 'alias',
  },
  {
    'id': 'GS072',
    'variant': 'FMA',
    'workIds': ['wk_000000194', 'wk_000000325'],
    'axis': 'alias',
  },
  {
    'id': 'GS056',
    'variant': 'GTO',
    'workIds': ['wk_000000333'],
    'axis': 'alias',
  },
  {
    'id': 'GS042',
    'variant': 'Re:제로',
    'workIds': ['wk_000000230'],
    'axis': 'alias',
  },
  {
    'id': 'GS013',
    'variant': 'SAO',
    'workIds': ['wk_000000241'],
    'axis': 'alias',
  },
];

List<Map<String, dynamic>> _gapPanelCases() => [
  {
    'id': 'GAP-romaji-01',
    'variant': 'Demon Slayer',
    'workIds': ['wk_000000343', 'wk_000000188'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-romaji-02',
    'variant': 'Kimetsu no Yaiba',
    'workIds': ['wk_000000343', 'wk_000000188'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-romaji-03',
    'variant': 'Spy x Family',
    'workIds': ['wk_000000387', 'wk_000000239'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-romaji-04',
    'variant': 'Fullmetal Alchemist',
    'workIds': ['wk_000000325', 'wk_000000194'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-romaji-05',
    'variant': 'Mushoku Tensei',
    'workIds': ['wk_000000354', 'wk_000000257'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-romaji-06',
    'variant': 'Re:Zero',
    'workIds': ['wk_000000230', 'wk_000000375'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-romaji-07',
    'variant': '20th Century Boys',
    'workIds': ['wk_000000291'],
    'axis': 'romanized',
  },
  {
    'id': 'GAP-cjk-01',
    'variant': '鬼滅の刃',
    'workIds': ['wk_000000343', 'wk_000000188'],
    'axis': 'translation',
  },
  {
    'id': 'GAP-cjk-02',
    'variant': '鬼灭之刃',
    'workIds': ['wk_000000343', 'wk_000000188'],
    'axis': 'translation',
  },
  {
    'id': 'GAP-cjk-03',
    'variant': '死亡笔记',
    'workIds': ['wk_000000187'],
    'axis': 'translation',
  },
  {
    'id': 'GAP-cjk-04',
    'variant': '火影忍者',
    'workIds': ['wk_000000218'],
    'axis': 'translation',
  },
  {
    'id': 'GAP-alias-01',
    'variant': 'Re:ゼロ',
    'workIds': ['wk_000000230'],
    'axis': 'alias',
  },
  {
    'id': 'GAP-alias-02',
    'variant': 'FMA',
    'workIds': ['wk_000000194', 'wk_000000325'],
    'axis': 'alias',
  },
  {
    'id': 'GAP-series-01',
    'variant': 'Lord of the Rings',
    'workIds': ['wk_000000010', 'wk_000000158'],
    'axis': 'subtitle',
  },
  {
    'id': 'GAP-series-02',
    'variant': 'The Fellowship of the Ring',
    'workIds': ['wk_000000010'],
    'axis': 'subtitle',
  },
  {
    'id': 'GAP-series-03',
    'variant': 'Dandadan',
    'workIds': ['wk_000000310', 'wk_000000185'],
    'axis': 'subtitle',
  },
];

class _FranchiseIndex {
  final Map<String, String> primaryByMember;
  const _FranchiseIndex(this.primaryByMember);
}

_FranchiseIndex _loadFranchise(Directory root) {
  final file = File(p.join(root.path, 'akasha-db', 'franchise_groups.json'));
  final raw = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final map = <String, String>{};
  raw.forEach((key, value) {
    if (key.startsWith('_') || value is! Map) return;
    final primary = value['primaryWorkId']?.toString();
    final members = (value['members'] as List?)?.map((e) => e.toString()) ?? [];
    for (final m in members) {
      map[m] = primary ?? m;
    }
  });
  return _FranchiseIndex(map);
}

class _Work {
  final String workId;
  final String title;
  final String category;
  final Map<String, String> titles;
  final List<String> aliases;
  final Map<String, String> externalIds;
  final List<dynamic> seasons;
  final bool needsRomanization;
  final Set<String> allNormalizedSurfaces;
  final List<String> searchSurfaces;

  _Work({
    required this.workId,
    required this.title,
    required this.category,
    required this.titles,
    required this.aliases,
    required this.externalIds,
    required this.seasons,
    required this.needsRomanization,
    required this.allNormalizedSurfaces,
    required this.searchSurfaces,
  });

  bool hasRomanizationSurface(RegExp latinAlias) {
    if (_nonEmpty(titles['romaji'])) return true;
    if (_nonEmpty(titles['en'])) return true;
    return aliases.any(latinAlias.hasMatch);
  }

  bool hasAliasSurface(RegExp latinAlias) {
    if (aliases.isNotEmpty) return true;
    if (_nonEmpty(titles['romaji'])) return true;
    for (final a in aliases) {
      if (a.length <= 12 && latinAlias.hasMatch(a)) return true;
    }
    final en = titles['en'];
    if (en != null && en.length <= 12 && latinAlias.hasMatch(en)) return true;
    return false;
  }
}

List<_Work> _loadWorks(Directory root) {
  final manifest =
      json.decode(
            File(
              p.join(root.path, 'akasha-db', 'manifest.json'),
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final indexSurfaces = _loadSearchSurfaces(root);
  final out = <_Work>[];

  for (final shardMeta in manifest['shards'] as List) {
    final path = p.join(
      root.path,
      'akasha-db',
      (shardMeta as Map)['path'] as String,
    );
    final shard = json.decode(File(path).readAsStringSync()) as Map;
    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final w = Map<String, dynamic>.from(entry.value as Map);
      final workId = w['workId']?.toString() ?? entry.key.toString();
      final title = w['title']?.toString() ?? workId;
      final category = w['category']?.toString() ?? 'unknown';

      final titles = <String, String>{};
      final rawTitles = w['titles'];
      if (rawTitles is Map) {
        rawTitles.forEach((k, v) {
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
      final ext = w['extensions'];
      if (ext is Map && ext['seasons'] is List) {
        seasons.addAll(ext['seasons'] as List);
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

      final cjkPrimary = RegExp(
        r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]',
      ).hasMatch(title);
      final needsRoman =
          cjkPrimary || _nonEmpty(titles['ja']) || _nonEmpty(titles['native']);

      out.add(
        _Work(
          workId: workId,
          title: title,
          category: category,
          titles: titles,
          aliases: aliases,
          externalIds: externalIds,
          seasons: seasons,
          needsRomanization: needsRoman,
          allNormalizedSurfaces: surfaces,
          searchSurfaces: indexSurfaces[workId] ?? const [],
        ),
      );
    }
  }
  return out;
}

Map<String, List<String>> _loadSearchSurfaces(Directory root) {
  final file = File(p.join(root.path, 'akasha-db', 'search_index.json'));
  if (!file.existsSync()) return {};
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! List) return {};
  final out = <String, List<String>>{};
  for (final e in decoded) {
    if (e is! Map) continue;
    final id = e['workId']?.toString();
    if (id == null) continue;
    final tokens =
        (e['searchTokens'] as List?)?.map((t) => t.toString()).toList() ?? [];
    out[id] = tokens;
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
