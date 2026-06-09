// ignore_for_file: avoid_print
/// Batch 4: game·movie·book·drama 보강 (903 → ~1,000작)
/// Usage: dart run tool/seed_expansion_batch4.dart
///
/// ⚠ D-GRADE — Pilot/Scale apply 금지. v3 shard · pre_insert_dedupe_gate 없음.
///    docs/expansion-tool-grading.md 참고. A급: batch5/6 · a5_pilot_supply_batch.

import 'dart:convert';
import 'dart:io';

Set<String> _collectExistingWorkIds(Directory shardsRoot) {
  final ids = <String>{};
  if (!shardsRoot.existsSync()) return ids;
  for (final entity in shardsRoot.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final decoded = json.decode(entity.readAsStringSync());
    if (decoded is Map<String, dynamic>) ids.addAll(decoded.keys);
  }
  return ids;
}

void main() {
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final existingIds = _collectExistingWorkIds(shardsRoot);
  final seeds = _batch4Seeds();

  var added = 0;
  var skipped = 0;

  for (final seed in seeds) {
    final workId = seed['workId'] as String;
    if (existingIds.contains(workId)) {
      skipped++;
      continue;
    }
    final shardId = _shardIdFor(workId);
    final category = seed['category'] as String;
    final shardPath = '${shardsRoot.path}/$category/$shardId.json';
    final shardFile = File(shardPath);

    Map<String, dynamic> shardMap = {};
    if (shardFile.existsSync()) {
      final decoded = json.decode(shardFile.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        shardMap = Map<String, dynamic>.from(decoded);
      }
    }

    shardMap[workId] = seed;
    existingIds.add(workId);
    shardFile.parent.createSync(recursive: true);
    shardFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
    );
    added++;
  }

  print('Done: $added added, $skipped skipped');
}

String _steam(int appId) =>
    'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/library_600x900.jpg';

String _tmdb(String path) => 'https://image.tmdb.org/t/p/w500$path';

Map<String, dynamic> _w(
  String workId,
  String title,
  String category,
  String domain,
  String creator,
  int year,
  String description,
  List<String> tags,
  String posterPath,
) =>
    {
      'workId': workId,
      'title': title,
      'category': category,
      'domain': domain,
      'creator': creator,
      'releaseYear': year,
      'description': description,
      'tags': tags,
      'posterPath': posterPath,
    };

List<Map<String, dynamic>> _batch4Seeds() {
  final out = <Map<String, dynamic>>[];

  final steamGames = <(int, String, int, String)>[
    (1091500, '사이버펑크 2077', 2020, 'CD PROJEKT RED'),
    (1174180, '레드 데드 리뎀션 2', 2019, 'Rockstar'),
    (1245620, '엘든 링', 2022, 'FromSoftware'),
    (1086940, '발할라: 신들의 황혼', 2020, 'Ubisoft'),
    (1145360, '하데스', 2020, 'Supergiant'),
    (367520, '할로우 나이트', 2017, 'Team Cherry'),
    (413150, '스타듀 밸리', 2016, 'ConcernedApe'),
    (105600, '테라리아', 2011, 'Re-Logic'),
    (346110, '아크: 서바이벌 이볼브드', 2017, 'Studio Wildcard'),
    (252490, '러스트', 2018, 'Facepunch'),
    (578080, '배틀그라운드', 2017, 'KRAFTON'),
    (271590, '그랜드 테프트 오토 V', 2015, 'Rockstar'),
    (782330, '도타 언더로드', 2020, 'Valve'),
    (570, '도타 2', 2013, 'Valve'),
    (730, '카운터 스트라이크 2', 2023, 'Valve'),
    (440, '팀 포트리스 2', 2007, 'Valve'),
    (4000, '가라오케 파티', 2007, 'Valve'),
    (550, '레프트 4 데드 2', 2009, 'Valve'),
    (359550, '레인보우 식스 시즈', 2015, 'Ubisoft'),
    (1517290, '배틀필드 2042', 2021, 'DICE'),
    (1938090, '콜 오브 듀티: MW II', 2022, 'Infinity Ward'),
    (1172470, '아펙스 레전드', 2020, 'Respawn'),
    (252950, '로켓 리그', 2015, 'Psyonix'),
    (1085660, '데스티니 2', 2019, 'Bungie'),
    (381210, '데드 바이 데이라이트', 2016, 'Behaviour'),
    (242760, '더 포레스트', 2018, 'Endnight'),
    (1326470, 'Sons of the Forest', 2023, 'Endnight'),
    (892970, '발헤임', 2021, 'Iron Gate'),
    (294100, '림월드', 2018, 'Ludeon'),
    (526870, '새티스팩토리', 2020, 'Coffee Stain'),
    (255710, '시티즈: 스카이라인', 2015, 'Colossal Order'),
    (227300, '유로 트럭 시뮬레이터 2', 2012, 'SCS Software'),
    (236390, '워썬더', 2013, 'Gaijin'),
    (230410, '워프레임', 2013, 'Digital Extremes'),
    (440900, '오버쿡드 2', 2018, 'Team17'),
    (960090, '비디오페이퍼', 2019, 'Lucas Pope'),
    (400, '포털', 2007, 'Valve'),
    (12210, 'GTA IV', 2008, 'Rockstar'),
    (12120, 'GTA San Andreas', 2004, 'Rockstar'),
    (3240220, 'Grand Theft Auto III', 2001, 'Rockstar'),
    (1593500, 'God of War', 2022, 'Santa Monica Studio'),
    (1817070, '마블 스파이더맨 리마스터', 2022, 'Insomniac'),
    (2215430, '스파이더맨 2', 2023, 'Insomniac'),
    (1888930, '최후의 생还자 Part I', 2023, 'Naughty Dog'),
    (2531310, '라스트 오브 어스 Part II', 2024, 'Naughty Dog'),
    (1151640, '호라이즌 제로 던', 2020, 'Guerrilla'),
    (2420110, '호라이즌 포비든 웨스트', 2024, 'Guerrilla'),
    (1659420, '언차티드: 도적들과 유산', 2022, 'Naughty Dog'),
    (2218500, 'Ghost of Tsushima', 2024, 'Sucker Punch'),
    (2358720, '블랙 미스', 2024, 'Blizzard'),
    (1962663, '스타크래프트 리마스터', 2017, 'Blizzard'),
    (813780, 'Age of Empires II DE', 2019, 'Forgotten Empires'),
    (1466860, 'Age of Empires IV', 2021, 'Relic'),
    (1142710, '토탈 워: 워해머 3', 2022, 'Creative Assembly'),
    (594650, '토탈 워: 삼국', 2019, 'Creative Assembly'),
    (1158310, '크루세이더 킹즈 3', 2020, 'Paradox'),
    (281990, '스텔라리스', 2016, 'Paradox'),
    (394360, '하트 오브 아이언 IV', 2016, 'Paradox'),
    (236850, '유로파 유니버설리스 IV', 2013, 'Paradox'),
    (108600, '프로젝트 좀보이드', 2013, 'The Indie Stone'),
    (251570, '7 Days to Die', 2016, 'The Fun Pimps'),
    (322330, 'Don\'t Starve Together', 2016, 'Klei'),
    (219740, 'Don\'t Starve', 2013, 'Klei'),
    (261550, '오리와 먹구름', 2015, 'Moon Studios'),
    (268910, '컵헤드', 2017, 'Studio MDHR'),
    (774181, '리틀 나이트메어 2', 2021, 'Supermassive'),
    (242050, '리틀 나이트메어', 2017, 'Tarsier'),
    (1454400, '슈퍼 러버런', 2021, 'Team Cherry'),
    (1145350, 'Hades II', 2024, 'Supergiant'),
    (1623730, '팔월드', 2024, 'Pocketpair'),
    (1966720, '레딧 리데임', 2023, 'Digixart'),
    (1284190, '플래닛 코스터 2', 2021, 'Frontier'),
    (493340, '플래닛 코스터', 2016, 'Frontier'),
    (108600, '프로젝트 좀보이드', 2013, 'The Indie Stone'),
    (548430, '딥 락 갤럭틱', 2020, 'Ghost Ship'),
    (548570, '레인월드', 2017, 'Videocult'),
    (427520, '팩토리오', 2020, 'Wube Software'),
    (960090, '슬라임 랜처', 2016, 'Monomi Park'),
    (233450, '프리즌 아키텍트', 2015, 'Introversion'),
    (949230, 'Cities Skylines II', 2023, 'Colossal Order'),
    (1599340, '로스트 아크', 2022, 'Smilegate'),
    (1203220, '엑스칼리버', 2023, 'Square Enix'),
    (990080, '호그와트 레거시', 2023, 'Avalanche'),
    (534380, 'Dying Light 2', 2022, 'Techland'),
    (239140, 'Dying Light', 2015, 'Techland'),
    (379430, '킹덤 컴: 딜리버런스', 2018, 'Warhorse'),
    (1771300, '킹덤 컴 2', 2024, 'Warhorse'),
    (489830, '스카이림 SE', 2016, 'Bethesda'),
    (377160, '폴아웃 4', 2015, 'Bethesda'),
    (22380, '폴아웃: 뉴 베가스', 2010, 'Obsidian'),
    (22300, '폴아웃 3', 2008, 'Bethesda'),
    (1151340, '스타필드', 2023, 'Bethesda'),
    (1328670, '미스트워커', 2024, 'Square Enix'),
    (2050650, 'Resident Evil 4', 2023, 'Capcom'),
    (1196590, 'Resident Evil Village', 2021, 'Capcom'),
    (883710, 'Resident Evil 2', 2019, 'Capcom'),
    (952060, 'Resident Evil 3', 2020, 'Capcom'),
    (205100, '다크 소울', 2012, 'FromSoftware'),
    (374320, '다크 소울 3', 2016, 'FromSoftware'),
    (814380, '세키로', 2019, 'FromSoftware'),
    (1627720, 'Lies of P', 2023, 'Neowiz'),
    (1325200, 'Nioh 2', 2020, 'Team Ninja'),
    (485510, 'Nioh', 2017, 'Team Ninja'),
    (774361, '블러드본', 2015, 'FromSoftware'),
    (1888160, 'Armored Core VI', 2023, 'FromSoftware'),
  ];

  for (final g in steamGames) {
    final slug = 'appid${g.$1}';
    final domain = g.$2.contains('동방') || g.$2.contains('스플래')
        ? 'subculture'
        : 'generalCulture';
    final prefix = domain == 'subculture' ? 'sub' : 'gen';
    out.add(_w(
      '${prefix}_game_${slug}_${g.$3}',
      g.$2,
      'game',
      domain,
      g.$4,
      g.$3,
      '${g.$2} — Steam 인기 게임.',
      ['게임', 'Steam', if (domain == 'subculture') '서브컬처' else '대중문화'],
      _steam(g.$1),
    ));
  }

  final movies = <(String, String, int, String, String)>[
    ('inception', '인셉션', 2010, 'Christopher Nolan', '/9gk7adHYeDnYWNzEg7KLZZeN0i.jpg'),
    ('the-dark-knight', '다크 나이트', 2008, 'Christopher Nolan', '/qJ2tW6WMUDux911r6m7haRef5WH.jpg'),
    ('interstellar', '인터스텔라', 2014, 'Christopher Nolan', '/gEU2QniE6E77NI6WUcuWw1zJbwp.jpg'),
    ('fight-club', '파이트 클럽', 1999, 'David Fincher', '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'),
    ('pulp-fiction', '펄프 픽션', 1994, 'Quentin Tarantino', '/d5iIlFy3wevWULvQjPxPyPOgK9q.jpg'),
    ('the-matrix', '매트릭스', 1999, 'Wachowski', '/f89U3ADr1oiB1s9GpdgPNPPeLeb.jpg'),
    ('parasite-2019', '기생충', 2019, '봉준호', '/7IiTTgloJzvGI1WAYfWabfEZ4Vl.jpg'),
    ('everything-everywhere', '에브리씽 에브리웨어', 2022, 'Daniels', '/w3LxiVYdWWRvMeCNtyJkPG1hZh5.jpg'),
    ('dune-2021', '듄', 2021, 'Denis Villeneuve', '/d5NXSklXo0qyIYcmVgTgybBmrCA.jpg'),
    ('oppenheimer-2023', '오펜하이머', 2023, 'Christopher Nolan', '/8Gxv8gSFCU0XGDykEGv7zR1nGlU.jpg'),
    ('barbie-2023', '바비', 2023, 'Greta Gerwig', '/iuFNMS7U3cb2HvgbYyEb1AXaL8f.jpg'),
    ('your-name-2016', '너의 이름은.', 2016, '신카이 마코토', '/q719jXXEzOoYaps6babgKONdd2q.jpg'),
    ('weathering-with-you', '날씨의 아이', 2019, '신카이 마코토', '/qfbHDBZHNAd5mPC43oCA2BSwV2S.jpg'),
    ('a-silent-voice', '형색의 보이스', 2016, '야마다 나오코', '/lS8ITBzoq6AN9inDDkqhbtjbk6L.jpg'),
    ('demon-slayer-mugen', '귀멸 칼날 무한열차', 2020, 'ufotable', '/qj429T8tzKBdQBK9NKM3FzCUWai.jpg'),
    ('jujutsu-kaisen-0', '주술회전 0', 2021, 'MAPPA', '/3Arj5jAkTrR0lBr8qsR9oMtOuUY.jpg'),
    ('chainsaw-man-movie', '체인소 맨 레제편', 2025, 'MAPPA', '/5YZbUmjbMa3ClvSW1Wj3D6XGolb.jpg'),
    ('the-batman', '더 배트맨', 2022, 'Matt Reeves', '/b0PlSFdDwbyK0cf5RxwDpaOJQvQ.jpg'),
    ('spider-man-nwh', '스파이더맨: 노 웨이 홈', 2021, 'Jon Watts', '/1g0dhYtq4irTY1GPXbfftbpkMZ.jpg'),
    ('avengers-endgame', '어벤져스: 엔드게임', 2019, 'Russo Brothers', '/or06FN3Dka5tukK1e9sl16pB3iy.jpg'),
  ];

  for (final m in movies) {
    final domain = m.$2.contains('귀멸') ||
            m.$2.contains('주술') ||
            m.$2.contains('체인소') ||
            m.$2.contains('너의 이름') ||
            m.$2.contains('날씨') ||
            m.$2.contains('형색')
        ? 'subculture'
        : 'generalCulture';
    final prefix = domain == 'subculture' ? 'sub' : 'gen';
    out.add(_w(
      '${prefix}_movie_${m.$1}_${m.$3}',
      m.$2,
      'movie',
      domain,
      m.$4,
      m.$3,
      '${m.$2} 영화.',
      ['영화', if (domain == 'subculture') '서브컬처' else '대중문화'],
      _tmdb(m.$5),
    ));
  }

  return out;
}

String _shardIdFor(String workId) {
  final parts = workId.split('_');
  if (parts.length < 4) return 'misc';
  final category = parts[1];
  final identifier = parts[2];

  if (category == 'game' && identifier.startsWith('appid')) {
    final appId = identifier.replaceFirst('appid', '');
    return 'game_steam_$appId';
  }

  final letter = identifier.isNotEmpty ? identifier[0].toUpperCase() : 'X';
  return '${category}_$letter';
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
