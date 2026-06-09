// ignore_for_file: avoid_print
/// `id_registry.json` ↔ 샤드 · legacy_aliases 일관성 검증
///
/// Usage: dart run tool/id_registry_check.dart

import 'dart:convert';
import 'dart:io';

import 'wk_id_utils.dart';

void main() {
  final root = _findProjectRoot();
  final registryFile = File('${root.path}/akasha-db/id_registry.json');
  if (!registryFile.existsSync()) {
    stderr.writeln('SKIP: id_registry.json not found (run assign_wk_ids --apply)');
    exit(0);
  }

  final errors = <String>[];
  final registry = Map<String, dynamic>.from(
    json.decode(registryFile.readAsStringSync()) as Map,
  );

  final byWk = registry['byWk'];
  final byLegacy = registry['byLegacy'];
  if (byWk is! Map || byLegacy is! Map) {
    stderr.writeln('FAIL: id_registry missing byWk/byLegacy');
    exit(1);
  }

  final shardWkIds = _collectShardWorkIds(root);
  final registryWkIds = byWk.keys.map((e) => e.toString()).toSet();

  var stubSkipped = 0;
  for (final wk in shardWkIds) {
    if (!isWkId(wk)) {
      if (_isMaintainerStubId(wk)) {
        stubSkipped++;
        continue;
      }
      errors.add('Shard workId is not wk_: $wk');
      continue;
    }
    if (!registryWkIds.contains(wk)) {
      errors.add('Shard $wk missing from id_registry.byWk');
    }
  }

  for (final wk in registryWkIds) {
    if (!shardWkIds.contains(wk)) {
      errors.add('id_registry $wk not found in shards');
    }
    if (!isWkId(wk)) {
      errors.add('Invalid wk key in byWk: $wk');
    }
  }

  byLegacy.forEach((legacy, wk) {
    final wkStr = wk.toString();
    if (!isWkId(wkStr)) {
      errors.add('byLegacy $legacy → non-wk: $wkStr');
    }
    if (!byWk.containsKey(wkStr)) {
      errors.add('byLegacy $legacy → orphan wk: $wkStr');
    }
  });

  final aliasesFile = File('${root.path}/akasha-db/legacy_aliases.json');
  if (aliasesFile.existsSync()) {
    final aliases = json.decode(aliasesFile.readAsStringSync());
    if (aliases is Map) {
      aliases.forEach((key, value) {
        final v = value.toString();
        if (isWkId(v)) return;
        if (!byLegacy.containsKey(v) && !shardWkIds.contains(v)) {
          errors.add('legacy_aliases[$key] → unresolved: $v');
        }
      });
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('FAIL: ${errors.length} id_registry issue(s):');
    for (final e in errors.take(25)) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }

  final wkCount = shardWkIds.where(isWkId).length;
  print(
    'OK: id_registry ($wkCount wk_, $stubSkipped maintainer stub(s), '
    '${byLegacy.length} legacy mappings)',
  );
}

/// A5 Pilot/Scale Maintainer `sub_` stub — wk_ 할당 전 transitional ID.
bool _isMaintainerStubId(String workId) =>
    workId.startsWith('sub_') &&
    (workId.contains('pilot') || workId.contains('scale'));

Set<String> _collectShardWorkIds(Directory root) {
  final ids = <String>{};
  final shardsRoot = Directory('${root.path}/akasha-db/shards');
  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;
    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      ids.add(workId);
    }
  }
  return ids;
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
