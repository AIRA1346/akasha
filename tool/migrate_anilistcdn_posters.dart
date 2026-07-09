// ignore_for_file: avoid_print
// anilistcdn posterPath → TMDB / Open Library / Steam 등으로 교체
//
// Usage:
//   dart run tool/migrate_anilistcdn_posters.dart           # dry-run
//   dart run tool/migrate_anilistcdn_posters.dart --apply
//   dart run tool/migrate_anilistcdn_posters.dart --fetch --apply  # TMDB API (TMDB_API_KEY)
//
// Policy: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)

import 'dart:convert';
import 'dart:io';

import 'poster_url_policy.dart';

const _tmdbImageBase = 'https://image.tmdb.org/t/p/w500';

/// workId slug → TMDB TV id (애니·만화 원작 TV)
const _slugTmdbTv = <String, int>{
  'attack-on-titan': 1429,
  'shingeki-no-kyojin': 1429,
  'angel-beats': 46195,
  'bocchi-the-rock': 204541,
  'bungo-stray-dogs': 65930,
  'black-lagoon': 890,
  'chainsaw-man': 114410,
  'code-geass': 8905,
  'cowboy-bebop': 30991,
  'clannad': 46004,
  'cyberpunk-edgerunners': 105248,
  'dandadan': 240411,
  'dandadan-anime': 240411,
  'demon-slayer': 85937,
  'kimetsu-no-yaiba': 85937,
  'fate-zero': 45939,
  'frieren': 209867,
  'fullmetal-alchemist-brotherhood': 2204,
  'fullmetal-alchemist': 2204,
  'gintama': 57033,
  'hajime-no-ippo': 68287,
  'jujutsu-kaisen': 95479,
  'konosuba': 66361,
  'lycoris-recoil': 204609,
  'made-in-abyss': 73223,
  'mob-psycho-100': 69050,
  'monogatari': 61148,
  'mushoku-tensei': 94663,
  'neon-genesis-evangelion': 9552,
  'noragami': 60732,
  'one-punch-man': 63926,
  'oshi-no-ko': 203737,
  'overlord': 64199,
  'ping-pong': 61530,
  'psycho-pass': 43701,
  'rezero': 67071,
  'rezero-anime': 67071,
  'samurai-champloo': 1176,
  'shield-hero': 83095,
  'slime-anime': 82625,
  'tensura': 82625,
  'spy-x-family': 120089,
  'steinsgate': 26298,
  'trigun': 642,
  'violet-evergarden': 74830,
  'my-hero-academia': 65931,
  'one-piece': 111110,
  'naruto': 46260,
  'bleach': 57243,
  'hunter-x-hunter': 46298,
  'death-note': 37854,
  'tokyo-ghoul': 61374,
  'dr-stone': 83867,
  'kaiju-no-8': 114226,
  'blue-lock': 131041,
  'haikyuu': 60863,
  'tokyo-revengers': 95481,
  'solo-leveling': 127532,
  'vinland-saga': 88800,
  'fire-force': 88046,
  'black-clover': 77236,
  'promised-neverland': 79460,
  'kaguya-sama': 83121,
  'horimiya': 112112,
  'toradora': 31910,
  'mushishi': 30981,
  'parasyte': 60866,
  'pluto': 114547,
  'monster': 56296,
  'slam-dunk': 96316,
  'yu-yu-hakusho': 7468,
  'rurouni-kenshin': 43168,
  'detective-conan': 30983,
  'cardcaptor-sakura': 35790,
  'fruits-basket': 85940,
  'nana': 11062,
  'skip-and-loafer': 203488,
  'sakamoto-days': 241002,
  'undead-unluck': 211079,
  'hells-paradise': 117465,
  'golden-kamuy': 76148,
  'dorohedoro': 93289,
  'beastars': 90937,
  '20th-century-boys': 42671,
  '86-eighty-six': 100565,
  '86-light-novel': 100565,
  'chihayafuru': 42509,
  'march-comes-in-like-a-lion': 68541,
  'shigatsu-wa-kimi-no-uso': 61663,
  'oregairu': 65676,
  'nisekoi': 60859,
  'quintessential-quintuplets': 84669,
  'tower-of-god': 96346,
  'real': 0, // skip
  'goodnight-punpun': 0,
  'vagabond': 0,
  'berserk': 0,
  'ao-ashi': 116747,
  'blue-period': 131400,
  'gabriel-dropout': 70594,
  'fairy-tail': 15260,
  'crayon-shin-chan': 65733,
  'kingdom': 96664,
};

/// slug → TMDB movie id
const _slugTmdbMovie = <String, int>{
  'silent-voice': 372754,
  'weathering-with-you': 568160,
  'your-name': 372058,
  'my-neighbor-totoro': 8392,
};

/// workId → 직접 URL (게임·예외)
const _workOverrides = <String, String>{
  'sub_game_blue-archive_2021':
      'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/3511790/library_600x900.jpg',
  'sub_game_nikke_2022':
      'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/2358720/library_600x900.jpg',
};

/// 라이트노벨 slug → Open Library ISBN (L 커버)
const _bookIsbn = <String, String>{
  '86-light-novel': '9784040681412',
  'classroom-of-the-elite': '9784041015025',
  'konosuba-light-novel': '9784041015780',
  'monogatari-light-novel': '9784044740626',
  'mushoku-tensei-light-novel': '9784040685373',
  'no-game-no-life': '9784048667951',
  'overlord-light-novel': '9784040661637',
  'rezero-light-novel': '9784040701104',
  'slime-light-novel': '9784040702279',
  'spice-and-wolf': '9784048862579',
  'sword-art-online': '9784048869004',
};

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final fetch = args.contains('--fetch');
  final root = _findProjectRoot();
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  final tmdbPosterCache = <int, String>{};
  if (fetch) {
    await _warmTmdbPosterCache(tmdbPosterCache);
  } else {
    _loadCachedTmdbPosters(tmdbPosterCache);
  }

  var changed = 0;
  var unresolved = <String>[];

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    var dirty = false;
    final content = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
    final updated = <String, dynamic>{};

    for (final entry in content.entries) {
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key;
      final poster = work['posterPath']?.toString() ?? '';

      if (!poster.toLowerCase().contains('anilistcdn')) {
        updated[entry.key] = work;
        continue;
      }

      final replacement = _resolvePoster(
        workId: workId,
        work: work,
        tmdbPosterCache: tmdbPosterCache,
      );

      if (replacement == null) {
        unresolved.add(workId);
        updated[entry.key] = work;
        continue;
      } else if (replacement != poster) {
        work['posterPath'] = replacement;
        final err = validatePosterUrlForShard(replacement);
        if (err != null) {
          print('WARN $workId: $err — keeping replacement anyway');
        }
        changed++;
        dirty = true;
      }
      updated[entry.key] = work;
    }

    if (dirty) {
      if (apply) {
        _writeJson(f.path, updated);
      }
    }
  }

  print('Replaced: $changed, skipped (no replacement): ${unresolved.length}');
  if (unresolved.isNotEmpty) {
    print('Unresolved (${unresolved.length}):');
    for (final id in unresolved) {
      print('  - $id');
    }
  }
  if (!apply) {
    print('\nDry-run only. Pass --apply to write shards.');
  }
  if (fetch && tmdbPosterCache.isNotEmpty) {
    _saveTmdbPosterCache(root, tmdbPosterCache);
  }
}

String? _resolvePoster({
  required String workId,
  required Map<String, dynamic> work,
  required Map<int, String> tmdbPosterCache,
}) {
  final override = _workOverrides[workId];
  if (override != null) return override;

  final slug = _slugFromWorkId(workId);
  final category = work['category']?.toString() ?? '';

  if (category == 'book') {
    final isbn = _bookIsbn[slug];
    if (isbn != null) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
    }
    return null;
  }

  final movieId = _slugTmdbMovie[slug];
  if (movieId != null && movieId > 0) {
    final path = tmdbPosterCache[movieId];
    if (path != null) return '$_tmdbImageBase$path';
  }

  final tvId = _slugTmdbTv[slug];
  if (tvId != null && tvId > 0) {
    final path = tmdbPosterCache[tvId];
    if (path != null) return '$_tmdbImageBase$path';
  }

  return null;
}

String _slugFromWorkId(String workId) {
  final parts = workId.split('_');
  if (parts.length >= 4) return parts[2];
  return workId;
}

Future<void> _warmTmdbPosterCache(Map<int, String> cache) async {
  _loadCachedTmdbPosters(cache);

  final apiKey = Platform.environment['TMDB_API_KEY'] ?? '';
  final tvIds = _slugTmdbTv.values.where((id) => id > 0).toSet();
  final movieIds = _slugTmdbMovie.values.toSet();

  final client = HttpClient();
  for (final id in tvIds) {
    if (cache.containsKey(id)) continue;
    if (apiKey.isNotEmpty) {
      await _fetchTmdbApiPoster(client, apiKey, 'tv', id, cache);
    } else {
      await _scrapeTmdbPoster(client, 'tv', id, cache);
    }
  }
  for (final id in movieIds) {
    if (cache.containsKey(id)) continue;
    if (apiKey.isNotEmpty) {
      await _fetchTmdbApiPoster(client, apiKey, 'movie', id, cache);
    } else {
      await _scrapeTmdbPoster(client, 'movie', id, cache);
    }
  }
  client.close();
  print('TMDB cache warmed: ${cache.length} posters');
}

Future<void> _fetchTmdbApiPoster(
  HttpClient client,
  String apiKey,
  String type,
  int id,
  Map<int, String> cache,
) async {
  final uri = Uri.parse(
    'https://api.themoviedb.org/3/$type/$id?api_key=$apiKey',
  );
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) return;
    final body = await response.transform(utf8.decoder).join();
    final decoded = json.decode(body) as Map<String, dynamic>;
    final path = decoded['poster_path']?.toString();
    if (path != null && path.isNotEmpty) cache[id] = path;
    await Future<void>.delayed(const Duration(milliseconds: 80));
  } catch (e) {
    print('TMDB API failed for $type/$id: $e');
  }
}

final _tmdbImagePatterns = [
  RegExp(
    r'property="og:image"\s+content="https://media\.themoviedb\.org/t/p/w\d+(/[^"]+)"',
  ),
  RegExp(
    r'"image":"https://image\.tmdb\.org/t/p/w\d+(/[^"]+\.jpg)"',
  ),
];

Future<void> _scrapeTmdbPoster(
  HttpClient client,
  String type,
  int id,
  Map<int, String> cache,
) async {
  final uri = Uri.parse('https://www.themoviedb.org/$type/$id');
  try {
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'akasha-poster-migrate/1.0');
    final response = await request.close();
    if (response.statusCode != 200) {
      print('SCRAPE FAIL $type/$id: HTTP ${response.statusCode}');
      return;
    }
    final html = await response.transform(utf8.decoder).join();
    RegExpMatch? match;
    for (final pattern in _tmdbImagePatterns) {
      match = pattern.firstMatch(html);
      if (match != null) break;
    }
    if (match != null) {
      final path = match.group(1)!;
      if (!path.contains(r'$')) cache[id] = path;
      print('SCRAPE OK $type/$id');
    } else {
      print('SCRAPE MISS $type/$id');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  } catch (e) {
    print('SCRAPE ERR $type/$id: $e');
  }
}

void _loadCachedTmdbPosters(Map<int, String> cache) {
  final file = File('akasha-db/tmdb_poster_cache.json');
  if (!file.existsSync()) return;
  try {
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is Map) {
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString());
        final path = value?.toString();
        if (id != null && path != null && path.isNotEmpty) {
          cache[id] = path;
        }
      });
    }
  } catch (e) {
    print('Failed to load tmdb_poster_cache.json: $e');
  }
}

void _saveTmdbPosterCache(Directory root, Map<int, String> cache) {
  final sorted = <String, String>{};
  for (final entry in cache.entries) {
    sorted[entry.key.toString()] = entry.value;
  }
  final keys = sorted.keys.toList()..sort();
  final ordered = {for (final k in keys) k: sorted[k]!};
  final file = File('${root.path}/akasha-db/tmdb_poster_cache.json');
  final encoder = const JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(ordered)}\n');
  print('Saved ${file.path}');
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

void _writeJson(String path, Map<String, dynamic> data) {
  final encoder = const JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(data)}\n');
}
