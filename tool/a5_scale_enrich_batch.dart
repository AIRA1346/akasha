// ignore_for_file: avoid_print
/// A5 Scale — 소규모 enrich 배치 (O6·O7 관측).
///
/// Usage:
///   dart run tool/a5_scale_enrich_batch.dart --batch 1 [--apply]
///
/// 산출: akasha-db/pipeline/artifacts/coverage_dashboard/scale_enrich_bN.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Sprint 03 단가 (maintainer-minutes / work)
const _minutesManual = 15.0;

void main(List<String> args) {
  final apply = args.contains('--apply');
  final batch = int.parse(_argValue(args, '--batch') ?? '1');
  final root = _root();
  final plans = _plansForBatch(batch);
  final shardsRoot = Directory(p.join(root.path, 'akasha-db', 'shards'));

  final insertFree = batch == 4;
  print(
    '=== Scale enrich batch $batch (${plans.length} works)${insertFree ? " [insert-free]" : ""} ===',
  );
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
    if (titles.containsKey(plan.axis) &&
        titles[plan.axis]?.toString().isNotEmpty == true) {
      print('SKIP $workId (${plan.axis} already set)');
      skipped++;
      continue;
    }

    titles[plan.axis] = plan.value;
    work['titles'] = titles;
    final ext = Map<String, dynamic>.from(
      (work['extensions'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    ext['coverageScaleEnrich'] = 'batch${batch}_${plan.axis}';
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
  final supplyAdded = 2;
  final cumulativeInsert = batch * 2;
  final cumulativeEnrich = switch (batch) {
    1 => 2,
    2 => 4,
    3 => 8,
    _ => enriched,
  };
  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'batch': batch,
    'axis': 'titles.ja',
    'enriched': enriched,
    'skipped': skipped,
    'wallMs': sw.elapsedMilliseconds,
    'estimatedMinutesTotal': enriched * _minutesManual,
    'insertBacklogContext': {
      'scaleSupplyBatchAdded': supplyAdded,
      'enrichBatchDone': enriched,
      'sessionInsertEnrichRatio': '$supplyAdded:$enriched',
      'cumulativeScaleInsertFrom410': cumulativeInsert,
      'cumulativeScaleEnrichJa': cumulativeEnrich,
      if (batch == 3) 'pilotJaBacklogBefore': 6,
      if (batch == 3) 'pilotJaBacklogAfter': 4,
    },
    'works': details,
  };

  final outDir = Directory(
    p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
  );
  outDir.createSync(recursive: true);
  final outFile = File(p.join(outDir.path, 'scale_enrich_b$batch.json'));
  if (apply) {
    outFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('\nWrote ${outFile.path}');
    print('Next: dart run tool/registry_builder.dart');
  } else {
    print('\nDry-run — pass --apply to write shards + report');
  }
  print(
    'Batch $batch: $enriched enriched, $skipped skipped, wall ${sw.elapsedMilliseconds}ms',
  );
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
      2 => const [
          _EnrichPlan(
            'sub_movie_scale-supply-b2a_2026',
            'ja',
            'スケール供給バッチ2A',
          ),
          _EnrichPlan(
            'sub_drama_scale-supply-b2b_2026',
            'ja',
            'スケール供給バッチ2B',
          ),
        ],
      3 => const [
          _EnrichPlan(
            'sub_book_scale-supply-b3a_2026',
            'ja',
            'スケール供給バッチ3A',
          ),
          _EnrichPlan(
            'sub_animation_scale-supply-b3b_2026',
            'ja',
            'スケール供給バッチ3B',
          ),
          _EnrichPlan(
            'sub_game_pilot-h1-supply-b1a_2026',
            'ja',
            'パイロットH1供給バッチ1A',
          ),
          _EnrichPlan(
            'sub_movie_pilot-h1-supply-b1b_2026',
            'ja',
            'パイロットH1供給バッチ1B',
          ),
        ],
      _ => throw ArgumentError('batch must be 1, 2, or 3'),
    };

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i < 0 || i + 1 >= args.length) return null;
  return args[i + 1];
}

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
