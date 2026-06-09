// ignore_for_file: avoid_print
/// A5 Scale — 소규모 enrich 배치 (O6·O7 관측).
///
/// Usage:
///   dart run tool/a5_scale_enrich_batch.dart --batch 1 [--apply]
///
/// 산출: akasha-db/pipeline/artifacts/coverage_dashboard/scale_enrich_b1.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Sprint 03 단가 (maintainer-minutes / work)
const _minutesManual = 15.0;

void main(List<String> args) {
  final apply = args.contains('--apply');
  final root = _root();
  final plans = _plansForBatch(1);
  final shardsRoot = Directory(p.join(root.path, 'akasha-db', 'shards'));

  print('=== Scale enrich batch 1 (${plans.length} works) ===');
  final sw = Stopwatch()..start();
  var enriched = 0;
  var skipped = 0;
  final details = <Map<String, dynamic>>[];

  for (final plan in plans) {
    final workId = plan.workId;
    final located = _locateWork(shardsRoot, workId);
    if (located == null) {
      print('MISSING $workId');
      skipped++;
      continue;
    }

    final work = Map<String, dynamic>.from(located.work);
    final titles = Map<String, dynamic>.from(
      (work['titles'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    if (titles.containsKey(plan.axis) && titles[plan.axis]?.toString().isNotEmpty == true) {
      print('SKIP $workId (${plan.axis} already set)');
      skipped++;
      continue;
    }

    titles[plan.axis] = plan.value;
    work['titles'] = titles;
    final ext = Map<String, dynamic>.from(
      (work['extensions'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    ext['coverageScaleEnrich'] = 'batch1_${plan.axis}';
    work['extensions'] = ext;

    if (apply) {
      final shard = Map<String, dynamic>.from(located.shard);
      shard[workId] = work;
      located.file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    }
    print('${apply ? "ENRICH" : "WOULD_ENRICH"} $workId titles.${plan.axis}');
    enriched++;
    details.add({
      'workId': workId,
      'axis': plan.axis,
      'method': 'manual',
      'estimatedMinutes': _minutesManual,
    });
  }

  sw.stop();
  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'batch': 1,
    'axis': 'titles.ja',
    'enriched': enriched,
    'skipped': skipped,
    'wallMs': sw.elapsedMilliseconds,
    'estimatedMinutesTotal': enriched * _minutesManual,
    'insertBacklogContext': {
      'scaleSupplyBatch1Added': 2,
      'enrichBatch1Done': enriched,
      'note': 'O7 — insert:enrich 2:2 same session',
    },
    'works': details,
  };

  final outDir = Directory(
    p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
  );
  outDir.createSync(recursive: true);
  final outFile = File(p.join(outDir.path, 'scale_enrich_b1.json'));
  if (apply) {
    outFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('\nWrote ${outFile.path}');
    print('Next: dart run tool/registry_builder.dart');
  } else {
    print('\nDry-run — pass --apply to write shards + report');
  }
  print('Batch 1: $enriched enriched, $skipped skipped, wall ${sw.elapsedMilliseconds}ms');
}

class _EnrichPlan {
  const _EnrichPlan(this.workId, this.axis, this.value);
  final String workId;
  final String axis;
  final String value;
}

List<_EnrichPlan> _plansForBatch(int n) => switch (n) {
      1 => const [
          _EnrichPlan(
            'sub_webtoon_scale-supply-b1a_2026',
            'ja',
            'スケール供給バッチ1A',
          ),
          _EnrichPlan(
            'sub_game_scale-supply-b1b_2026',
            'ja',
            'スケール供給バッチ1B',
          ),
        ],
      _ => throw ArgumentError('batch must be 1'),
    };

class _Located {
  _Located(this.file, this.shard, this.work);
  final File file;
  final Map<String, dynamic> shard;
  final Map<String, dynamic> work;
}

_Located? _locateWork(Directory shardsRoot, String workId) {
  for (final cat in shardsRoot.listSync().whereType<Directory>()) {
    for (final f in cat.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final shard = json.decode(f.readAsStringSync());
      if (shard is! Map<String, dynamic>) continue;
      final w = shard[workId];
      if (w is Map) {
        return _Located(f, shard, Map<String, dynamic>.from(w));
      }
    }
  }
  return null;
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
