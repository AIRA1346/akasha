// ignore_for_file: avoid_print
/// 기존 8자리 `wk_` → 9자리 canonical 형식 일괄 변환
///
/// Usage:
///   dart run tool/migrate_wk_pad9.dart
///   dart run tool/migrate_wk_pad9.dart --apply --sync-assets
///
/// `wk_00000402` → `wk_000000402` (순번·legacy 매핑 유지)

import 'dart:convert';
import 'dart:io';

import 'wk_id_utils.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final syncAssets = args.contains('--sync-assets');
  final root = _findProjectRoot();
  final remap = _buildRemap(root);

  if (remap.isEmpty) {
    print('OK: no 8-digit wk_ IDs found (already 9-digit or empty)');
    exit(0);
  }

  print('migrate_wk_pad9 — ${remap.length} ID(s) to re-pad');
  for (final entry in remap.entries.take(5)) {
    print('  ${entry.key} → ${entry.value}');
  }
  if (remap.length > 5) print('  ... +${remap.length - 5} more');

  if (!apply) {
    print('\nDry-run — pass --apply to write');
    exit(0);
  }

  _applyShards(root, remap);
  _applyIdRegistry(root, remap);
  _applyLegacyAliases(root, remap);
  _applyFranchiseGroups(root, remap);

  print('\nOK: migrated ${remap.length} wk_ ID(s)');

  if (syncAssets) {
    final builder = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'tool/registry_builder.dart', '--sync-assets'],
      workingDirectory: root.path,
      runInShell: true,
    );
    await stdout.addStream(builder.stdout);
    await stderr.addStream(builder.stderr);
    if (await builder.exitCode != 0) exit(1);
  }
}

Map<String, String> _buildRemap(Directory root) {
  final remap = <String, String>{};
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;
    for (final key in decoded.keys) {
      final id = key.toString();
      if (isWkIdLegacy8(id)) {
        remap[id] = canonicalizeWkId(id)!;
      }
    }
  }

  return remap;
}

void _applyShards(Directory root, Map<String, String> remap) {
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = Map<String, dynamic>.from(
      json.decode(f.readAsStringSync()) as Map,
    );

    final next = <String, dynamic>{};
    var changed = false;

    for (final entry in decoded.entries) {
      final oldKey = entry.key;
      final newKey = remap[oldKey] ?? oldKey;
      if (newKey != oldKey) changed = true;

      if (entry.value is! Map) {
        next[newKey] = entry.value;
        continue;
      }

      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? oldKey;
      final newId = remap[workId] ?? workId;
      if (newId != workId) {
        work['workId'] = newId;
        changed = true;
      }
      next[newKey] = work;
    }

    if (!changed) continue;
    f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(next)}\n');
    print('  shard: ${f.path}');
  }
}

void _applyIdRegistry(Directory root, Map<String, String> remap) {
  final file = File('${root.path}/akasha-db/id_registry.json');
  if (!file.existsSync()) return;

  final registry = Map<String, dynamic>.from(
    json.decode(file.readAsStringSync()) as Map,
  );
  final byWk = Map<String, dynamic>.from(registry['byWk'] as Map);
  final byLegacy = Map<String, dynamic>.from(registry['byLegacy'] as Map);

  final newByWk = <String, dynamic>{};
  byWk.forEach((wk, value) {
    newByWk[remap[wk] ?? wk] = value;
  });

  byLegacy.forEach((legacy, wk) {
    final wkStr = wk.toString();
    byLegacy[legacy] = remap[wkStr] ?? wkStr;
  });

  registry['byWk'] = newByWk;
  registry['byLegacy'] = byLegacy;

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(registry)}\n');
  print('  id_registry.json');
}

void _applyLegacyAliases(Directory root, Map<String, String> remap) {
  final file = File('${root.path}/akasha-db/legacy_aliases.json');
  if (!file.existsSync()) return;

  final aliases = Map<String, dynamic>.from(
    json.decode(file.readAsStringSync()) as Map,
  );

  aliases.forEach((key, value) {
    final v = value.toString();
    if (remap.containsKey(v)) aliases[key] = remap[v];
  });

  // 볼트에 구 8자리 wk_가 남아 있어도 9자리로 해석
  for (final entry in remap.entries) {
    aliases[entry.key] = entry.value;
  }

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(aliases)}\n');
  print('  legacy_aliases.json');
}

void _applyFranchiseGroups(Directory root, Map<String, String> remap) {
  final file = File('${root.path}/akasha-db/franchise_groups.json');
  if (!file.existsSync()) return;

  final groups = Map<String, dynamic>.from(
    json.decode(file.readAsStringSync()) as Map,
  );
  var changed = false;

  groups.forEach((id, value) {
    if (id.startsWith('_') || value is! Map) return;
    final map = Map<String, dynamic>.from(value);
    final members =
        (map['members'] as List?)?.map((e) => e.toString()).toList() ?? [];
    map['members'] = members.map((m) => remap[m] ?? m).toList();
    final primary = map['primaryWorkId']?.toString();
    if (primary != null && remap.containsKey(primary)) {
      map['primaryWorkId'] = remap[primary];
      changed = true;
    }
    if (members.any(remap.containsKey)) changed = true;
    groups[id] = map;
  });

  if (changed) {
    file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(groups)}\n');
    print('  franchise_groups.json');
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
