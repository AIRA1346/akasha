// ignore_for_file: avoid_print
/// A5 Scale ??O9 semantic enrich spot-check (syntactic gate Î∞?.
///
/// Usage: dart run tool/archive/a5_scale_semantic_spotcheck.dart [--apply]
///
/// ?∞Ï∂ú: akasha-db/pipeline/artifacts/coverage_dashboard/scale_semantic_o9.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../coverage_quality.dart';

/// SD4.2 cohort ??Scale¬∑Expansion enrich Í≤ΩÎ°ú 20Í±?
const _cohortWorkIds = [
  'sub_webtoon_scale-supply-b1a_2026',
  'sub_game_scale-supply-b1b_2026',
  'sub_movie_scale-supply-b2a_2026',
  'sub_drama_scale-supply-b2b_2026',
  'sub_book_scale-supply-b3a_2026',
  'sub_animation_scale-supply-b3b_2026',
  'sub_manga_scale-supply-b4a_2026',
  'sub_webtoon_scale-supply-b4b_2026',
  'sub_movie_scale-supply-b5a_2026',
  'sub_drama_scale-supply-b5b_2026',
  'sub_book_scale-supply-b6a_2026',
  'sub_game_scale-supply-b6b_2026',
  'sub_animation_scale-exp-b7-probe-alpha_2026',
  'sub_manga_scale-exp-b7-probe-beta_2026',
  'sub_game_scale-exp-b7-probe-gamma_2026',
  'sub_movie_scale-exp-b7-probe-delta_2026',
  'sub_drama_scale-exp-b7-probe-epsilon_2026',
  'sub_book_scale-exp-b7-probe-zeta_2026',
  'sub_webtoon_scale-exp-b7-probe-eta_2026',
  'sub_animation_scale-exp-b7-probe-theta_2026',
];

final _jaScript = RegExp(r'[\u3040-\u30ff\u4e00-\u9fff]');

enum SemanticJaIssue { empty, copyOfEn, noJaScript }

class SemanticJaFinding {
  const SemanticJaFinding({
    required this.workId,
    required this.issue,
    required this.ja,
    this.en,
    this.ko,
  });

  final String workId;
  final SemanticJaIssue issue;
  final String? ja;
  final String? en;
  final String? ko;
}

SemanticJaFinding? checkSemanticJa(Map<String, dynamic> work) {
  final workId = work['workId']?.toString() ?? '';
  final titles = work['titles'];
  if (titles is! Map) {
    return SemanticJaFinding(
      workId: workId,
      issue: SemanticJaIssue.empty,
      ja: null,
    );
  }
  final t = titles.cast<String, dynamic>();
  final ja = t['ja']?.toString().trim();
  final en = t['en']?.toString().trim();
  final ko = t['ko']?.toString().trim();

  if (ja == null || ja.isEmpty) {
    return SemanticJaFinding(workId: workId, issue: SemanticJaIssue.empty, ja: ja, en: en, ko: ko);
  }
  if (en != null && en.isNotEmpty && ja == en) {
    return SemanticJaFinding(workId: workId, issue: SemanticJaIssue.copyOfEn, ja: ja, en: en, ko: ko);
  }
  if (!_jaScript.hasMatch(ja)) {
    return SemanticJaFinding(workId: workId, issue: SemanticJaIssue.noJaScript, ja: ja, en: en, ko: ko);
  }
  return null;
}

void main(List<String> args) {
  final apply = args.contains('--apply') || args.contains('--report');
  final root = _root();
  final works = loadRegistryWorkMaps(root);
  final byId = {for (final w in works) w['workId']?.toString() ?? '': w};

  print('=== Scale O9 semantic spot-check (${_cohortWorkIds.length} works) ===\n');

  final findings = <SemanticJaFinding>[];
  var missing = 0;

  for (final workId in _cohortWorkIds) {
    final work = byId[workId];
    if (work == null) {
      print('MISSING $workId');
      missing++;
      continue;
    }
    final f = checkSemanticJa(work);
    if (f != null) {
      findings.add(f);
      print('FLAG ${f.workId} ??${f.issue.name}');
    } else {
      print('OK   $workId');
    }
  }

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'observation': 'O9',
    'sampleSize': _cohortWorkIds.length,
    'cohort': 'scale_supply_b1_6 + expansion_batch7',
    'missing': missing,
    'flagged': findings.length,
    'errorRate': _cohortWorkIds.isEmpty
        ? 0.0
        : findings.length / (_cohortWorkIds.length - missing),
    'status': findings.isEmpty && missing == 0 ? 'PASS' : 'REVIEW',
    'findings': findings
        .map(
          (f) => {
            'workId': f.workId,
            'issue': f.issue.name,
            if (f.ja != null) 'titlesJa': f.ja,
            if (f.en != null) 'titlesEn': f.en,
            if (f.ko != null) 'titlesKo': f.ko,
          },
        )
        .toList(),
    'note':
        'Heuristic only ??KPI PASS?Ä semantic ?†Î¢∞ Î∂ÑÎ¶¨ Ï∏°Ï†ï. ?∏Ï†Å spot-check??flagged=0???åÎèÑ SD4.2 Ï£ºÍ∏∞ ?†Ï?.',
  };

  print('\nFlagged: ${findings.length} / ${_cohortWorkIds.length - missing}');

  if (apply) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    );
    outDir.createSync(recursive: true);
    final out = File(p.join(outDir.path, 'scale_semantic_o9.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  } else {
    print('Dry-run ??pass --apply to write report');
  }
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
