// ignore_for_file: avoid_print
// AniList bulk 시드 작품을 akasha-db에서 제거 (법무 정책)
//
// 삭제 조건:
//   - extensions.seedSource == anilist_popularity
//   - workId slug이 `-a{digits}` 패턴 (예: naruto-a30011)
//
// Usage:
//   dart run tool/purge_anilist_bulk.dart           # dry-run
//   dart run tool/purge_anilist_bulk.dart --apply
//   dart run tool/registry_builder.dart --sync-assets

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final aliasesPath = '${projectRoot.path}/akasha-db/legacy_aliases.json';

  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  final allWorks = <String, Map<String, dynamic>>{};
  final workToShardFile = <String, File>{};

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map<String, dynamic>) continue;
    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      allWorks[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      workToShardFile[entry.key] = f;
    }
  }

  final curatedIds = <String>{};
  final bulkIds = <String>{};

  for (final id in allWorks.keys) {
    if (_isAnilistBulk(id, allWorks[id]!)) {
      bulkIds.add(id);
    } else {
      curatedIds.add(id);
    }
  }

  final normToCurated = <String, String>{};
  for (final id in curatedIds) {
    normToCurated[_normalizeWorkId(id)] = id;
  }

  final newAliases = <String, String>{};
  final existingAliases = _loadAliases(aliasesPath);
  newAliases.addAll(existingAliases);

  var aliasAdded = 0;
  for (final bulkId in bulkIds) {
    final norm = _normalizeWorkId(bulkId);
    final target = normToCurated[norm];
    if (target != null && target != bulkId) {
      if (!newAliases.containsKey(bulkId)) {
        newAliases[bulkId] = target;
        aliasAdded++;
      }
    }
  }

  final onlyBulk = bulkIds.where((id) {
    final norm = _normalizeWorkId(id);
    return !normToCurated.containsKey(norm);
  }).toList();

  print('Catalog scan: ${allWorks.length} works');
  print('  curated (keep): ${curatedIds.length}');
  print('  anilist bulk (remove): ${bulkIds.length}');
  print('  aliases to add: $aliasAdded');
  print('  bulk-only (no curated twin): ${onlyBulk.length}');

  if (!apply) {
    print('\nDry-run only. Pass --apply to write changes.');
    print('Sample removals (first 10):');
    for (final id in bulkIds.take(10)) {
      final twin = normToCurated[_normalizeWorkId(id)];
      print('  - $id${twin != null ? ' → alias $twin' : ''}');
    }
    return;
  }

  final filesToUpdate = <File, Map<String, dynamic>>{};

  for (final bulkId in bulkIds) {
    final file = workToShardFile[bulkId];
    if (file == null) continue;

    filesToUpdate.putIfAbsent(file, () {
      final decoded = json.decode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    });

    filesToUpdate[file]!.remove(bulkId);
  }

  var filesWritten = 0;
  var filesDeleted = 0;
  const encoder = JsonEncoder.withIndent('  ');

  for (final entry in filesToUpdate.entries) {
    final file = entry.key;
    final map = entry.value;
    if (map.isEmpty) {
      file.deleteSync();
      filesDeleted++;
      continue;
    }
    file.writeAsStringSync('${encoder.convert(map)}\n');
    filesWritten++;
  }

  File(aliasesPath).writeAsStringSync('${encoder.convert(newAliases)}\n');

  print('\nApplied:');
  print('  removed works: ${bulkIds.length}');
  print('  shard files updated: $filesWritten');
  print('  empty shard files deleted: $filesDeleted');
  print('  legacy_aliases entries: ${newAliases.length} (+$aliasAdded)');
  print('\nNext: dart run tool/registry_builder.dart --sync-assets');
}

bool _isAnilistBulk(String workId, Map<String, dynamic> work) {
  final ext = work['extensions'];
  if (ext is Map && ext['seedSource']?.toString() == 'anilist_popularity') {
    return true;
  }
  return _hasAnilistSlug(workId);
}

bool _hasAnilistSlug(String workId) {
  final parts = workId.split('_');
  if (parts.length < 4) return false;
  return RegExp(r'-a\d+$').hasMatch(parts[2]);
}

String _normalizeWorkId(String workId) {
  final parts = workId.split('_');
  if (parts.length < 4) return workId;
  final slug = parts[2].replaceAll(RegExp(r'-a\d+$'), '');
  return '${parts[0]}_${parts[1]}_${slug}_${parts[3]}';
}

Map<String, String> _loadAliases(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map) return {};
  return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
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
