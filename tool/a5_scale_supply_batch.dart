// ignore_for_file: avoid_print
/// A5 Scale — Maintainer Net-new 소규모 공급 (pre-insert gate + v4 shard).
///
/// Usage:
///   dart run tool/a5_scale_supply_batch.dart --batch 1 [--apply]

import 'dart:convert';
import 'dart:io';

import 'pre_insert_dedupe_gate.dart';
import 'registry_hash_utils.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final batchArg = _argValue(args, '--batch') ?? '1';
  final n = int.parse(batchArg);

  final root = _root();
  final gate = PreInsertDedupeGate.load(root);
  final shards = Directory('${root.path}/akasha-db/shards');
  final seeds = _seedsForBatch(n);

  print('=== Scale supply batch $n (${seeds.length} seeds) ===');
  var added = 0;
  var blocked = 0;

  for (final seed in seeds) {
    final workId = seed['workId'] as String;
    final conflicts = gate.check(seed);
    if (conflicts.isNotEmpty) {
      print('BLOCK $workId: ${conflicts.first}');
      blocked++;
      continue;
    }

    final cat = seed['category'] as String;
    final hex = shardHexForWorkId(workId);
    final file = File('${shards.path}/$cat/$hex.json');
    Map<String, dynamic> shard = {};
    if (file.existsSync()) {
      shard = Map<String, dynamic>.from(
        json.decode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    }
    if (shard.containsKey(workId)) {
      print('SKIP $workId');
      continue;
    }

    if (apply) {
      shard[workId] = seed;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    }
    print('${apply ? "ADD" : "WOULD_ADD"} $workId -> $cat/$hex.json');
    added++;
  }
  print('Batch $n: $added ${apply ? "added" : "would add"}, $blocked blocked');
  if (!apply) print('Dry-run — pass --apply to write');
}

List<Map<String, dynamic>> _seedsForBatch(int n) => switch (n) {
      1 => _batch1(),
      _ => throw ArgumentError('batch must be 1'),
    };

List<Map<String, dynamic>> _batch1() => [
      _e(
        workId: 'sub_webtoon_scale-supply-b1a_2026',
        titleKo: '스케일 공급 배치1A',
        titleEn: 'Scale Supply Batch 1A',
        category: 'webtoon',
        year: 2026,
      ),
      _e(
        workId: 'sub_game_scale-supply-b1b_2026',
        titleKo: '스케일 공급 배치1B',
        titleEn: 'Scale Supply Batch 1B',
        category: 'game',
        year: 2026,
      ),
    ];

Map<String, dynamic> _e({
  required String workId,
  required String titleKo,
  required String titleEn,
  required String category,
  required int year,
}) {
  return {
    'workId': workId,
    'title': titleKo,
    'titles': {'ko': titleKo, 'en': titleEn},
    'category': category,
    'domain': 'subculture',
    'creator': 'A5 Scale Maintainer',
    'releaseYear': year,
    'description': 'Scale Net-new insert — Maintainer anchor (Expansion cohort B-type).',
    'tags': ['scale', 'supply'],
  };
}

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i < 0 || i + 1 >= args.length) return null;
  return args[i + 1];
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
