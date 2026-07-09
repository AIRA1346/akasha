// ignore_for_file: avoid_print
// Sprint 04 Phase B-4 ??E1 cohort post Quality Gate (E1?ìE5) reclassification.
//
// Usage: dart run tool/archive/coverage_sprint_04_e1_post_gate.dart [--write-json]
//
// Read-only ¬∑ no apply ¬∑ no registry mutation.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../coverage_quality.dart';

const _e4Threshold = 0.15;

void main(List<String> args) {
  final writeJson = args.contains('--write-json');
  final root = _root();
  final works = loadRegistryWorkMaps(root);
  final byId = {for (final w in works) w['workId']?.toString() ?? '': w};
  final steamIndex = _buildSteamIndex(works);

  final totalWorks = works.length;
  final currentExternal =
      works.where((w) => _externalIds(w).isNotEmpty).length;
  final g2Target = (totalWorks * 0.5).ceil();

  final items = <Map<String, dynamic>>[];
  for (final work in works) {
    if (_externalIds(work).isNotEmpty) continue;
    final steamId = _resolveSteamAppId(work);
    if (steamId == null) continue;
    if ((work['category']?.toString() ?? '') != 'game') continue;

    final titleKo = work['title']?.toString() ?? '';
    final titleEn = (work['titles'] as Map?)?['en']?.toString() ?? '';
    final titleEnTrim = titleEn.trim();

    final triggered = <String>[];
    final ruleDetails = <String, dynamic>{};

    // E1
    if (titleEnTrim == 'Site Error') {
      triggered.add('E1');
      ruleDetails['E1'] = 'titles.en == "Site Error"';
    }

    // E2
    if (titleEnTrim.startsWith('Save ')) {
      triggered.add('E2');
      ruleDetails['E2'] = 'titles.en startsWith "Save "';
    }

    // E3
    final dupOwners = (steamIndex[steamId] ?? [])
        .where((id) => id != work['workId']?.toString())
        .toList();
    if (dupOwners.isNotEmpty) {
      triggered.add('E3');
      ruleDetails['E3'] = {
        'existingWorkIds': dupOwners,
        'key': 'steam:$steamId',
      };
    }

    // E5 ??same predicate as E3 for attach-time cohort (virtual attach)
    if (dupOwners.isNotEmpty) {
      triggered.add('E5');
      ruleDetails['E5'] = {
        'duplicateAcrossWk': true,
        'owners': [...dupOwners, work['workId']?.toString()],
      };
    }

    // E4
    final sim = _titleTokenOverlap(titleKo, titleEn);
    final crossGame = _crossGameTitleMismatch(titleKo, titleEn);
    if (sim < _e4Threshold || crossGame) {
      triggered.add('E4');
      ruleDetails['E4'] = {
        'tokenOverlap': double.parse(sim.toStringAsFixed(4)),
        'threshold': _e4Threshold,
        'crossGameDictionary': crossGame,
      };
    }

    final hasBlock = triggered.any((r) => r != 'E4');
    final hasReview = triggered.contains('E4');
    final verdict = hasBlock
        ? 'BLOCK'
        : hasReview
        ? 'REVIEW'
        : 'AUTO_APPROVE';

    items.add({
      'workId': work['workId']?.toString() ?? '',
      'title': titleKo,
      'titlesEn': titleEn,
      'candidateSteamAppId': steamId,
      'triggeredRules': triggered,
      'ruleDetails': ruleDetails,
      'verdict': verdict,
      'phaseBSeverity': _phaseBSeverity(work, steamId, steamIndex, byId),
    });
  }

  items.sort((a, b) => (a['workId'] as String).compareTo(b['workId'] as String));

  final autoApprove =
      items.where((i) => i['verdict'] == 'AUTO_APPROVE').length;
  final review = items.where((i) => i['verdict'] == 'REVIEW').length;
  final block = items.where((i) => i['verdict'] == 'BLOCK').length;

  final covAuto = (currentExternal + autoApprove) / totalWorks;
  final covAutoReview = (currentExternal + autoApprove + review) / totalWorks;
  final extAfterAuto = currentExternal + autoApprove;
  final extAfterReview = currentExternal + autoApprove + review;

  final summary = {
    'cohortSize': items.length,
    'autoApprove': autoApprove,
    'review': review,
    'block': block,
    'registry': {
      'totalWorks': totalWorks,
      'currentExternalIdCount': currentExternal,
      'currentCoveragePct': _pct(currentExternal / totalWorks),
      'g2TargetCount': g2Target,
      'g2TargetPct': 50.0,
    },
    'projectedCoverage': {
      'autoApproveOnly': {
        'externalIdCount': extAfterAuto,
        'coveragePct': _pct(covAuto),
        'deltaFromBaseline': autoApprove,
        'meetsG2': extAfterAuto >= g2Target,
        'gapToG2': math.max(0, g2Target - extAfterAuto),
      },
      'autoApprovePlusReview': {
        'externalIdCount': extAfterReview,
        'coveragePct': _pct(covAutoReview),
        'deltaFromBaseline': autoApprove + review,
        'meetsG2': extAfterReview >= g2Target,
        'gapToG2': math.max(0, g2Target - extAfterReview),
      },
    },
  };

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'phase': 'Sprint 04 Phase B-4',
    'mode': 'post_gate_measurement',
    'rules': ['E1', 'E2', 'E3', 'E4', 'E5'],
    'e4Threshold': _e4Threshold,
    'summary': summary,
    'items': items,
  };

  print(jsonEncode(summary));

  if (writeJson) {
    final outDir = Directory(
      p.join(
        root.path,
        'akasha-db',
        'pipeline',
        'artifacts',
        'coverage_dashboard',
      ),
    )..createSync(recursive: true);
    final out = File(p.join(outDir.path, 'sprint_04_e1_post_gate.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  }
}

double _pct(double v) => double.parse((v * 100).toStringAsFixed(2));

String _phaseBSeverity(
  Map<String, dynamic> work,
  String steamId,
  Map<String, List<String>> steamIndex,
  Map<String, Map<String, dynamic>> byId,
) {
  final title = work['title']?.toString() ?? '';
  final titleEn =
      (work['titles'] as Map?)?['en']?.toString().toLowerCase() ?? '';
  final dup = (steamIndex[steamId] ?? [])
      .where((id) => id != work['workId']?.toString())
      .isNotEmpty;
  final stalePromo = RegExp(
    r'^save\s+\d+%\s+on\s+',
    caseSensitive: false,
  ).hasMatch(titleEn.trim());
  final crossGame = _crossGameTitleMismatch(title, titleEn);
  final siteError = titleEn.trim() == 'site error';

  if (dup || crossGame || siteError) return 'HIGH';
  if (stalePromo) return 'MEDIUM';
  return 'LOW';
}

bool _crossGameTitleMismatch(String titleKo, String titleEn) {
  final en = titleEn.toLowerCase();
  final ko = titleKo.toLowerCase();
  if (en.isEmpty) return false;
  const mismatches = [
    (ko: '?àÏ?', enNeedle: 'wukong'),
    (ko: 'Î∏îÎ£® ?ÑÏπ¥?¥Î∏å', enNeedle: 'songs of conquest'),
    (ko: '?åÏù¥???êÌ?ÏßÄ', enNeedle: 'site error'),
  ];
  for (final m in mismatches) {
    if (ko.contains(m.ko) && en.contains(m.enNeedle)) return true;
  }
  return false;
}

/// Token overlap: |A ??B| / max(|A|, |B|) on alphanumeric tokens (len ??2).
double _titleTokenOverlap(String titleKo, String titleEn) {
  final a = _tokens(titleKo);
  final b = _tokens(titleEn);
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final inter = a.intersection(b).length;
  return inter / math.max(a.length, b.length);
}

Set<String> _tokens(String raw) {
  return RegExp(r'[a-z0-9]{2,}', caseSensitive: false)
      .allMatches(raw.toLowerCase())
      .map((m) => m.group(0)!)
      .toSet();
}

Map<String, List<String>> _buildSteamIndex(List<Map<String, dynamic>> works) {
  final index = <String, List<String>>{};
  for (final work in works) {
    final wid = work['workId']?.toString() ?? '';
    final steam = _externalIds(work)['steam'];
    if (steam == null) continue;
    index.putIfAbsent(steam, () => []).add(wid);
  }
  return index;
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

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
