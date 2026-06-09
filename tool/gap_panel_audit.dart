// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final ids = [
    'wk_000000343', 'wk_000000188', 'wk_000000387', 'wk_000000239',
    'wk_000000325', 'wk_000000194', 'wk_000000354', 'wk_000000257',
    'wk_000000230', 'wk_000000375', 'wk_000000291', 'wk_000000187',
    'wk_000000218', 'wk_000000010', 'wk_000000158', 'wk_000000310', 'wk_000000185',
  ];
  final m = jsonDecode(File('akasha-db/manifest.json').readAsStringSync()) as Map;
  final found = <String, Map>{};
  for (final s in m['shards'] as List) {
    final path = (s as Map)['path'] as String;
    final shard = jsonDecode(File('akasha-db/$path').readAsStringSync()) as Map;
    for (final id in ids) {
      if (shard.containsKey(id)) {
        found[id] = {'path': path, 'work': shard[id] as Map};
      }
    }
  }
  for (final id in ids) {
    final f = found[id];
    if (f == null) {
      print('$id: NOT FOUND');
      continue;
    }
    final w = f['work'] as Map;
    final titles = w['titles'];
    final t = titles is Map ? Map<String, dynamic>.from(titles) : <String, dynamic>{};
    print('$id @ ${f['path']}');
    print('  title: ${w['title']}');
    print('  category: ${w['category']}');
    print('  titles.en: ${t['en'] ?? '-'}');
    print('  titles.ja: ${t['ja'] ?? '-'}');
    print('  titles.zh: ${t['zh'] ?? '-'}');
    print('  titles.romaji: ${t['romaji'] ?? '-'}');
    print('  aliases: ${w['aliases'] ?? []}');
    print('  externalIds: ${w['externalIds'] ?? {}}');
    print('');
  }
}
