// ignore_for_file: avoid_print
/// Trial Apply — Shadow Write wouldCreate·mergeCandidate → shard·id_registry·cursor.
///
/// Usage:
///   dart run tool/discovery/trial_apply.dart --live --channel wikidata_manga
///   dart run tool/discovery/trial_apply.dart --live --channel wikidata_manga --apply
///   dart run tool/discovery/trial_apply.dart --live --channel wikidata_manga --apply --skip-merge
///   dart run tool/discovery/trial_apply.dart --live --channel wikidata_manga --apply --max-create 20

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data_policy_utils.dart';
import '../dedupe_utils.dart';
import '../registry_hash_utils.dart';
import '../registry_v3_utils.dart';
import '../wk_id_utils.dart';
import 'contract_test_runner.dart';
import 'discovery_fixtures.dart';
import 'discovery_manifest.dart';
import 'discovery_source_fetch.dart';
import 'discovery_types.dart';
import 'registry_snapshot.dart';
import 'shadow_write_runner.dart';

void main(List<String> args) async {
  final offline = args.contains('--offline');
  final live = args.contains('--live');
  final apply = args.contains('--apply');
  final skipMerge = args.contains('--skip-merge');
  final mergeOnly = args.contains('--merge-only');
  final channelId = _argValue(args, '--channel') ?? 'wikidata_manga';
  final maxCreate = int.tryParse(_argValue(args, '--max-create') ?? '');
  final fetchOffset = int.tryParse(_argValue(args, '--offset') ?? '');
  final batchSizeOverride = int.tryParse(_argValue(args, '--batch-size') ?? '');

  if (!offline && !live) {
    stderr.writeln(
      'Usage: dart run tool/discovery/trial_apply.dart --offline | --live '
      '[--channel wikidata_manga] [--apply] [--skip-merge] [--merge-only] '
      '[--max-create N] [--offset N] [--batch-size N]',
    );
    exit(64);
  }

  final root = _findProjectRoot();
  final dbRoot = Directory(p.join(root.path, 'akasha-db'));
  final manifest = DiscoveryManifest.load(root);
  final configRaw = manifest.channel(channelId);
  if (configRaw == null) {
    stderr.writeln('ERROR: unknown channel $channelId');
    exit(1);
  }
  final config = batchSizeOverride != null
      ? DiscoveryChannelConfig(
          id: configRaw.id,
          source: configRaw.source,
          category: configRaw.category,
          domain: configRaw.domain,
          enabled: configRaw.enabled,
          dailyLimit: configRaw.dailyLimit,
          trialBatchSize: batchSizeOverride,
          cursorPath: configRaw.cursorPath,
        )
      : configRaw;

  print('trial_apply — $channelId');
  print('  mode: ${offline ? 'offline' : 'live'}');
  print('  apply: $apply');
  print('  merge patches: ${apply && !skipMerge}');
  print('  merge-only: $mergeOnly');
  if (maxCreate != null) print('  max-create: $maxCreate');
  if (fetchOffset != null) print('  offset: $fetchOffset');
  print('');

  final contractRunner = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  final List<Map<String, dynamic>> nodes;
  if (offline) {
    nodes = contractFixturesForChannel(config, config.trialBatchSize);
  } else {
    print(
      'fetching ${config.source} (${config.trialBatchSize} ${config.category} nodes)...',
    );
    nodes = await fetchDiscoveryBatch(
      config: config,
      projectRoot: root,
      offset: fetchOffset,
    );
  }

  final inputs = shadowInputsFromNodes(contractRunner, nodes);
  final shadowRunner = ShadowWriteRunner.fromProject(root);
  final result = shadowRunner.run(inputs);

  final creates = result.items
      .where((i) => i.outcome == ShadowWriteOutcome.wouldCreate)
      .toList();
  final merges = result.items
      .where((i) => i.outcome == ShadowWriteOutcome.mergeCandidate)
      .toList();

  print('Shadow KPI: wouldCreate=${result.kpi.wouldCreate} '
      'mergeCandidates=${result.kpi.mergeCandidates} '
      'wouldReject=${result.kpi.wouldReject}');

  if (!apply) {
    print('\nDry-run. Pass --apply to write shards, id_registry, cursor.');
    return;
  }

  if (!result.kpi.mirroringIntegrityPassed) {
    stderr.writeln('ABORT: mirroringIntegrityPassed=false');
    exit(1);
  }
  if (result.kpi.wouldReject > 0) {
    stderr.writeln('ABORT: wouldReject=${result.kpi.wouldReject}');
    exit(1);
  }

  var createLimit = creates.length;
  if (maxCreate != null && maxCreate < createLimit) {
    createLimit = maxCreate;
  }

  final preApplySnap = RegistrySnapshot.load(root);
  final createdWks = <String>{};
  final createdWikidataIds = <String>{};
  var created = 0;
  var merged = 0;
  var skippedMerge = 0;
  var skippedDuplicateQid = 0;
  int? highestSeq;
  final createdRegistryEntries = <Map<String, dynamic>>[];

  if (!mergeOnly) {
  for (var i = 0; i < createLimit; i++) {
    final item = creates[i];
    final draft = Map<String, dynamic>.from(item.draft ?? {});
    final wk = item.shadowWorkId ?? draft['workId']?.toString() ?? '';
    if (!isWkId(wk)) {
      stderr.writeln('ABORT: invalid workId for create ${item.externalId}');
      exit(1);
    }

    final qid = _externalIdsFromDraft(draft)['wikidata'];
    if (qid != null && qid.isNotEmpty) {
      final extKey = 'wikidata:$qid';
      if (preApplySnap.byExternalKey.containsKey(extKey) ||
          createdWikidataIds.contains(qid)) {
        print('SKIP duplicate wikidata:$qid (${item.title})');
        skippedDuplicateQid++;
        continue;
      }
      createdWikidataIds.add(qid);
    }

    _enrichProvenance(draft, channelId, config.source);
    final category = draft['category']?.toString() ?? config.category;
    final hex = shardHexForWorkId(wk);
    final relPath = v4ShardPath(category, hex);
    final shardFile = File(p.join(dbRoot.path, relPath));

    final issues = lintWorkEntry(
      workId: wk,
      work: draft,
      relativePath: relPath,
    );
    if (issues.isNotEmpty) {
      stderr.writeln('ABORT: policy ${item.externalId}: ${issues.first.rule}');
      exit(1);
    }

    Map<String, dynamic> shardMap = {};
    if (shardFile.existsSync()) {
      final decoded = json.decode(shardFile.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        shardMap = Map<String, dynamic>.from(decoded);
      }
    }
    if (shardMap.containsKey(wk)) {
      stderr.writeln('ABORT: duplicate workId $wk in $relPath');
      exit(1);
    }

    shardMap[wk] = draft;
    shardFile.parent.createSync(recursive: true);
    shardFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
    );
    print('CREATE $wk ${config.source}:${item.externalId} -> $relPath');
    created++;
    createdWks.add(wk);
    createdRegistryEntries.add({'workId': wk, 'category': category});

    final seq = parseWkSequence(wk);
    if (seq != null && (highestSeq == null || seq > highestSeq!)) {
      highestSeq = seq;
    }
  }
  }

  if (!skipMerge) {
    for (final item in merges) {
      final draft = item.draft;
      if (draft == null) continue;

      var targetId = item.matchedWorkId;
      if (targetId == null ||
          (!preApplySnap.byWorkId.containsKey(targetId) &&
              !createdWks.contains(targetId))) {
        targetId = _resolveMergeTargetFromRegistry(preApplySnap, draft);
      }
      if (targetId == null) {
        stderr.writeln(
          'WARN: merge target missing ${item.matchedWorkId ?? "?"} — skip',
        );
        skippedMerge++;
        continue;
      }

      final inPreRegistry = preApplySnap.byWorkId.containsKey(targetId);
      final inBatch = createdWks.contains(targetId);
      if (!inPreRegistry && !inBatch) {
        stderr.writeln('WARN: merge target missing $targetId — skip');
        skippedMerge++;
        continue;
      }

      final existing = inPreRegistry
          ? preApplySnap.byWorkId[targetId]!
          : null;

      final newExt = _externalIdsFromDraft(draft);
      final qid = newExt['wikidata'];
      if (qid == null || qid.isEmpty) {
        skippedMerge++;
        continue;
      }

      final currentExt = existing != null
          ? Map<String, String>.from(existing.externalIds)
          : _readExternalIdsFromShard(dbRoot, targetId);
      final currentQ = currentExt['wikidata'];
      if (currentQ != null && currentQ.isNotEmpty) {
        if (currentQ == qid) {
          skippedMerge++;
          continue;
        }
        stderr.writeln(
          'WARN: $targetId already has wikidata:$currentQ — skip ${item.externalId}',
        );
        skippedMerge++;
        continue;
      }

      final category = existing?.category ??
          draft['category']?.toString() ??
          config.category;
      final hex = shardHexForWorkId(targetId);
      final relPath = v4ShardPath(category, hex);
      final shardFile = File(p.join(dbRoot.path, relPath));
      if (!shardFile.existsSync()) {
        stderr.writeln('WARN: shard missing for $targetId — skip');
        skippedMerge++;
        continue;
      }

      final shardMap = Map<String, dynamic>.from(
        json.decode(shardFile.readAsStringSync()) as Map,
      );
      final workRaw = shardMap[targetId];
      if (workRaw is! Map) {
        stderr.writeln('WARN: entry missing for $targetId — skip');
        skippedMerge++;
        continue;
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
      extensions['ingestSource'] = config.source;
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
      print('MERGE $targetId += wikidata:$qid (${item.title})');
      merged++;
    }
  }

  if (!mergeOnly && created > 0 && highestSeq != null) {
    _patchIdRegistry(
      File(p.join(dbRoot.path, 'id_registry.json')),
      createdRegistryEntries,
      highestSeq! + 1,
    );
    print('id_registry nextWorkId -> ${highestSeq! + 1}');
  }

  if (!mergeOnly && fetchOffset == null) {
    final cursor = readCursor(root, config.cursorPath);
    final oldOffset = int.tryParse(cursor['offset']?.toString() ?? '') ?? 0;
    final newOffset = oldOffset + nodes.length;
    final lastQid = nodes.isNotEmpty ? nodes.last['qid']?.toString() : null;
    writeCursor(root, config.cursorPath, {
      ...cursor,
      'channelId': channelId,
      'source': config.source,
      'offset': newOffset,
      if (lastQid != null && lastQid.isNotEmpty) 'lastQid': lastQid,
    });
    print('cursor offset $oldOffset -> $newOffset');
  }

  print('\nDone: $created created, $merged merged, $skippedMerge merge skipped'
      '${skippedDuplicateQid > 0 ? ', $skippedDuplicateQid duplicate qid skipped' : ''}');
}

void _enrichProvenance(
  Map<String, dynamic> draft,
  String channelId,
  String source,
) {
  final extensions = Map<String, dynamic>.from(
    draft['extensions'] as Map? ?? {},
  );
  extensions['ingestChannel'] = channelId;
  extensions['ingestSource'] = source;
  draft['extensions'] = extensions;
}

Map<String, String> _readExternalIdsFromShard(Directory dbRoot, String workId) {
  final shardsRoot = Directory(p.join(dbRoot.path, 'shards'));
  for (final file in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is! Map) continue;
    final work = decoded[workId];
    if (work is! Map) continue;
    final ext = work['externalIds'];
    if (ext is! Map) return {};
    return ext.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
  return {};
}

Map<String, String> _externalIdsFromDraft(Map<String, dynamic> draft) {
  final ext = draft['externalIds'];
  if (ext is! Map) return {};
  return ext.map((k, v) => MapEntry(k.toString(), v.toString()));
}

/// shadow pending wk 대신 레지스트리 제목 매칭으로 merge 대상 복구
String? _resolveMergeTargetFromRegistry(
  RegistrySnapshot snap,
  Map<String, dynamic> draft,
) {
  final category = draft['category']?.toString() ?? '';
  final year = draft['releaseYear'] is int
      ? draft['releaseYear'] as int
      : int.tryParse(draft['releaseYear']?.toString() ?? '');

  for (final norm in _normalizedTitlesFromDraft(draft)) {
    if (norm.length < 2) continue;
    final key = '$category::$norm';
    for (final hit in snap.byTitleKey[key] ?? const []) {
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

void _patchIdRegistry(
  File registryFile,
  Iterable<Map<String, dynamic>> creates,
  int nextWorkId,
) {
  final decoded = json.decode(registryFile.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('invalid id_registry.json');
  }
  final map = Map<String, dynamic>.from(decoded);
  final byWk = Map<String, dynamic>.from(map['byWk'] as Map? ?? {});

  for (final c in creates) {
    final wk = c['workId']?.toString() ?? '';
    if (!isWkId(wk)) continue;
    if (byWk.containsKey(wk)) continue;
    byWk[wk] = {
      'category': c['category']?.toString() ?? 'manga',
      'legacyIds': <String>[],
    };
  }

  map['byWk'] = byWk;
  map['nextWorkId'] = nextWorkId;
  registryFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(map)}\n',
  );
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
