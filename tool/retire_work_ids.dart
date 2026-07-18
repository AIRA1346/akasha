// ignore_for_file: avoid_print
// 중복 wk_ 병합 — loser 레거시를 survivor에 흡수 후 샤드·레지스트리에서 제거
//
// Usage:
//   dart run tool/retire_work_ids.dart --survivor=wk_00000039 --retire=wk_00000040 --apply
//
// wk_ 번호는 재사용하지 않습니다. loser 키는 샤드에서만 삭제됩니다.

import 'dart:convert';
import 'dart:io';

import 'wk_id_utils.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final survivor = _argValue(args, '--survivor');
  final retirees = _argValues(args, '--retire');

  if (survivor == null || retirees.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/retire_work_ids.dart '
      '--survivor=wk_xxx --retire=wk_yyy [--retire=wk_zzz] [--apply]',
    );
    exit(64);
  }

  if (!isWkId(survivor)) {
    stderr.writeln('Invalid survivor: $survivor');
    exit(1);
  }
  for (final r in retirees) {
    if (!isWkId(r)) {
      stderr.writeln('Invalid retire id: $r');
      exit(1);
    }
    if (r == survivor) {
      stderr.writeln('Survivor cannot be retired: $r');
      exit(1);
    }
  }

  final root = _findProjectRoot();
  final retireSet = retirees.toSet();
  final mergedLegacy = _collectMergedLegacy(root, survivor, retireSet);

  print('Survivor: $survivor');
  for (final r in retirees) {
    print('  retire: $r');
  }
  print('Merged legacyIds (${mergedLegacy.length}): ${mergedLegacy.join(', ')}');

  if (!apply) {
    print('\nDry-run — pass --apply to execute');
    exit(0);
  }

  _applyShards(root, survivor, retireSet, mergedLegacy);
  _applyIdRegistry(root, survivor, retireSet, mergedLegacy);
  _applyLegacyAliases(root, survivor, retireSet, mergedLegacy);
  _applyFranchiseGroups(root, survivor, retireSet);

  print('OK: retired ${retirees.length} work(s); run registry_builder');
}

List<String> _collectMergedLegacy(
  Directory root,
  String survivor,
  Set<String> retirees,
) {
  final legacy = <String>{};
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      if (workId != survivor && !retirees.contains(workId)) continue;

      final ids = (work['legacyIds'] as List?)?.map((e) => e.toString()) ?? [];
      legacy.addAll(ids);
    }
  }

  return legacy.toList()..sort();
}

void _applyShards(
  Directory root,
  String survivor,
  Set<String> retirees,
  List<String> mergedLegacy,
) {
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = Map<String, dynamic>.from(
      json.decode(f.readAsStringSync()) as Map,
    );

    var changed = false;
    for (final id in retirees) {
      if (decoded.remove(id) != null) changed = true;
    }

    if (decoded.containsKey(survivor)) {
      final work = Map<String, dynamic>.from(decoded[survivor] as Map);
      work['legacyIds'] = mergedLegacy;
      decoded[survivor] = work;
      changed = true;
    }

    if (!changed) continue;

    f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(decoded)}\n');
    print('  shard: ${f.path}');
  }
}

void _applyIdRegistry(
  Directory root,
  String survivor,
  Set<String> retirees,
  List<String> mergedLegacy,
) {
  final file = File('${root.path}/akasha-db/id_registry.json');
  final registry = Map<String, dynamic>.from(
    json.decode(file.readAsStringSync()) as Map,
  );
  final byWk = Map<String, dynamic>.from(registry['byWk'] as Map);
  final byLegacy = Map<String, dynamic>.from(registry['byLegacy'] as Map);

  final survivorEntry = Map<String, dynamic>.from(byWk[survivor] as Map);
  survivorEntry['legacyIds'] = mergedLegacy;
  byWk[survivor] = survivorEntry;

  for (final loser in retirees) {
    byWk.remove(loser);
    byLegacy.removeWhere((_, wk) => wk.toString() == loser);
  }

  for (final legacy in mergedLegacy) {
    byLegacy[legacy] = survivor;
  }

  registry['byWk'] = byWk;
  registry['byLegacy'] = byLegacy;

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(registry)}\n');
  print('  id_registry.json');
}

void _applyLegacyAliases(
  Directory root,
  String survivor,
  Set<String> retirees,
  List<String> mergedLegacy,
) {
  final file = File('${root.path}/akasha-db/legacy_aliases.json');
  if (!file.existsSync()) return;

  final aliases = Map<String, dynamic>.from(
    json.decode(file.readAsStringSync()) as Map,
  );

  aliases.forEach((key, value) {
    if (retirees.contains(value.toString())) {
      aliases[key] = survivor;
    }
  });

  for (final legacy in mergedLegacy) {
    aliases[legacy] = survivor;
  }

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(aliases)}\n');
  print('  legacy_aliases.json');
}

void _applyFranchiseGroups(
  Directory root,
  String survivor,
  Set<String> retirees,
) {
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
    final updated = <String>[];
    for (final m in members) {
      if (retirees.contains(m)) {
        if (!updated.contains(survivor)) updated.add(survivor);
        changed = true;
      } else {
        updated.add(m);
      }
    }
    map['members'] = updated;
    if (retirees.contains(map['primaryWorkId']?.toString())) {
      map['primaryWorkId'] = survivor;
      changed = true;
    }
    groups[id] = map;
  });

  if (changed) {
    file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(groups)}\n');
    print('  franchise_groups.json');
  }
}

String? _argValue(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

List<String> _argValues(List<String> args, String name) {
  return args
      .where((a) => a.startsWith('$name='))
      .map((a) => a.substring(name.length + 1))
      .toList();
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
