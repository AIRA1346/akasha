// ignore_for_file: avoid_print
/// batch5 누락·깨진 포스터 보강 + TMDB path 이중 슬래시 정리
import 'dart:convert';
import 'dart:io';

const _base = 'https://image.tmdb.org/t/p/w500';

final _posterByWorkId = <String, String>{
  'sub_animation_danmachi_2015': '$_base/1UVNq3idXo9k9D7s7Wm4q93KM9c.jpg',
  'sub_animation_classroom-of-the-elite_2017':
      '$_base/kutFu5sPlZRGksLA6lva7J9HLJw.jpg',
  'sub_manga_grand-blue_2014': '$_base/df2BpzYyo4p4UrD12NGu1mKhkMc.jpg',
  'sub_manga_nagatoro_2017': '$_base/dacZNeYhaOB3Bo2RahF3pGQFac5.jpg',
  'sub_manga_dgray-man_2004': '$_base/bIFp20ZUg3kPOfR5FUuAE5cxhHh.jpg',
  'sub_manga_barakamon_2009': '$_base/33mPuB6UTJkscJxKmcEeruKj0gl.jpg',
};

void main() {
  final root = _findProjectRoot();
  final shards = Directory('${root.path}/akasha-db/shards');
  var fixed = 0;
  var slashFixed = 0;

  for (final f in shards.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final raw = f.readAsStringSync();
    final map = Map<String, dynamic>.from(json.decode(raw) as Map);
    var dirty = false;

    for (final entry in map.entries.toList()) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key;

      final override = _posterByWorkId[workId];
      if (override != null && work['posterPath'] != override) {
        work['posterPath'] = override;
        dirty = true;
        fixed++;
      }

      final poster = work['posterPath']?.toString() ?? '';
      if (poster.contains('/w500//')) {
        work['posterPath'] = poster.replaceAll('/w500//', '/w500/');
        dirty = true;
        slashFixed++;
      }

      map[entry.key] = work;
    }

    if (dirty) {
      f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(map)}\n');
    }
  }

  print('Posters set: $fixed, slash fixed: $slashFixed');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('no pubspec');
}
