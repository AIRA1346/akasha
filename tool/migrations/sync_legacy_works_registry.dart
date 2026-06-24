// ignore_for_file: avoid_print
/// ?àÍ±∞??works_registry.json??poster/extensionsÎ•??§Îìú ÎßàÏä§???∞Ïù¥?∞Î°ú ?ôÍ∏∞?îÌï©?àÎã§.
///
/// Usage: dart run tool/migrations/sync_legacy_works_registry.dart [--dry-run]

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final root = _findProjectRoot();
  final legacyPath = File('${root.path}/akasha-db/works_registry.json');
  final aliasesPath = File('${root.path}/akasha-db/legacy_aliases.json');
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  if (!legacyPath.existsSync() || !aliasesPath.existsSync()) {
    stderr.writeln('ERROR: works_registry.json or legacy_aliases.json missing');
    exit(1);
  }

  final aliases = Map<String, String>.from(
    json.decode(aliasesPath.readAsStringSync()) as Map,
  );
  final masterWorks = _loadAllShardWorks(shardsRoot);
  final legacy =
      Map<String, dynamic>.from(json.decode(legacyPath.readAsStringSync()) as Map);

  var updated = 0;
  var justwatchFixed = 0;

  legacy.forEach((key, value) {
    if (value is! Map) return;
    final work = Map<String, dynamic>.from(value);
    final legacyWorkId = work['workId']?.toString() ?? key;
    final masterId = aliases[legacyWorkId] ??
        aliases[key] ??
        (masterWorks.containsKey(legacyWorkId) ? legacyWorkId : null);
    if (masterId == null) return;

    final shard = masterWorks[masterId];
    if (shard == null) return;

    var changed = false;
    final currentPoster = work['posterPath']?.toString() ?? '';
    final shardPoster = shard['posterPath']?.toString() ?? '';

    if (shardPoster.isNotEmpty &&
        (currentPoster.contains('justwatch.com') ||
            (currentPoster.isNotEmpty && currentPoster != shardPoster))) {
      print('$legacyWorkId poster:');
      print('  legacy: $currentPoster');
      print('  shard:  $shardPoster');
      work['posterPath'] = shardPoster;
      changed = true;
      if (currentPoster.contains('justwatch.com')) justwatchFixed++;
    }

    final shardExtensions = shard['extensions'];
    if (shardExtensions is Map && shardExtensions.isNotEmpty) {
      work['extensions'] = shardExtensions;
      changed = true;
    }

    if (changed) {
      legacy[key] = work;
      updated++;
    }
  });

  if (!dryRun && updated > 0) {
    const encoder = JsonEncoder.withIndent('  ');
    legacyPath.writeAsStringSync('${encoder.convert(legacy)}\n');
  }

  print(dryRun
      ? 'Dry run: $updated entry(ies), $justwatchFixed JustWatch poster(s) would update.'
      : 'Updated $updated entry(ies), fixed $justwatchFixed JustWatch poster(s).');
}

Map<String, Map<String, dynamic>> _loadAllShardWorks(Directory shardsRoot) {
  final works = <String, Map<String, dynamic>>{};
  if (!shardsRoot.existsSync()) return works;

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final decoded = json.decode(shardFile.readAsStringSync());
      if (decoded is! Map) continue;
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final map = Map<String, dynamic>.from(value);
        final workId = map['workId']?.toString() ?? key.toString();
        works[workId] = map;
      });
    }
  }
  return works;
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
