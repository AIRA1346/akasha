// ignore_for_file: avoid_print
// Archived poster-provider counter from the pre-Fact-only registry.
import 'dart:convert';
import 'dart:io';

void main() {
  final byHost = <String, int>{};
  var anilist = 0;

  for (final f in Directory('akasha-db/shards').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final m = json.decode(f.readAsStringSync()) as Map;
    for (final e in m.entries) {
      final p = (e.value as Map)['posterPath']?.toString() ?? '';
      if (p.isEmpty) {
        byHost['(none)'] = (byHost['(none)'] ?? 0) + 1;
        continue;
      }
      if (p.contains('anilistcdn')) anilist++;
      String bucket = 'other';
      if (p.contains('image.tmdb.org')) {
        bucket = 'tmdb';
      } else if (p.contains('openlibrary')) {
        bucket = 'openlibrary';
      } else if (p.contains('steamstatic') || p.contains('steamcdn')) {
        bucket = 'steam';
      } else if (p.contains('igdb.com')) {
        bucket = 'igdb';
      }
      byHost[bucket] = (byHost[bucket] ?? 0) + 1;
    }
  }

  print('anilistcdn: $anilist');
  print('poster buckets: $byHost');
}
