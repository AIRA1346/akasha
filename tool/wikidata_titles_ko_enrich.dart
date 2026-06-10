// ignore_for_file: avoid_print
/// Wikidata Q-id 작품 — `titles.ko`·`ja` 백필 + `title` ko-primary 동기화.
///
/// Usage:
///   dart run tool/wikidata_titles_ko_enrich.dart              # dry-run
///   dart run tool/wikidata_titles_ko_enrich.dart --apply      # shard 갱신
///   dart run tool/wikidata_titles_ko_enrich.dart --apply --all  # 라벨 재동기화

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'discovery/wikidata_entity_labels.dart';
import 'registry_v3_utils.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final resyncAll = args.contains('--all');

  final root = _findProjectRoot();
  final dbRoot = p.join(root.path, 'akasha-db');
  final manifestPath = p.join(dbRoot, 'manifest.json');
  final manifest = jsonDecode(File(manifestPath).readAsStringSync()) as Map;

  final targets = <_LocaleEnrichTarget>[];
  for (final shardMeta in manifest['shards'] as List) {
    final rel = (shardMeta as Map)['path'] as String;
    final shardPath = p.join(dbRoot, rel);
    final shard = jsonDecode(File(shardPath).readAsStringSync()) as Map;
    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      final qid = _wikidataQid(work);
      if (qid == null) continue;

      final titles = parseTitlesJson(work['titles']);
      final hasKo = titles['ko']?.trim().isNotEmpty ?? false;
      final hasJa = titles['ja']?.trim().isNotEmpty ?? false;
      if (!resyncAll && hasKo && hasJa) continue;

      targets.add(
        _LocaleEnrichTarget(
          workId: workId,
          shardRel: rel,
          qid: qid,
          currentTitle: work['title']?.toString() ?? '',
          titles: titles,
        ),
      );
    }
  }

  print('wikidata_titles_ko_enrich');
  print('  targets: ${targets.length}');
  if (targets.isEmpty) {
    print('Nothing to enrich.');
    return;
  }

  final qids = targets.map((t) => t.qid).toSet().toList();
  print('  fetching labels for ${qids.length} Q-ids...');
  final labelsByQid = await fetchWikidataEntityLabels(qids: qids);

  var wouldUpdate = 0;
  var koFound = 0;
  var jaFound = 0;
  var unchanged = 0;
  final report = <Map<String, dynamic>>[];

  for (final target in targets) {
    final labels = labelsByQid[target.qid] ?? const {};
    final mergedTitles = Map<String, String>.from(target.titles);

    if (labels['ko']?.isNotEmpty == true) {
      mergedTitles['ko'] = labels['ko']!.trim();
      koFound++;
    }
    if (labels['ja']?.isNotEmpty == true) {
      mergedTitles['ja'] = labels['ja']!.trim();
      jaFound++;
    }
    if (labels['en']?.isNotEmpty == true &&
        (mergedTitles['en']?.isEmpty ?? true)) {
      mergedTitles['en'] = labels['en']!.trim();
    }

    final newTitle = resolveRegistryPrimaryTitle(
      titles: mergedTitles,
      legacyTitle: target.currentTitle,
    );

    final changed = !_titlesEqual(mergedTitles, target.titles) ||
        newTitle != target.currentTitle;

    if (!changed) {
      unchanged++;
      report.add({
        'workId': target.workId,
        'qid': target.qid,
        'status': 'unchanged',
        'title': target.currentTitle,
      });
      continue;
    }

    wouldUpdate++;
    report.add({
      'workId': target.workId,
      'qid': target.qid,
      'status': 'update',
      'ko': mergedTitles['ko'],
      'ja': mergedTitles['ja'],
      'titleBefore': target.currentTitle,
      'titleAfter': newTitle,
    });

    if (apply) {
      _writeLocaleTitles(
        root: root,
        shardRel: target.shardRel,
        workId: target.workId,
        titles: mergedTitles,
        title: newTitle,
      );
    }
  }

  final outDir = Directory(
    p.join(dbRoot, 'pipeline', 'artifacts', 'wikidata_ko_enrich'),
  );
  outDir.createSync(recursive: true);
  final reportFile = File(
    p.join(outDir.path, 'report_${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}'),
  );
  reportFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'apply': apply,
      'targets': targets.length,
      'koLabelsFetched': koFound,
      'jaLabelsFetched': jaFound,
      'unchanged': unchanged,
      'updated': wouldUpdate,
      'items': report,
    })}\n',
  );

  print('  ko labels in API response: $koFound');
  print('  ja labels in API response: $jaFound');
  print('  unchanged: $unchanged');
  print('  would update: $wouldUpdate');
  print('  report: ${reportFile.path}');

  if (!apply) {
    print('\nDry-run. Pass --apply to write shards.');
  }
}

bool _titlesEqual(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

String? _wikidataQid(Map<String, dynamic> work) {
  final ext = work['externalIds'];
  if (ext is! Map) return null;
  final qid = ext['wikidata']?.toString().trim() ?? '';
  if (qid.isEmpty || !qid.startsWith('Q')) return null;
  return qid;
}

void _writeLocaleTitles({
  required Directory root,
  required String shardRel,
  required String workId,
  required Map<String, String> titles,
  required String title,
}) {
  final file = File(p.join(root.path, 'akasha-db', shardRel));
  final shard = Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
  final work = Map<String, dynamic>.from(shard[workId] as Map);
  work['titles'] = Map<String, String>.from(titles);
  work['title'] = title;
  shard[workId] = work;
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(shard)}\n');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('project root not found');
    }
    dir = parent;
  }
}

class _LocaleEnrichTarget {
  final String workId;
  final String shardRel;
  final String qid;
  final String currentTitle;
  final Map<String, String> titles;

  const _LocaleEnrichTarget({
    required this.workId,
    required this.shardRel,
    required this.qid,
    required this.currentTitle,
    required this.titles,
  });
}
