// ignore_for_file: avoid_print
/// Phase A — 기존 샤드 작품에 `wk_` 영구 ID 일괄 할당
///
/// Usage:
///   dart run tool/assign_wk_ids.dart              # dry-run
///   dart run tool/assign_wk_ids.dart --apply      # 샤드·alias·id_registry 갱신
///   dart run tool/assign_wk_ids.dart --apply --sync-assets
///
/// 산출물:
///   akasha-db/id_registry.json
///   akasha-db/legacy_aliases.json (전 legacy → wk_ 매핑)
///   샤드 workId/key → wk_ + legacyIds[]
///   assets/registry/franchise_groups.json members 갱신

import 'dart:convert';
import 'dart:io';

import 'wk_id_utils.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final syncAssets = args.contains('--sync-assets');
  final root = _findProjectRoot();
  final dbRoot = Directory('${root.path}/akasha-db');
  final shardsRoot = Directory('${dbRoot.path}/shards');

  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  final collected = <_CollectedWork>[];
  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    final category = p.basename(categoryDir.path);
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final relativePath =
          'shards/$category/${p.basename(shardFile.path)}';
      final shard = Map<String, dynamic>.from(
        json.decode(shardFile.readAsStringSync()) as Map,
      );
      for (final entry in shard.entries) {
        if (entry.value is! Map) continue;
        final work = Map<String, dynamic>.from(entry.value as Map);
        final workId = work['workId']?.toString() ?? entry.key;
        if (entry.key != workId) {
          stderr.writeln('WARN: key mismatch $relativePath $entry.key != $workId');
        }
        collected.add(
          _CollectedWork(
            legacyId: workId,
            category: work['category']?.toString() ?? category,
            shardPath: relativePath,
            shardFile: shardFile,
            mapKey: entry.key,
            work: work,
          ),
        );
      }
    }
  }

  if (collected.isEmpty) {
    stderr.writeln('ERROR: no works found in shards');
    exit(1);
  }

  final legacyIds = collected.map((w) => w.legacyId).toList()..sort();
  final dupes = <String>[];
  for (var i = 1; i < legacyIds.length; i++) {
    if (legacyIds[i] == legacyIds[i - 1]) dupes.add(legacyIds[i]);
  }
  if (dupes.isNotEmpty) {
    stderr.writeln('ERROR: duplicate legacy workIds: ${dupes.toSet().join(', ')}');
    exit(1);
  }

  collected.sort((a, b) => a.legacyId.compareTo(b.legacyId));

  final alreadyWk = collected.where((w) => isWkIdAny(w.legacyId)).length;
  final toAssign = collected.where((w) => !isWkIdAny(w.legacyId)).toList();

  final legacyToWk = <String, String>{};
  var seq = 1;
  for (final item in collected) {
    if (isWkIdAny(item.legacyId)) {
      legacyToWk[item.legacyId] = canonicalizeWkId(item.legacyId) ?? item.legacyId;
      final n = parseWkSequence(item.legacyId);
      if (n != null && n >= seq) seq = n + 1;
      continue;
    }
    final wk = formatWkId(seq++);
    legacyToWk[item.legacyId] = wk;
  }

  final idRegistry = _buildIdRegistry(legacyToWk, collected, seq);
  final aliases = _buildLegacyAliases(
    root,
    legacyToWk,
  );

  print('assign_wk_ids — ${collected.length} works');
  print('  already wk_: $alreadyWk');
  print('  to assign: ${toAssign.length}');
  print('  nextWorkId: ${idRegistry['nextWorkId']}');
  print('');
  for (final item in toAssign.take(5)) {
    print('  ${legacyToWk[item.legacyId]} ← ${item.legacyId}');
  }
  if (toAssign.length > 5) print('  ... +${toAssign.length - 5} more');

  if (!apply) {
    print('\nDry-run only. Pass --apply to write files.');
    return;
  }

  _applyShards(collected, legacyToWk);
  _writeJson(File('${dbRoot.path}/id_registry.json'), idRegistry);
  _writeJson(File('${dbRoot.path}/legacy_aliases.json'), aliases);
  _updateFranchiseGroups(root, legacyToWk);

  print('\nWrote id_registry.json, legacy_aliases.json, shard workIds');

  if (syncAssets) {
    final builder = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'tool/registry_builder.dart', '--sync-assets'],
      workingDirectory: root.path,
      runInShell: true,
    );
    await stdout.addStream(builder.stdout);
    await stderr.addStream(builder.stderr);
    final code = await builder.exitCode;
    if (code != 0) exit(code);
  } else {
    print('Run: dart run tool/registry_builder.dart --sync-assets');
  }
}

class _CollectedWork {
  final String legacyId;
  final String category;
  final String shardPath;
  final File shardFile;
  final String mapKey;
  final Map<String, dynamic> work;

  _CollectedWork({
    required this.legacyId,
    required this.category,
    required this.shardPath,
    required this.shardFile,
    required this.mapKey,
    required this.work,
  });
}

Map<String, dynamic> _buildIdRegistry(
  Map<String, String> legacyToWk,
  List<_CollectedWork> collected,
  int nextSeq,
) {
  final byWk = <String, dynamic>{};
  final byLegacy = <String, String>{};

  for (final item in collected) {
    final legacy = item.legacyId;
    final wk = legacyToWk[legacy]!;
    byLegacy[legacy] = wk;

    if (!isWkId(legacy)) {
      byWk[wk] = {
        'category': item.category,
        'legacyIds': [legacy],
      };
    } else {
      final existing = byWk[wk];
      if (existing is Map) {
        final ids = List<String>.from(existing['legacyIds'] as List? ?? []);
        if (!ids.contains(legacy)) ids.add(legacy);
        existing['legacyIds'] = ids;
      } else {
        byWk[wk] = {
          'category': item.category,
          'legacyIds': <String>[legacy],
        };
      }
    }
  }

  return {
    'version': 1,
    'nextWorkId': nextSeq,
    'byWk': byWk,
    'byLegacy': byLegacy,
  };
}

Map<String, String> _buildLegacyAliases(
  Directory root,
  Map<String, String> legacyToWk,
) {
  final aliasesFile = File('${root.path}/akasha-db/legacy_aliases.json');
  final aliases = <String, String>{};
  if (aliasesFile.existsSync()) {
    final decoded = json.decode(aliasesFile.readAsStringSync());
    if (decoded is Map) {
      decoded.forEach((k, v) {
        aliases[k.toString()] = v.toString();
      });
    }
  }

  for (final entry in aliases.entries.toList()) {
    final canonical = _resolveAliasChain(entry.value, aliases);
    final wk = legacyToWk[canonical] ?? legacyToWk[entry.value];
    if (wk != null) {
      aliases[entry.key] = wk;
    }
  }

  for (final entry in legacyToWk.entries) {
    if (!isWkId(entry.key)) {
      aliases[entry.key] = entry.value;
    }
  }

  final sorted = Map.fromEntries(
    aliases.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return sorted;
}

String _resolveAliasChain(String start, Map<String, String> aliases) {
  var current = start;
  final seen = <String>{};
  while (aliases.containsKey(current) && !seen.contains(current)) {
    seen.add(current);
    current = aliases[current]!;
  }
  return current;
}

void _applyShards(List<_CollectedWork> collected, Map<String, String> legacyToWk) {
  final byFile = <String, Map<String, dynamic>>{};

  for (final item in collected) {
    final wk = legacyToWk[item.legacyId]!;
    if (isWkId(item.legacyId) && item.legacyId == wk) continue;

    final path = item.shardFile.path;
    byFile.putIfAbsent(path, () {
      return Map<String, dynamic>.from(
        json.decode(item.shardFile.readAsStringSync()) as Map,
      );
    });

    final shard = byFile[path]!;
    shard.remove(item.mapKey);

    final work = Map<String, dynamic>.from(item.work);
    work['workId'] = wk;
    final legacyIds = <String>[];
    if (!isWkId(item.legacyId)) legacyIds.add(item.legacyId);
    final existingLegacy = work['legacyIds'];
    if (existingLegacy is List) {
      for (final id in existingLegacy) {
        final s = id.toString();
        if (s.isNotEmpty && !legacyIds.contains(s)) legacyIds.add(s);
      }
    }
    if (legacyIds.isNotEmpty) {
      work['legacyIds'] = legacyIds;
    }
    shard[wk] = work;
  }

  for (final entry in byFile.entries) {
    final sorted = Map.fromEntries(
      entry.value.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    File(entry.key).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
    );
  }
}

void _updateFranchiseGroups(Directory root, Map<String, String> legacyToWk) {
  final assetsPath = '${root.path}/assets/registry/franchise_groups.json';
  final dbPath = '${root.path}/akasha-db/franchise_groups.json';
  if (!File(dbPath).existsSync() && File(assetsPath).existsSync()) {
    File(assetsPath).copySync(dbPath);
  }

  for (final path in [assetsPath, dbPath]) {
    final file = File(path);
    if (!file.existsSync()) continue;

    final raw = Map<String, dynamic>.from(
      json.decode(file.readAsStringSync()) as Map,
    );

    raw.forEach((key, value) {
      if (key == '_schema' || value is! Map) return;
      final group = Map<String, dynamic>.from(value);

      final members = (group['members'] as List?)
              ?.map((e) => e.toString())
              .map((id) => legacyToWk[id] ?? id)
              .toList() ??
          <String>[];
      group['members'] = members;

      final primary = group['primaryWorkId']?.toString();
      if (primary != null && primary.isNotEmpty) {
        group['primaryWorkId'] = legacyToWk[primary] ?? primary;
      }

      raw[key] = group;
    });

    _writeJson(file, raw);
    print('Updated ${file.path}');
  }
}

void _writeJson(File file, Object data) {
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}

/// path.basename — registry_builder와 동일하게 로컬 구현
class p {
  static String basename(String path) {
    final sep = path.contains('\\') ? '\\' : '/';
    return path.split(sep).last;
  }
}
