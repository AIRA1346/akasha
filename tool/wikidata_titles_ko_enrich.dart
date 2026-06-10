// ignore_for_file: avoid_print
/// Wikidata Q-id 작품 — `titles.ko` 백필 (label·alias·kowiki) + `title` 동기화.
///
/// Usage:
///   dart run tool/wikidata_titles_ko_enrich.dart              # dry-run
///   dart run tool/wikidata_titles_ko_enrich.dart --apply      # shard 갱신
///   dart run tool/wikidata_titles_ko_enrich.dart --apply --all

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'discovery/wikidata_entity_labels.dart';
import 'discovery/wikidata_ko_sparql.dart';
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
      if (!resyncAll && hasKo) continue;

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
  print('  targets (missing ko): ${targets.length}');
  if (targets.isEmpty) {
    print('Nothing to enrich.');
    return;
  }

  final qids = targets.map((t) => t.qid).toSet().toList();
  print('  fetching Wikidata facts for ${qids.length} Q-ids...');
  final factsByQid = await fetchWikidataEntityLocaleFacts(qids: qids);
  print('  fetching related kowiki (SPARQL 1-hop)...');
  final relatedKoByQid = await fetchRelatedKowikiTitles(qids: qids);

  var wouldUpdate = 0;
  var koByLabel = 0;
  var koByAlias = 0;
  var koByKowiki = 0;
  var koByRelated = 0;
  var koUnresolved = 0;
  var unchanged = 0;
  final report = <Map<String, dynamic>>[];

  for (final target in targets) {
    final facts = factsByQid[target.qid] ?? const WikidataEntityLocaleFacts();
    final mergedTitles = Map<String, String>.from(target.titles);

    var koSource = pickKoTitle(facts);
    if (koSource.ko == null) {
      final related = relatedKoByQid[target.qid];
      if (related != null && related.isNotEmpty) {
        koSource = (
          ko: disambiguateRelatedKoTitle(
            relatedKo: related,
            titles: mergedTitles,
          ),
          source: 'related',
        );
      }
    }

    if (koSource.ko == null) {
      koUnresolved++;
      unchanged++;
      report.add({
        'workId': target.workId,
        'qid': target.qid,
        'status': 'no_ko_source',
        'title': target.currentTitle,
      });
      continue;
    }

    mergedTitles['ko'] = koSource.ko!;
    switch (koSource.source) {
      case 'label':
        koByLabel++;
      case 'alias':
        koByAlias++;
      case 'kowiki':
        koByKowiki++;
      case 'related':
        koByRelated++;
    }

    final newTitle = resolveRegistryPrimaryTitle(
      titles: mergedTitles,
      legacyTitle: target.currentTitle,
    );

    if (mergedTitles['ko'] == target.titles['ko'] && newTitle == target.currentTitle) {
      unchanged++;
      report.add({
        'workId': target.workId,
        'qid': target.qid,
        'status': 'unchanged',
        'ko': koSource.ko,
      });
      continue;
    }

    wouldUpdate++;
    report.add({
      'workId': target.workId,
      'qid': target.qid,
      'status': 'update',
      'ko': mergedTitles['ko'],
      'koSource': koSource.source,
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
      'koByLabel': koByLabel,
      'koByAlias': koByAlias,
      'koByKowiki': koByKowiki,
      'koByRelated': koByRelated,
      'koUnresolved': koUnresolved,
      'unchanged': unchanged,
      'updated': wouldUpdate,
      'items': report,
    })}\n',
  );

  print('  ko by label: $koByLabel');
  print('  ko by alias: $koByAlias');
  print('  ko by kowiki: $koByKowiki');
  print('  ko by related: $koByRelated');
  print('  ko unresolved: $koUnresolved');
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
