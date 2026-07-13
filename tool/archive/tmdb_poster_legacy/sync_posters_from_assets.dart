// ignore_for_file: avoid_print
// Copy posterPath from assets/registry shards into akasha-db when assets has a
// non-JustWatch URL and akasha-db differs.
//
// Usage: dart run tool/archive/tmdb_poster_legacy/sync_posters_from_assets.dart [--dry-run]

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final root = _findProjectRoot();
  final assetsShards = Directory('${root.path}/assets/registry/shards');
  final dbShards = Directory('${root.path}/akasha-db/shards');

  if (!assetsShards.existsSync() || !dbShards.existsSync()) {
    stderr.writeln('ERROR: assets/registry/shards or akasha-db/shards missing');
    exit(1);
  }

  var updated = 0;

  for (final categoryDir in assetsShards.listSync().whereType<Directory>()) {
    final category = _basename(categoryDir.path);
    final dbCategoryDir = Directory('${dbShards.path}/$category');
    if (!dbCategoryDir.existsSync()) continue;

    for (final assetFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final name = _basename(assetFile.path);
      final dbFile = File('${dbCategoryDir.path}/$name');
      if (!dbFile.existsSync()) continue;

      final assetMap =
          json.decode(assetFile.readAsStringSync()) as Map<String, dynamic>;
      final dbMap =
          json.decode(dbFile.readAsStringSync()) as Map<String, dynamic>;

      var fileChanged = false;

      for (final entry in assetMap.entries) {
        final assetWork = entry.value;
        if (assetWork is! Map<String, dynamic>) continue;
        final assetPoster = assetWork['posterPath']?.toString() ?? '';
        if (assetPoster.isEmpty || !assetPoster.startsWith('http')) continue;
        if (assetPoster.contains('justwatch.com')) continue;

        final dbWork = dbMap[entry.key];
        if (dbWork is! Map<String, dynamic>) continue;
        final dbPoster = dbWork['posterPath']?.toString() ?? '';
        if (dbPoster == assetPoster) continue;

        print('${entry.key}:');
        print('  db:     $dbPoster');
        print('  assets: $assetPoster');
        dbWork['posterPath'] = assetPoster;
        fileChanged = true;
        updated++;
      }

      if (fileChanged && !dryRun) {
        const encoder = JsonEncoder.withIndent('  ');
        dbFile.writeAsStringSync('${encoder.convert(dbMap)}\n');
        print('  → wrote ${dbFile.path}');
      }
    }
  }

  print(dryRun
      ? 'Dry run: $updated poster(s) would be updated. Run registry_builder after apply.'
      : 'Updated $updated poster(s). Run: dart run tool/registry_builder.dart --sync-assets');
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

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}
