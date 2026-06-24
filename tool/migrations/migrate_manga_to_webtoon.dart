// ignore_for_file: avoid_print
/// ÎßåÌôî ?§Îìú?êÏÑú ?πÌà∞ ?ëÌíà??Î∂ÑÎ¶¨?©Îãà??
/// Usage: dart run tool/migrations/migrate_manga_to_webtoon.dart [--apply]

import 'dart:convert';
import 'dart:io';

/// ?êÎ†à?¥ÏÖò Í∏∞Ï? ?πÌà∞ (manga work_id)
const _curatedMangaWorkIds = <String>{
  'sub_manga_solo-leveling_2018',
  'sub_manga_tower-of-god_2010',
};

void main(List<String> args) {
  final apply = args.contains('--apply');
  final root = _findProjectRoot();
  final mangaRoot = Directory('${root.path}/akasha-db/shards/manga');
  final webtoonRoot = Directory('${root.path}/akasha-db/shards/webtoon');
  final aliasesFile = File('${root.path}/akasha-db/legacy_aliases.json');

  if (!mangaRoot.existsSync()) {
    stderr.writeln('manga shards not found');
    exit(1);
  }
  webtoonRoot.createSync(recursive: true);

  final aliases = _loadAliases(aliasesFile);
  final toMigrate = <String, Map<String, dynamic>>{};

  for (final shardFile in mangaRoot.listSync().whereType<File>()) {
    if (!shardFile.path.endsWith('.json')) continue;
    final shard = Map<String, dynamic>.from(
      json.decode(shardFile.readAsStringSync()) as Map,
    );

    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key;
      if (!_shouldMigrate(workId, work)) continue;
      toMigrate[workId] = work;
      print('PLAN $workId ??${_toWebtoonId(workId)}');
    }
  }

  if (!apply) {
    print('Found ${toMigrate.length} works. Pass --apply to migrate.');
    return;
  }

  for (final shardFile in mangaRoot.listSync().whereType<File>()) {
    if (!shardFile.path.endsWith('.json')) continue;
    final shard = Map<String, dynamic>.from(
      json.decode(shardFile.readAsStringSync()) as Map,
    );
    var dirty = false;
    for (final key in shard.keys.toList()) {
      final value = shard[key];
      if (value is! Map) continue;
      final workId =
          (value['workId']?.toString() ?? key).toString();
      if (!toMigrate.containsKey(workId)) continue;
      shard.remove(key);
      dirty = true;
    }
    if (dirty) {
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
      );
    }
  }

  final webtoonShards = <String, Map<String, dynamic>>{};

  for (final entry in toMigrate.entries) {
    final oldId = entry.key;
    final newId = _toWebtoonId(oldId);
    final work = Map<String, dynamic>.from(entry.value);
    work['workId'] = newId;
    work['category'] = 'webtoon';

    final shardId = _shardIdFor(newId);
    webtoonShards.putIfAbsent(shardId, () => {});
    webtoonShards[shardId]![newId] = work;

    aliases[oldId] = newId;
    print('MOVED $oldId ??$newId ($shardId)');
  }

  for (final shardEntry in webtoonShards.entries) {
    final path = '${webtoonRoot.path}/${shardEntry.key}.json';
    final file = File(path);
    Map<String, dynamic> shard = {};
    if (file.existsSync()) {
      shard = Map<String, dynamic>.from(
        json.decode(file.readAsStringSync()) as Map,
      );
    }
    shard.addAll(shardEntry.value);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(shard)}\n',
    );
  }

  aliasesFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(aliases)}\n',
  );
  print('Done: migrated=${toMigrate.length}');
}

bool _shouldMigrate(String workId, Map<String, dynamic> work) {
  if (_curatedMangaWorkIds.contains(workId)) return true;
  final tags = work['tags'];
  if (tags is List) {
    for (final tag in tags) {
      if (tag.toString().contains('?πÌà∞')) return true;
    }
  }
  return false;
}

String _toWebtoonId(String mangaWorkId) =>
    mangaWorkId
        .replaceFirst('sub_manga_', 'sub_webtoon_')
        .replaceFirst('gen_manga_', 'gen_webtoon_');

String _shardIdFor(String workId) {
  final parts = workId.split('_');
  if (parts.length < 4) return 'webtoon_misc';
  final slug = parts[parts.length - 2];
  if (slug.isEmpty) return 'webtoon_misc';
  final first = slug[0].toUpperCase();
  if (RegExp(r'[0-9]').hasMatch(first)) return 'webtoon_numeric';
  if (!RegExp(r'[A-Z]').hasMatch(first)) return 'webtoon_misc';
  return 'webtoon_$first';
}

Map<String, String> _loadAliases(File file) {
  if (!file.existsSync()) return {};
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map) return {};
  return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
