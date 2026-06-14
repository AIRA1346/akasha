// ignore_for_file: avoid_print
/// 수동 Wikidata Q-id 연결 — live 검증(P31·label·중복) 후 shard 반영.
///
/// Usage:
///   dart run tool/wikidata_link_work.dart --list-missing
///   dart run tool/wikidata_link_work.dart --work wk_000000344 --qid Q1058984
///   dart run tool/wikidata_link_work.dart --work wk_000000344 --qid Q1058984 --apply
///   dart run tool/wikidata_link_work.dart --search "Kingdom" --category manga
///   dart run tool/wikidata_link_work.dart --auto --limit 15
///   dart run tool/wikidata_link_work.dart --auto --limit 15 --apply --build

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'data_policy_utils.dart';
import 'discovery/registry_snapshot.dart';
import 'discovery/wikidata_client.dart';
import 'discovery/wikidata_q_validation.dart';
import 'registry_hash_utils.dart';
import 'wk_id_utils.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final force = args.contains('--force');
  final build = args.contains('--build');
  final listMissing = args.contains('--list-missing');
  final auto = args.contains('--auto');
  final workId = _argValue(args, '--work');
  final qid = _argValue(args, '--qid')?.trim().toUpperCase();
  final search = _argValue(args, '--search');
  final categoryFilter = _argValue(args, '--category');
  final limit = int.tryParse(_argValue(args, '--limit') ?? '') ?? 20;
  final batchPath = _argValue(args, '--batch');

  final root = _findProjectRoot();
  final dbRoot = Directory(p.join(root.path, 'akasha-db'));

  if (listMissing) {
    _printMissing(categoryFilter: categoryFilter, limit: limit);
    return;
  }

  if (search != null && search.isNotEmpty) {
    await _runSearch(search, categoryFilter ?? 'manga');
    return;
  }

  if (auto) {
    await _runAuto(
      dbRoot: dbRoot,
      apply: apply,
      force: force,
      build: build,
      categoryFilter: categoryFilter,
      limit: limit,
    );
    return;
  }

  if (batchPath != null) {
    await _runBatch(
      dbRoot: dbRoot,
      batchPath: batchPath,
      apply: apply,
      force: force,
      build: build,
    );
    return;
  }

  if (workId == null || qid == null) {
    _usage();
    exit(64);
  }

  final ok = await _linkOne(
    dbRoot: dbRoot,
    workId: workId,
    qid: qid,
    apply: apply,
    force: force,
  );
  if (!ok) exit(1);

  if (apply && build) {
    await _runRegistryBuilder(root);
  }
}

Future<void> _runAuto({
  required Directory dbRoot,
  required bool apply,
  required bool force,
  required bool build,
  required String? categoryFilter,
  required int limit,
}) async {
  final missing = _collectMissing(dbRoot, categoryFilter: categoryFilter);
  print('wikidata_link_work — auto');
  print('  missing: ${missing.length}');
  print('  limit: $limit');
  print('  apply: $apply');
  print('');

  var linked = 0;
  var skipped = 0;

  for (final target in missing.take(limit)) {
    final query = _pickSearchQuery(target);
    if (query == null) {
      skipped++;
      continue;
    }

    final hits = await _searchWikidata(query, language: 'en', limit: 3);
    if (hits.isEmpty) {
      print('SKIP ${target.workId} ${target.title} — no search hits for "$query"');
      skipped++;
      continue;
    }

    var linkedThis = false;
    for (final hit in hits) {
      final candidateQ = hit.qid;
      print(
        'TRY ${target.workId} ${target.title} ← $candidateQ (${hit.label})',
      );
      final ok = await _linkOne(
        dbRoot: dbRoot,
        workId: target.workId,
        qid: candidateQ,
        apply: apply,
        force: false,
        strictPassOnly: true,
        quietPass: true,
      );
      if (ok && apply) {
        linked++;
        linkedThis = true;
        break;
      }
      if (ok && !apply) {
        linked++;
        linkedThis = true;
        break;
      }
    }
    if (!linkedThis) skipped++;
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  print('');
  print('Auto summary: linked=$linked skipped=$skipped');
  if (!apply && linked > 0) {
    print('Dry-run. Pass --apply to write shards.');
  }

  if (apply && build && linked > 0) {
    await _runRegistryBuilder(_findProjectRoot());
  }
}

Future<void> _runBatch({
  required Directory dbRoot,
  required String batchPath,
  required bool apply,
  required bool force,
  required bool build,
}) async {
  final file = File(batchPath);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: batch file not found: $batchPath');
    exit(1);
  }
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! List) {
    stderr.writeln('ERROR: batch file must be a JSON array');
    exit(1);
  }

  var ok = 0;
  var fail = 0;
  for (final row in decoded) {
    if (row is! Map) continue;
    final workId = row['workId']?.toString() ?? '';
    final qid = row['qid']?.toString().trim().toUpperCase() ?? '';
    if (workId.isEmpty || qid.isEmpty) continue;
    final success = await _linkOne(
      dbRoot: dbRoot,
      workId: workId,
      qid: qid,
      apply: apply,
      force: force,
    );
    if (success) {
      ok++;
    } else {
      fail++;
    }
  }

  print('Batch: ok=$ok fail=$fail');
  if (apply && build && ok > 0) {
    await _runRegistryBuilder(_findProjectRoot());
  }
  if (fail > 0) exit(1);
}

Future<bool> _linkOne({
  required Directory dbRoot,
  required String workId,
  required String qid,
  required bool apply,
  required bool force,
  bool strictPassOnly = false,
  bool quietPass = false,
}) async {
  if (!isWkId(workId)) {
    stderr.writeln('ERROR: invalid workId: $workId');
    return false;
  }

  final snap = RegistrySnapshot.load(_findProjectRoot());
  final existing = snap.byWorkId[workId];
  if (existing == null) {
    stderr.writeln('ERROR: work not found: $workId');
    return false;
  }

  final currentQ = existing.externalIds['wikidata']?.trim() ?? '';
  if (currentQ.isNotEmpty) {
    if (currentQ == qid) {
      if (!quietPass) print('OK: $workId already has wikidata:$qid');
      return true;
    }
    stderr.writeln(
      'ERROR: $workId already has wikidata:$currentQ (use different work or clear first)',
    );
    return false;
  }

  final meta = await _fetchEntityMeta(qid);
  if (!meta.found) {
    stderr.writeln('ERROR: Wikidata entity not found: $qid');
    return false;
  }

  final allowedP31 = expectedP31ByAkashaCategory[existing.category];
  if (allowedP31 != null &&
      (meta.p31.isEmpty || !meta.p31.any(allowedP31.contains))) {
    if (!quietPass) {
      stderr.writeln(
        'BLOCK: P31 ${meta.p31.join("|")} not allowed for ${existing.category}',
      );
    }
    return false;
  }

  final titles = _titlesFromWork(existing.work);
  final validationTitle = titles['en']?.trim().isNotEmpty == true
      ? titles['en']!.trim()
      : existing.title;

  final registryQids = _allWikidataQids(dbRoot);
  final validation = validateWikidataQidForIngest(
    qid: qid,
    category: existing.category,
    title: validationTitle,
    registryWikidataQids: registryQids,
    entityP31Qids: meta.p31,
    entityEnLabel: meta.enLabel,
  );

  if (!quietPass) {
    print('Link: $workId (${existing.title})');
    print('  category: ${existing.category}');
    print('  validate title: $validationTitle');
    print('  qid: $qid');
    print('  wikidata label (en): ${meta.enLabel ?? "(none)"}');
    print('  P31: ${meta.p31.join(", ")}');
    print('  validation: ${validation.code} — ${validation.detail}');
  }

  if (validation.verdict == WikidataQValidationVerdict.block) {
    stderr.writeln('BLOCK: ${validation.code} — ${validation.detail}');
    return false;
  }
  if (validation.verdict == WikidataQValidationVerdict.review && !force) {
    stderr.writeln(
      'REVIEW: ${validation.detail} — pass --force if label match is acceptable',
    );
    return false;
  }
  if (strictPassOnly && validation.verdict != WikidataQValidationVerdict.pass) {
    return false;
  }

  if (!apply) {
    if (!quietPass) print('Dry-run OK. Pass --apply to write shard.');
    return true;
  }

  final hex = shardHexForWorkId(workId);
  final relPath = v4ShardPath(existing.category, hex);
  final shardFile = File(p.join(dbRoot.path, relPath));
  if (!shardFile.existsSync()) {
    stderr.writeln('ERROR: shard missing: $relPath');
    return false;
  }

  final shardMap = Map<String, dynamic>.from(
    json.decode(shardFile.readAsStringSync()) as Map,
  );
  final workRaw = shardMap[workId];
  if (workRaw is! Map) {
    stderr.writeln('ERROR: entry missing in shard');
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
  extensions['ingestChannel'] = 'manual_wikidata';
  extensions['ingestSource'] = 'manual';
  work['extensions'] = extensions;

  final signals = Map<String, dynamic>.from(
    work['qualitySignals'] as Map? ?? {},
  );
  signals['externalIdVerified'] = true;
  work['qualitySignals'] = signals;

  final issues = lintWorkEntry(
    workId: workId,
    work: work,
    relativePath: relPath,
  );
  if (issues.isNotEmpty) {
    stderr.writeln('ERROR: policy ${issues.first.rule}: ${issues.first.detail}');
    return false;
  }

  shardMap[workId] = work;
  shardFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
  );
  print('APPLIED $workId += wikidata:$qid');
  return true;
}

Future<void> _runSearch(String query, String category) async {
  print('Search Wikidata: "$query" (category hint: $category)');
  final hits = await _searchWikidata(query, language: 'en', limit: 8);
  if (hits.isEmpty) {
    print('No results.');
    return;
  }
  for (final hit in hits) {
    final meta = await _fetchEntityMeta(hit.qid);
    final allowed = expectedP31ByAkashaCategory[category] ?? const {};
    final p31Ok = meta.p31.isEmpty ||
        allowed.isEmpty ||
        meta.p31.any(allowed.contains);
    print(
      '  ${hit.qid}  ${hit.label}  P31=${meta.p31.join("|")}  '
      'category=${p31Ok ? "OK" : "MISMATCH"}',
    );
  }
  print('\nLink: dart run tool/wikidata_link_work.dart --work wk_... --qid Q... --apply');
}

void _printMissing({
  String? categoryFilter,
  required int limit,
}) {
  final missing = _collectMissing(
    Directory(p.join(_findProjectRoot().path, 'akasha-db')),
    categoryFilter: categoryFilter,
  );
  print('Works missing externalIds.wikidata: ${missing.length}');
  if (categoryFilter != null) print('  category filter: $categoryFilter');
  print('');
  for (final w in missing.take(limit)) {
    final mal = w.externalIds['mal'];
    final en = w.titles['en'] ?? '';
    print(
      '  ${w.workId}  ${w.title}  cat=${w.category}'
      '${en.isNotEmpty ? "  en=$en" : ""}'
      '${mal != null ? "  mal=$mal" : ""}',
    );
  }
  if (missing.length > limit) {
    print('  ... and ${missing.length - limit} more');
  }
}

List<_MissingWork> _collectMissing(
  Directory dbRoot, {
  String? categoryFilter,
}) {
  final snap = RegistrySnapshot.load(_findProjectRoot());
  final out = <_MissingWork>[];
  for (final w in snap.works) {
    if (categoryFilter != null && w.category != categoryFilter) continue;
    final wd = w.externalIds['wikidata']?.trim() ?? '';
    if (wd.isNotEmpty) continue;
    final titles = <String, String>{};
    final rawTitles = w.work['titles'];
    if (rawTitles is Map) {
      rawTitles.forEach((k, v) {
        final s = v?.toString().trim() ?? '';
        if (s.isNotEmpty) titles[k.toString()] = s;
      });
    }
    out.add(
      _MissingWork(
        workId: w.workId,
        title: w.title,
        category: w.category,
        titles: titles,
        externalIds: Map<String, String>.from(w.externalIds),
      ),
    );
  }
  out.sort((a, b) => a.title.compareTo(b.title));
  return out;
}

String? _pickSearchQuery(_MissingWork w) {
  final en = w.titles['en']?.trim() ?? '';
  if (en.isNotEmpty) return en;
  final ja = w.titles['ja']?.trim() ?? '';
  if (ja.isNotEmpty) return ja;
  final ko = w.titles['ko']?.trim() ?? '';
  if (ko.isNotEmpty) return ko;
  final title = w.title.trim();
  return title.isNotEmpty ? title : null;
}

Map<String, String> _titlesFromWork(Map<String, dynamic> work) {
  final out = <String, String>{};
  final raw = work['titles'];
  if (raw is Map) {
    raw.forEach((k, v) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) out[k.toString()] = s;
    });
  }
  return out;
}

Set<String> _allWikidataQids(Directory dbRoot) {
  final qids = <String>{};
  final shardsRoot = Directory(p.join(dbRoot.path, 'shards'));
  for (final file in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is! Map) continue;
    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final work = entry.value as Map;
      final ext = work['externalIds'];
      if (ext is! Map) continue;
      final q = ext['wikidata']?.toString().trim() ?? '';
      if (q.isNotEmpty) qids.add(q);
    }
  }
  return qids;
}

class _WikidataSearchHit {
  final String qid;
  final String label;

  const _WikidataSearchHit({required this.qid, required this.label});
}

class _MissingWork {
  final String workId;
  final String title;
  final String category;
  final Map<String, String> titles;
  final Map<String, String> externalIds;

  const _MissingWork({
    required this.workId,
    required this.title,
    required this.category,
    required this.titles,
    required this.externalIds,
  });
}

class _EntityMeta {
  final bool found;
  final Set<String> p31;
  final String? enLabel;

  const _EntityMeta({
    required this.found,
    required this.p31,
    this.enLabel,
  });
}

Future<_EntityMeta> _fetchEntityMeta(String qid) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('https://www.wikidata.org/w/api.php').replace(
      queryParameters: {
        'action': 'wbgetentities',
        'ids': qid,
        'props': 'labels|claims',
        'languages': 'en',
        'format': 'json',
      },
    );
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', akashaDiscoveryUserAgent);
    request.headers.set('Accept', 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Wikidata API HTTP ${response.statusCode}', uri: uri);
    }
    final decoded = json.decode(body);
    if (decoded is! Map) return const _EntityMeta(found: false, p31: {});

    final entities = decoded['entities'];
    if (entities is! Map) return const _EntityMeta(found: false, p31: {});

    final entity = entities[qid];
    if (entity is! Map || entity['missing'] != null) {
      return const _EntityMeta(found: false, p31: {});
    }

    String? enLabel;
    final labels = entity['labels'];
    if (labels is Map) {
      final en = labels['en'];
      if (en is Map) enLabel = en['value']?.toString();
    }

    final p31 = <String>{};
    final claims = entity['claims'];
    if (claims is Map) {
      final inst = claims['P31'];
      if (inst is List) {
        for (final claim in inst) {
          if (claim is! Map) continue;
          final mainsnak = claim['mainsnak'];
          if (mainsnak is! Map) continue;
          final datavalue = mainsnak['datavalue'];
          if (datavalue is! Map) continue;
          final value = datavalue['value'];
          if (value is Map) {
            final id = value['id']?.toString();
            if (id != null && id.isNotEmpty) p31.add(id);
          }
        }
      }
    }

    return _EntityMeta(found: true, p31: p31, enLabel: enLabel);
  } finally {
    client.close(force: true);
  }
}

Future<List<_WikidataSearchHit>> _searchWikidata(
  String query, {
  required String language,
  required int limit,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('https://www.wikidata.org/w/api.php').replace(
      queryParameters: {
        'action': 'wbsearchentities',
        'search': query,
        'language': language,
        'limit': '$limit',
        'format': 'json',
      },
    );
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', akashaDiscoveryUserAgent);
    request.headers.set('Accept', 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Wikidata search HTTP ${response.statusCode}', uri: uri);
    }
    final decoded = json.decode(body);
    if (decoded is! Map) return const [];

    final search = decoded['search'];
    if (search is! List) return const [];

    return [
      for (final row in search)
        if (row is Map)
          _WikidataSearchHit(
            qid: row['id']?.toString() ?? '',
            label: row['label']?.toString() ?? '',
          ),
    ].where((h) => h.qid.startsWith('Q')).toList();
  } finally {
    client.close(force: true);
  }
}

Future<void> _runRegistryBuilder(Directory root) async {
  print('');
  print('==> registry_builder --sync-assets');
  final sdkFile = File(p.join(root.path, 'tool', 'flutter_sdk.path'));
  final flutterRoot = sdkFile.existsSync()
      ? sdkFile.readAsStringSync().trim()
      : r'C:\src\flutter';
  final dart = p.join(flutterRoot, 'bin', 'dart.bat');
  final result = await Process.run(
    dart,
    ['run', 'tool/registry_builder.dart', '--sync-assets'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);
}

void _usage() {
  stderr.writeln('''
Usage:
  dart run tool/wikidata_link_work.dart --list-missing [--category manga] [--limit N]
  dart run tool/wikidata_link_work.dart --search "title" [--category manga]
  dart run tool/wikidata_link_work.dart --work wk_... --qid Q... [--apply] [--force] [--build]
  dart run tool/wikidata_link_work.dart --batch links.json [--apply] [--force] [--build]
  dart run tool/wikidata_link_work.dart --auto [--category manga] [--limit N] [--apply] [--build]
''');
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
