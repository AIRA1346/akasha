// ignore_for_file: avoid_print
/// akasha-db 샤드를 v3 메타데이터로 점진 마이그레이션
///
/// - `titles` 없으면 레거시 `title`에서 추정
/// - `extensions`의 anilist/steam/isbn → `externalIds` 승격
/// - `title`은 유지 (하위 호환·정렬)
///
/// Usage:
///   dart run tool/migrate_registry_v3.dart
///   dart run tool/migrate_registry_v3.dart --dry-run
///   dart run tool/registry_builder.dart --sync-assets

import 'dart:convert';
import 'dart:io';

import 'registry_v3_utils.dart';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');

  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  var filesTouched = 0;
  var worksUpdated = 0;

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final content = json.decode(shardFile.readAsStringSync());
      if (content is! Map<String, dynamic>) continue;

      var changed = false;
      final next = <String, dynamic>{};

      for (final entry in content.entries) {
        if (entry.value is! Map) {
          next[entry.key] = entry.value;
          continue;
        }
        final work = Map<String, dynamic>.from(entry.value as Map);
        if (_upgradeWork(work)) {
          changed = true;
          worksUpdated++;
        }
        next[entry.key] = work;
      }

      if (!changed) continue;
      filesTouched++;
      if (dryRun) {
        print('would update: ${shardFile.path}');
        continue;
      }

      const encoder = JsonEncoder.withIndent('  ');
      shardFile.writeAsStringSync('${encoder.convert(next)}\n');
      print('updated: ${shardFile.path}');
    }
  }

  print('\nDone: $worksUpdated works in $filesTouched shard files'
      '${dryRun ? ' (dry-run)' : ''}');
  if (!dryRun && worksUpdated > 0) {
    print('Next: dart run tool/registry_builder.dart --sync-assets');
  }
}

bool _upgradeWork(Map<String, dynamic> work) {
  var changed = false;
  final title = work['title']?.toString() ?? '';

  final titles = parseTitlesJson(work['titles']);
  if (titles.isEmpty && title.isNotEmpty) {
    work['titles'] = inferTitlesFromLegacyTitle(title);
    changed = true;
  }

  final extensions = work['extensions'];
  final extMap = extensions is Map
      ? Map<String, dynamic>.from(extensions)
      : <String, dynamic>{};
  final explicit = parseTitlesJson(work['externalIds']);
  final merged = mergeExternalIds(extensions: extMap, explicit: explicit);
  if (merged.isNotEmpty) {
    final current = parseTitlesJson(work['externalIds']);
    if (current.length != merged.length || !_mapsEqual(current, merged)) {
      work['externalIds'] = merged;
      changed = true;
    }
  }

  return changed;
}

bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
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
