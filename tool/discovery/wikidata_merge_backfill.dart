// ignore_for_file: avoid_print
/// Wikidata Q-id backfill — 기존 Registry 작품에만 fuzzy 매칭 (shadow wk_ 배정 없음).
///
/// Usage:
///   dart run tool/discovery/wikidata_merge_backfill.dart --live --channel wikidata_manga
///   dart run tool/discovery/wikidata_merge_backfill.dart --live --apply --from-offset 0 --to-offset 500

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../dedupe_utils.dart';
import '../registry_hash_utils.dart';
import '../registry_v3_utils.dart';
import 'contract_test_runner.dart';
import 'discovery_manifest.dart';
import 'discovery_source_fetch.dart';
import 'registry_snapshot.dart';

void main(List<String> args) async {
  final live = args.contains('--live');
  final apply = args.contains('--apply');
  final channelId = _argValue(args, '--channel') ?? 'wikidata_manga';
  final fromOffset = int.tryParse(_argValue(args, '--from-offset') ?? '') ?? 0;
  final toOffset = int.tryParse(_argValue(args, '--to-offset') ?? '');
  final singleOffset = int.tryParse(_argValue(args, '--offset') ?? '');

  if (!live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/wikidata_merge_backfill.dart --live '
      '[--channel wikidata_manga] [--apply] '
      '[--offset N | --from-offset N --to-offset N]',
    );
    exit(64);
  }

  final root = _findProjectRoot();
  final dbRoot = Directory(p.join(root.path, 'akasha-db'));
  final manifest = DiscoveryManifest.load(root);
  final config = manifest.channel(channelId);
  if (config == null) {
    stderr.writeln('ERROR: unknown channel $channelId');
    exit(1);
  }

  final endOffset = toOffset ?? singleOffset ?? fromOffset;
  final startOffset = singleOffset ?? fromOffset;
  if (endOffset < startOffset) {
    stderr.writeln('ERROR: to-offset must be >= from-offset');
    exit(1);
  }

  print('wikidata_merge_backfill — $channelId');
  print('  apply: $apply');
  print('  offset range: $startOffset .. $endOffset (step ${config.trialBatchSize})');
  print('');

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  var candidates = 0;
  var merged = 0;
  var skipped = 0;
  var noMatch = 0;
  final linkedWorks = <String>{};
  final linkedQids = <String>{};

  for (var offset = startOffset;
      offset <= endOffset;
      offset += config.trialBatchSize) {
    print('fetch offset $offset...');
    final nodes = await fetchDiscoveryBatch(
      config: config,
      projectRoot: root,
      offset: offset,
    );

    final snap = RegistrySnapshot.load(root);

    for (final node in nodes) {
      final record = contractRunner.classifyNode(node);
      if (record.outcome != ContractNodeOutcome.minimalCoreDraft) continue;
      final draft = record.draft;
      if (draft == null) continue;

      final qid = record.externalId.trim();
      if (qid.isEmpty || linkedQids.contains(qid)) continue;

      final targetId = _findRegistryTitleMatch(draft, snap);
      if (targetId == null) {
        noMatch++;
        continue;
      }
      if (linkedWorks.contains(targetId)) {
        skipped++;
        continue;
      }

      final existing = snap.byWorkId[targetId];
      if (existing == null) {
        skipped++;
        continue;
      }

      final currentQ = existing.externalIds['wikidata']?.trim() ?? '';
      if (currentQ.isNotEmpty) {
        if (currentQ == qid) skipped++;
        else {
          stderr.writeln(
            'WARN: $targetId already wikidata:$currentQ — skip $qid (${record.title})',
          );
          skipped++;
        }
        continue;
      }

      candidates++;
      print(
        'LINK ${record.title} wikidata:$qid → $targetId '
        '(offset $offset)',
      );

      if (apply) {
        final ok = _applyMerge(
          dbRoot: dbRoot,
          targetId: targetId,
          qid: qid,
          category: existing.category,
          channelId: channelId,
          source: config.source,
        );
        if (ok) {
          merged++;
          linkedWorks.add(targetId);
          linkedQids.add(qid);
        } else {
          skipped++;
        }
      } else {
        linkedWorks.add(targetId);
        linkedQids.add(qid);
      }
    }
  }

  print('');
  print('Summary:');
  print('  link candidates: $candidates');
  print('  merged: $merged');
  print('  skipped: $skipped');
  print('  no registry match: $noMatch');
  if (!apply && candidates > 0) {
    print('\nDry-run. Pass --apply to write shards.');
  }
}

String? _findRegistryTitleMatch(
  Map<String, dynamic> draft,
  RegistrySnapshot registry,
) {
  final category = draft['category']?.toString() ?? '';
  final year = draft['releaseYear'] is int
      ? draft['releaseYear'] as int
      : int.tryParse(draft['releaseYear']?.toString() ?? '');

  for (final norm in _normalizedTitlesFromDraft(draft)) {
    if (norm.length < 2) continue;
    final key = '$category::$norm';
    final hits = registry.byTitleKey[key] ?? const [];
    for (final hit in hits) {
      if (!releaseYearsCompatible(year, hit.releaseYear)) continue;
      return hit.workId;
    }
  }
  return null;
}

Set<String> _normalizedTitlesFromDraft(Map<String, dynamic> draft) {
  final norms = <String>{};
  void add(String? t) {
    if (t == null || t.isEmpty) return;
    final n = normalizeTitle(t);
    if (n.isNotEmpty) norms.add(n);
  }

  add(draft['title']?.toString());
  final titles = draft['titles'];
  if (titles is Map) {
    titles.forEach((_, v) => add(v?.toString()));
  }
  final aliases = draft['aliases'];
  if (aliases is List) {
    for (final a in aliases) {
      add(a?.toString());
    }
  }
  return norms;
}

bool _applyMerge({
  required Directory dbRoot,
  required String targetId,
  required String qid,
  required String category,
  required String channelId,
  required String source,
}) {
  final hex = shardHexForWorkId(targetId);
  final relPath = v4ShardPath(category, hex);
  final shardFile = File(p.join(dbRoot.path, relPath));
  if (!shardFile.existsSync()) {
    stderr.writeln('WARN: shard missing for $targetId — skip');
    return false;
  }

  final shardMap = Map<String, dynamic>.from(
    json.decode(shardFile.readAsStringSync()) as Map,
  );
  final workRaw = shardMap[targetId];
  if (workRaw is! Map) {
    stderr.writeln('WARN: entry missing for $targetId — skip');
    return false;
  }

  final work = Map<String, dynamic>.from(workRaw);
  final extMap = Map<String, dynamic>.from(
    work['externalIds'] as Map? ?? {},
  );
  extMap['wikidata'] = qid;
  work['externalIds'] = extMap;

  final extensions = Map<String, dynamic>.from(
    work['extensions'] as Map? ?? {},
  );
  extensions['ingestChannel'] = channelId;
  extensions['ingestSource'] = source;
  work['extensions'] = extensions;

  final signals = Map<String, dynamic>.from(
    work['qualitySignals'] as Map? ?? {},
  );
  signals['externalIdVerified'] = true;
  work['qualitySignals'] = signals;

  shardMap[targetId] = work;
  shardFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
  );
  return true;
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
  return null;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
