// ignore_for_file: avoid_print
// Batch 7: Scale A-type Net-new Expansion cohort (gate + v4 hex).
// Policy: [docs/programs/a5-scale-expansion-cohort-plan.md](../docs/programs/a5-scale-expansion-cohort-plan.md)
//
// Usage:
//   dart run tool/archive/seed_expansion_batch7.dart              # dry-run
//   dart run tool/archive/seed_expansion_batch7.dart --apply      # default --max-add 2
//   dart run tool/archive/seed_expansion_batch7.dart --apply --max-add 4

import 'dart:convert';
import 'dart:io';

import '../pre_insert_dedupe_gate.dart';
import '../registry_hash_utils.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final existingIds = _collectExistingWorkIds(shardsRoot);
  final dedupeGate = PreInsertDedupeGate.load(projectRoot);
  final maxAdd = int.tryParse(_argValue(args, '--max-add') ?? '') ?? 2;

  var added = 0;
  var skipped = 0;
  var blocked = 0;

  for (final seed in _batch7Seeds()) {
    if (added >= maxAdd) break;

    final workId = seed['workId'] as String;
    if (existingIds.contains(workId)) {
      skipped++;
      continue;
    }

    final conflicts = dedupeGate.check(seed);
    if (conflicts.isNotEmpty) {
      print('BLOCK $workId: ${conflicts.first}');
      blocked++;
      continue;
    }

    final category = seed['category'] as String;
    final hex = shardHexForWorkId(workId);
    final shardPath = '${shardsRoot.path}/$category/$hex.json';
    final shardFile = File(shardPath);

    Map<String, dynamic> shardMap = {};
    if (shardFile.existsSync()) {
      final decoded = json.decode(shardFile.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        shardMap = Map<String, dynamic>.from(decoded);
      }
    }

    shardMap[workId] = Map<String, dynamic>.from(seed);
    existingIds.add(workId);

    if (apply) {
      shardFile.parent.createSync(recursive: true);
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
      );
    }
    print('${apply ? "ADD" : "WOULD_ADD"} $workId -> $category/$hex.json');
    added++;
  }

  print('Done: $added ${apply ? "added" : "would add"}, $skipped skipped, $blocked blocked');
  if (!apply) print('Dry-run. Pass --apply to write shards (default --max-add 2).');
}

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i < 0 || i + 1 >= args.length) return null;
  return args[i + 1];
}

Set<String> _collectExistingWorkIds(Directory shardsRoot) {
  final ids = <String>{};
  if (!shardsRoot.existsSync()) return ids;
  for (final entity in shardsRoot.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final decoded = json.decode(entity.readAsStringSync());
    if (decoded is Map<String, dynamic>) ids.addAll(decoded.keys);
  }
  return ids;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}

Map<String, dynamic> _entry({
  required String workId,
  required String titleKo,
  required String titleEn,
  required String titleJa,
  required String category,
  required int year,
}) {
  return {
    'workId': workId,
    'title': titleKo,
    'titles': {'ko': titleKo, 'en': titleEn, 'ja': titleJa},
    'category': category,
    'domain': 'subculture',
    'creator': 'A5 Scale Expansion',
    'releaseYear': year,
    'description':
        'Scale A-type Expansion probe ??Net-new cohort for gate validation.',
    'tags': ['scale', 'expansion', 'batch7'],
  };
}

/// Net-new workIds ??not registered as legacyIds on any wk_.
List<Map<String, dynamic>> _batch7Seeds() => [
      _entry(
        workId: 'sub_animation_scale-exp-b7-probe-alpha_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏??åÌåå',
        titleEn: 'Scale Expansion Probe Alpha',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?¢„É´?ï„Ç°',
        category: 'animation',
        year: 2026,
      ),
      _entry(
        workId: 'sub_manga_scale-exp-b7-probe-beta_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏?Î≤†Ì?',
        titleEn: 'Scale Expansion Probe Beta',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?ô„Éº??,
        category: 'manga',
        year: 2026,
      ),
      _entry(
        workId: 'sub_game_scale-exp-b7-probe-gamma_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏?Í∞êÎßà',
        titleEn: 'Scale Expansion Probe Gamma',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?¨„É≥??,
        category: 'game',
        year: 2026,
      ),
      _entry(
        workId: 'sub_movie_scale-exp-b7-probe-delta_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏??∏Ì?',
        titleEn: 'Scale Expansion Probe Delta',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?á„É´??,
        category: 'movie',
        year: 2026,
      ),
      _entry(
        workId: 'sub_drama_scale-exp-b7-probe-epsilon_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏??°Ïã§Î°?,
        titleEn: 'Scale Expansion Probe Epsilon',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?§„Éó?∑„É≠??,
        category: 'drama',
        year: 2026,
      ),
      _entry(
        workId: 'sub_book_scale-exp-b7-probe-zeta_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏??úÌ?',
        titleEn: 'Scale Expansion Probe Zeta',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?º„Éº??,
        category: 'book',
        year: 2026,
      ),
      _entry(
        workId: 'sub_webtoon_scale-exp-b7-probe-eta_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏??êÌ?',
        titleEn: 'Scale Expansion Probe Eta',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?§„Éº??,
        category: 'webtoon',
        year: 2026,
      ),
      _entry(
        workId: 'sub_animation_scale-exp-b7-probe-theta_2026',
        titleKo: '?§Ï????ïÏû• ?ÑÎ°úÎ∏??∏Ì?',
        titleEn: 'Scale Expansion Probe Theta',
        titleJa: '?π„Ç±?º„É´?°Âºµ?ó„É≠?º„Éñ?∑„Éº??,
        category: 'animation',
        year: 2026,
      ),
    ];
