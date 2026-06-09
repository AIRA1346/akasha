// ignore_for_file: avoid_print
/// A5 Pilot — Maintainer 소규모 공급 배치 (pre-insert gate + v4 shard).
///
/// Usage:
///   dart run tool/a5_pilot_supply_batch.dart --batch 1 [--apply]
///   dart run tool/a5_pilot_supply_batch.dart --batch all [--apply]

import 'dart:convert';
import 'dart:io';

import 'pre_insert_dedupe_gate.dart';
import 'registry_hash_utils.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final batchArg = _argValue(args, '--batch') ?? '1';
  final batches = batchArg == 'all' ? [1, 2, 3] : [int.parse(batchArg)];

  final root = _root();
  final gate = PreInsertDedupeGate.load(root);
  final shards = Directory('${root.path}/akasha-db/shards');

  for (final n in batches) {
    final seeds = _seedsForBatch(n);
    print('=== H1 supply batch $n (${seeds.length} seeds) ===');
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
}

List<Map<String, dynamic>> _seedsForBatch(int n) => switch (n) {
      1 => _batch1(),
      2 => _batch2(),
      3 => _batch3(),
      _ => throw ArgumentError('batch must be 1, 2, or 3'),
    };

List<Map<String, dynamic>> _batch1() => [
      _e(
        workId: 'sub_game_pilot-h1-supply-b1a_2026',
        titleKo: '파일럿 H1 공급 배치1A',
        titleEn: 'Pilot H1 Supply Batch 1A',
        category: 'game',
        year: 2026,
      ),
      _e(
        workId: 'sub_movie_pilot-h1-supply-b1b_2026',
        titleKo: '파일럿 H1 공급 배치1B',
        titleEn: 'Pilot H1 Supply Batch 1B',
        category: 'movie',
        year: 2026,
      ),
    ];

List<Map<String, dynamic>> _batch2() => [
      _e(
        workId: 'sub_drama_pilot-h1-supply-b2a_2026',
        titleKo: '파일럿 H1 공급 배치2A',
        titleEn: 'Pilot H1 Supply Batch 2A',
        category: 'drama',
        year: 2026,
      ),
      _e(
        workId: 'sub_book_pilot-h1-supply-b2b_2026',
        titleKo: '파일럿 H1 공급 배치2B',
        titleEn: 'Pilot H1 Supply Batch 2B',
        category: 'book',
        year: 2026,
      ),
    ];

List<Map<String, dynamic>> _batch3() => [
      _e(
        workId: 'sub_animation_pilot-h1-supply-b3a_2026',
        titleKo: '파일럿 H1 공급 배치3A',
        titleEn: 'Pilot H1 Supply Batch 3A',
        category: 'animation',
        year: 2026,
      ),
      _e(
        workId: 'sub_manga_pilot-h1-supply-b3b_2026',
        titleKo: '파일럿 H1 공급 배치3B',
        titleEn: 'Pilot H1 Supply Batch 3B',
        category: 'manga',
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
    'creator': 'A5 Pilot Maintainer',
    'releaseYear': year,
    'description': 'H1 supply path repeatability test — batch insert.',
    'tags': ['pilot', 'supply'],
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
