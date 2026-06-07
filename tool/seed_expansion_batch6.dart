// ignore_for_file: avoid_print
/// Batch 6: AM2 애니·만화 엄선 추가 (+40작 목표)
/// Policy: [docs/catalog-expansion-plan.md](../docs/catalog-expansion-plan.md)
///
/// Usage:
///   dart run tool/seed_expansion_batch6.dart --fetch-posters --apply

import 'dart:convert';
import 'dart:io';

import 'poster_url_policy.dart';

const _tmdbImageBase = 'https://image.tmdb.org/t/p/w500';
const _posterCacheFile = 'akasha-db/tmdb_poster_cache.json';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final fetchPosters = args.contains('--fetch-posters');
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final existingIds = _collectExistingWorkIds(shardsRoot);
  final posterCache = _loadPosterCache(projectRoot);

  if (fetchPosters) {
    await _warmPosterCacheForSeeds(posterCache, _batch6Seeds());
    _savePosterCache(projectRoot, posterCache);
  }

  var added = 0;
  var skipped = 0;
  var noPoster = 0;

  for (final seed in _batch6Seeds()) {
    final workId = seed['workId'] as String;
    if (existingIds.contains(workId)) {
      skipped++;
      continue;
    }

    final entry = Map<String, dynamic>.from(seed);
    entry.remove('_tmdbTvId');

    final tmdbId = seed['_tmdbTvId'] as int?;
    final poster = _resolvePoster(tmdbId, posterCache, seed);
    if (poster != null) {
      entry['posterPath'] = poster;
      final err = validatePosterUrlForShard(poster);
      if (err != null) print('WARN $workId poster: $err');
    } else {
      entry.remove('posterPath');
      noPoster++;
      print('NOTE $workId: no poster (placeholder)');
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

    shardMap[workId] = entry;
    existingIds.add(workId);

    if (apply) {
      shardFile.parent.createSync(recursive: true);
      shardFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
      );
    }
    added++;
  }

  print('Done: $added added, $skipped skipped, $noPoster without poster');
  if (!apply) print('Dry-run. Pass --apply to write shards.');
}

String? _resolvePoster(
  int? tmdbTvId,
  Map<int, String> cache,
  Map<String, dynamic> seed,
) {
  if (seed['posterPath'] != null) return seed['posterPath'] as String;
  if (tmdbTvId == null || tmdbTvId <= 0) return null;
  final path = cache[tmdbTvId];
  if (path == null || path.isEmpty) return null;
  return '$_tmdbImageBase$path';
}

Map<int, String> _loadPosterCache(Directory projectRoot) {
  final file = File('${projectRoot.path}/$_posterCacheFile');
  if (!file.existsSync()) return {};
  final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
}

void _savePosterCache(Directory projectRoot, Map<int, String> cache) {
  final sorted = Map.fromEntries(
    cache.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  final file = File('${projectRoot.path}/$_posterCacheFile');
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted.map((k, v) => MapEntry('$k', v)))}\n',
  );
}

Future<void> _warmPosterCacheForSeeds(
  Map<int, String> cache,
  List<Map<String, dynamic>> seeds,
) async {
  final ids = <int>{};
  for (final s in seeds) {
    final id = s['_tmdbTvId'] as int?;
    if (id != null && id > 0) ids.add(id);
  }
  final client = HttpClient();
  for (final id in ids) {
    if (cache.containsKey(id)) continue;
    await _scrapeTmdbPoster(client, 'tv', id, cache);
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  client.close();
  print('Poster cache: ${cache.length} entries');
}

Future<void> _scrapeTmdbPoster(
  HttpClient client,
  String type,
  int id,
  Map<int, String> cache,
) async {
  for (final mediaType in [type, 'tv', 'movie']) {
    final uri = Uri.parse('https://www.themoviedb.org/$mediaType/$id');
    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'AkashaRegistryBuilder/1.0');
      final response = await request.close();
      if (response.statusCode != 200) continue;
      final html = await response.transform(utf8.decoder).join();
      for (final pattern in [
        RegExp(
          r'property="og:image" content="https://media\.themoviedb\.org/t/p/w500([^"]+)"',
        ),
        RegExp(
          r'property="og:image" content="https://image\.tmdb\.org/t/p/w500([^"]+)"',
        ),
        RegExp(r'"poster_path":"(/[^"]+)"'),
      ]) {
        final m = pattern.firstMatch(html);
        if (m == null) continue;
        var path = m.group(1)!;
        if (!path.startsWith('/')) path = '/$path';
        cache[id] = path;
        return;
      }
    } catch (_) {}
  }
}

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

String _shardIdFor(String workId) {
  final parts = workId.split('_');
  if (parts.length < 4) return 'misc';
  final category = parts[1];
  final identifier = parts[2];
  final letter = identifier.isNotEmpty ? identifier[0].toUpperCase() : 'X';
  return '${category}_$letter';
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}

Map<String, dynamic> _entry({
  required String workId,
  required String titleKo,
  required String titleEn,
  required String titleJa,
  String? romaji,
  required String category,
  required String creator,
  required int year,
  required String description,
  required List<String> tags,
  List<Map<String, dynamic>>? seasons,
  int? tmdbTvId,
  List<String>? aliases,
}) {
  final titles = <String, String>{
    'ko': titleKo,
    'en': titleEn,
    'ja': titleJa,
  };
  if (romaji != null) titles['romaji'] = romaji;

  final extensions = <String, dynamic>{'posterSource': 'tmdb'};
  if (seasons != null && seasons.isNotEmpty) {
    extensions['seasons'] = seasons;
    extensions['latestSeason'] = seasons.last['label'];
  }

  return {
    'workId': workId,
    'title': titleKo,
    'titles': titles,
    if (aliases != null) 'aliases': aliases,
    'category': category,
    'domain': 'subculture',
    'creator': creator,
    'releaseYear': year,
    'description': description,
    'tags': tags,
    'extensions': extensions,
    '_tmdbTvId': tmdbTvId ?? 0,
  };
}

List<Map<String, dynamic>> _batch6Seeds() => [
      ..._animationSeeds(),
      ..._mangaSeeds(),
    ];

List<Map<String, dynamic>> _animationSeeds() => [
      _entry(
        workId: 'sub_animation_jojo-bizarre-adventure_2012',
        titleKo: '죠죠의 기묘한 모험',
        titleEn: 'JoJo\'s Bizarre Adventure',
        titleJa: 'ジョジョの奇妙な冒険',
        category: 'animation',
        creator: '아라키 히로히코',
        year: 2012,
        description:
            '죠스타 가문과 디오의 인연이 이어지며 세대를 넘어 전개되는 '
            '독특한 스탠드 배틀 액션.',
        tags: ['액션', '초능력', '모험', '다크'],
        seasons: [
          {'label': '1~6부', 'year': 2012, 'episodes': 190},
        ],
        tmdbTvId: 46393,
      ),
      _entry(
        workId: 'sub_animation_hunter-x-hunter_2011',
        titleKo: '헌터×헌터',
        titleEn: 'Hunter x Hunter',
        titleJa: 'ハンター×ハンター',
        category: 'animation',
        creator: '토가시 요시히로',
        year: 2011,
        description:
            '헌터 시험에 도전하는 곤이 아버지를 찾으며 겪는 '
            '모험과 넨 배틀 이야기.',
        tags: ['액션', '모험', '판타지', '우정'],
        seasons: [
          {'label': '2011판', 'year': 2011, 'episodes': 148},
        ],
        tmdbTvId: 46298,
      ),
      _entry(
        workId: 'sub_animation_bleach_2004',
        titleKo: '블리치',
        titleEn: 'Bleach',
        titleJa: 'BLEACH',
        category: 'animation',
        creator: '쿠보 타이토',
        year: 2004,
        description:
            '소울 소사 이치고가 사신의 힘으로 호로와 싸우며 '
            '영혼의 세계를 지키는 액션.',
        tags: ['액션', '초자연', '사신', '성장'],
        seasons: [
          {'label': '1기', 'year': 2004, 'episodes': 366},
          {'label': '천년혈전', 'year': 2022, 'episodes': 26},
        ],
        tmdbTvId: 30936,
      ),
      _entry(
        workId: 'sub_animation_one-piece-anime_1999',
        titleKo: '원피스',
        titleEn: 'One Piece',
        titleJa: 'ONE PIECE',
        category: 'animation',
        creator: '오다 에이치로',
        year: 1999,
        description:
            '루피와 밀짚모자 해적단이 위대한 항로를 항해하며 '
            '원피스를 찾아가는 대장정.',
        tags: ['모험', '액션', '해적', '우정'],
        seasons: [
          {'label': 'TV', 'year': 1999, 'episodes': 1100},
        ],
        tmdbTvId: 37854,
      ),
      _entry(
        workId: 'sub_animation_naruto_2002',
        titleKo: '나루토',
        titleEn: 'Naruto',
        titleJa: 'NARUTO',
        category: 'animation',
        creator: '키시모토 마사시',
        year: 2002,
        description:
            '닌자 호카게를 꿈꾸는 나루토가 동료와 함께 '
            '수행과 전투를 겪으며 성장하는 이야기.',
        tags: ['닌자', '액션', '성장', '우정'],
        seasons: [
          {'label': '1부', 'year': 2002, 'episodes': 220},
        ],
        tmdbTvId: 46260,
      ),
      _entry(
        workId: 'sub_animation_death-note_2006',
        titleKo: '데스노트',
        titleEn: 'Death Note',
        titleJa: 'DEATH NOTE',
        category: 'animation',
        creator: '오바 타케노부',
        year: 2006,
        description:
            '데스노트를 손에 넣은 야가미 라이토와 탐정 L의 '
            '치열한 지능전을 그린 스릴러.',
        tags: ['스릴러', '미스터리', '초자연', '심리'],
        seasons: [
          {'label': '1기', 'year': 2006, 'episodes': 37},
        ],
        tmdbTvId: 13916,
      ),
      _entry(
        workId: 'sub_animation_tokyo-ghoul_2014',
        titleKo: '도쿄 구울',
        titleEn: 'Tokyo Ghoul',
        titleJa: '東京喰種トーキョーグール',
        category: 'animation',
        creator: '이시다 슈',
        year: 2014,
        description:
            '반구울이 된 칸키 켄이 인간과 구울 사이에서 '
            '정체성과 생존을 고민하는 다크 액션.',
        tags: ['다크', '액션', '호러', '정체성'],
        seasons: [
          {'label': '1기', 'year': 2014, 'episodes': 12},
          {'label': ':re', 'year': 2018, 'episodes': 24},
        ],
        tmdbTvId: 61374,
      ),
      _entry(
        workId: 'sub_animation_parasyte_2014',
        titleKo: '기생수',
        titleEn: 'Parasyte: The Maxim',
        titleJa: '寄生獣 セイの格率',
        category: 'animation',
        creator: '이와와키 히토시',
        year: 2014,
        description:
            '손에 기생한 미치가 신이치와 공존하며 '
            '기생생물과 맞서는 SF 호러 액션.',
        tags: ['SF', '호러', '액션', '공존'],
        seasons: [
          {'label': '1기', 'year': 2014, 'episodes': 24},
        ],
        tmdbTvId: 62538,
      ),
      _entry(
        workId: 'sub_animation_toradora_2008',
        titleKo: '토라도라!',
        titleEn: 'Toradora!',
        titleJa: 'とらドラ！',
        category: 'animation',
        creator: '타케마야 야스코',
        year: 2008,
        description:
            '강호동 같은 소녀 아이스와 작은 소년 류지가 '
            '짝사랑을 도우며 사랑을 배우는 로맨스 코미디.',
        tags: ['로맨스', '코미디', '학원', '성장'],
        seasons: [
          {'label': '1기', 'year': 2008, 'episodes': 25},
        ],
        tmdbTvId: 65334,
      ),
      _entry(
        workId: 'sub_animation_shigatsu-wa-kimi-no-uso_2011',
        titleKo: '4월은 너의 거짓말',
        titleEn: 'Your Lie in April',
        titleJa: '四月は君の嘘',
        category: 'animation',
        creator: '아라키 코세이',
        year: 2014,
        description:
            '피아노를 떠났던 코세이가 바이올리니스트 카오리를 '
            '만나 음악과 상처를 치유하는 청춘 드라마.',
        tags: ['음악', '청춘', '로맨스', '감동'],
        seasons: [
          {'label': '1기', 'year': 2014, 'episodes': 22},
        ],
        tmdbTvId: 61677,
      ),
      _entry(
        workId: 'sub_animation_golden-kamuy_2018',
        titleKo: '골든 카무이',
        titleEn: 'Golden Kamuy',
        titleJa: 'ゴールデンカムイ',
        category: 'animation',
        creator: '야기 노리코',
        year: 2018,
        description:
            '전쟁에서 돌아온 사찌와 아이누 소년 아시리파가 '
            '황금 보물을 찾아 홋카이도를 가로지르는 모험.',
        tags: ['모험', '역사', '액션', '코미디'],
        seasons: [
          {'label': '1기', 'year': 2018, 'episodes': 12},
          {'label': '2기', 'year': 2018, 'episodes': 12},
          {'label': '3기', 'year': 2021, 'episodes': 12},
          {'label': '4기', 'year': 2023, 'episodes': 13},
        ],
        tmdbTvId: 74061,
      ),
      _entry(
        workId: 'sub_animation_beastars_2019',
        titleKo: 'BEASTARS',
        titleEn: 'BEASTARS',
        titleJa: 'BEASTARS',
        category: 'animation',
        creator: '이토 파루',
        year: 2019,
        description:
            '육식·초식 동물이 공존하는 학교에서 늑대 레고시가 '
            '알마와 사회적 갈등을 헤쳐 나가는 이야기.',
        tags: ['드라마', '학원', '로맨스', '사회'],
        seasons: [
          {'label': '1기', 'year': 2019, 'episodes': 12},
          {'label': '2기', 'year': 2021, 'episodes': 12},
          {'label': '3기', 'year': 2024, 'episodes': 12},
        ],
        tmdbTvId: 90937,
      ),
      _entry(
        workId: 'sub_animation_gurren-lagann_2007',
        titleKo: '천원돌파 그렌라간',
        titleEn: 'Gurren Lagann',
        titleJa: '天元突破グレンラガン',
        category: 'animation',
        creator: '가이낙스',
        year: 2007,
        description:
            '지하 마을에서 시작한 시몬과 카미나가 '
            '거대 로봇으로 하늘을 향해 돌파하는 SF 액션.',
        tags: ['SF', '로봇', '액션', '열혈'],
        seasons: [
          {'label': '1기', 'year': 2007, 'episodes': 27},
        ],
        tmdbTvId: 6999,
      ),
      _entry(
        workId: 'sub_animation_kill-la-kill_2013',
        titleKo: '킬 라 킬',
        titleEn: 'Kill la Kill',
        titleJa: 'キルラキル',
        category: 'animation',
        creator: '트리거',
        year: 2013,
        description:
            '전투복을 입은 류코가 학원 지배 체제에 맞서 '
            '복수와 진실을 쫓는 과장된 액션.',
        tags: ['액션', '코미디', '학원', '복수'],
        seasons: [
          {'label': '1기', 'year': 2013, 'episodes': 24},
        ],
        tmdbTvId: 51663,
      ),
      _entry(
        workId: 'sub_animation_no-game-no-life_2014',
        titleKo: '노 게임 노 라이프',
        titleEn: 'No Game No Life',
        titleJa: 'ノーゲーム・ノーライフ',
        category: 'animation',
        creator: '카무라 유우',
        year: 2014,
        description:
            '게임만이 특기인 남매가 이세계 디스보드에서 '
            '모든 분쟁을 게임으로 해결하는 판타지.',
        tags: ['판타지', '게임', '이세계', '코미디'],
        seasons: [
          {'label': '1기', 'year': 2014, 'episodes': 12},
        ],
        tmdbTvId: 61620,
      ),
      _entry(
        workId: 'sub_animation_log-horizon_2013',
        titleKo: '로그 호라이즌',
        titleEn: 'Log Horizon',
        titleJa: 'ログ・ホライズン',
        category: 'animation',
        creator: '마메타와 마모루',
        year: 2013,
        description:
            'MMORPG에 갇힌 플레이어들이 세계 규칙을 분석하며 '
            '새 사회를 만들어가는 이세계 드라마.',
        tags: ['이세계', '게임', '전략', '판타지'],
        seasons: [
          {'label': '1기', 'year': 2013, 'episodes': 25},
          {'label': '2기', 'year': 2014, 'episodes': 25},
        ],
        tmdbTvId: 57706,
      ),
      _entry(
        workId: 'sub_animation_tokyo-revengers_2021',
        titleKo: '도쿄 리벤저스',
        titleEn: 'Tokyo Revengers',
        titleJa: '東京卍リベンジャーズ',
        category: 'animation',
        creator: '와카이 켄',
        year: 2021,
        description:
            '한타케 타케미치가 과거로 돌아가 양아치 조직과 '
            '운명을 바꾸려는 시간여행 액션.',
        tags: ['액션', '시간여행', '조직', '청춘'],
        seasons: [
          {'label': '1기', 'year': 2021, 'episodes': 24},
          {'label': '2기', 'year': 2023, 'episodes': 13},
        ],
        tmdbTvId: 95481,
      ),
      _entry(
        workId: 'sub_animation_ranking-of-kings_2021',
        titleKo: '왕의 랭킹',
        titleEn: 'Ranking of Kings',
        titleJa: '王様ランキング',
        category: 'animation',
        creator: '토키타 소스케',
        year: 2021,
        description:
            '작고 약해 보이는 보지 왕자 보지가 '
            '동료와 함께 성장하며 왕이 되어가는 판타지.',
        tags: ['판타지', '성장', '모험', '감동'],
        seasons: [
          {'label': '1기', 'year': 2021, 'episodes': 23},
          {'label': '2기', 'year': 2023, 'episodes': 12},
        ],
        tmdbTvId: 99557,
      ),
      _entry(
        workId: 'sub_animation_vinland-saga_2019',
        titleKo: '빈란드 사가',
        titleEn: 'Vinland Saga',
        titleJa: 'ヴィンランド・サガ',
        category: 'animation',
        creator: '유키마쓰 신야',
        year: 2019,
        description:
            '아이슬란드의 복수를 꿈꾸던 토르핀이 전쟁과 '
            '삶의 의미를 마주하며 성장하는 역사 드라마.',
        tags: ['역사', '액션', '복수', '성장'],
        seasons: [
          {'label': '1기', 'year': 2019, 'episodes': 24},
          {'label': '2기', 'year': 2023, 'episodes': 24},
        ],
        tmdbTvId: 37606,
      ),
      _entry(
        workId: 'sub_animation_kingdom_2012',
        titleKo: '킹덤',
        titleEn: 'Kingdom',
        titleJa: 'キングダム',
        category: 'animation',
        creator: '하라 야스히사',
        year: 2012,
        description:
            '전국시대를 배경으로 신이 왕국 통일을 꿈꾸며 '
            '전장에서 성장하는 소년의 이야기.',
        tags: ['역사', '전쟁', '성장', '액션'],
        seasons: [
          {'label': '1~5기', 'year': 2012, 'episodes': 120},
        ],
        tmdbTvId: 72408,
      ),
    ];

List<Map<String, dynamic>> _mangaSeeds() => [
      _entry(
        workId: 'sub_manga_dragon-ball_1984',
        titleKo: '드래곤볼',
        titleEn: 'Dragon Ball',
        titleJa: 'ドラゴンボール',
        category: 'manga',
        creator: '토리야마 아키라',
        year: 1984,
        description:
            '손오공이 드래곤볼을 모으며 성장하고 '
            '강적과 맞서는 액션 모험 만화.',
        tags: ['액션', '모험', '무술', '코미디'],
        tmdbTvId: 30979,
      ),
      _entry(
        workId: 'sub_manga_jojo-bizarre-adventure_1987',
        titleKo: '죠죠의 기묘한 모험',
        titleEn: 'JoJo\'s Bizarre Adventure',
        titleJa: 'ジョジョの奇妙な冒険',
        category: 'manga',
        creator: '아라키 히로히코',
        year: 1987,
        description:
            '죠스타 가문과 디오의 대립이 세대를 넘어 이어지는 '
            '스탠드 배틀 액션 만화.',
        tags: ['액션', '초능력', '모험', '다크'],
        tmdbTvId: 46393,
      ),
      _entry(
        workId: 'sub_manga_gto_1997',
        titleKo: 'GTO',
        titleEn: 'Great Teacher Onizuka',
        titleJa: 'GTO',
        category: 'manga',
        creator: '후지이 카즈히로',
        year: 1997,
        description:
            '전 양아치 오니즈카가 교사가 되어 문제 학급을 '
            '때로는 거칠게, 때로는 따뜻하게 이끄는 이야기.',
        tags: ['학원', '코미디', '성장', '교육'],
        tmdbTvId: 42701,
      ),
      _entry(
        workId: 'sub_manga_ranma-half_1987',
        titleKo: '란마 1/2',
        titleEn: 'Ranma ½',
        titleJa: 'らんま1/2',
        category: 'manga',
        creator: '타카하시 루미코',
        year: 1987,
        description:
            '물에 닿으면 성별이 바뀌는 란마를 둘러싼 '
            '무술 도장과 연애가 뒤엉킨 코미디.',
        tags: ['코미디', '무술', '로맨스', '판타지'],
        tmdbTvId: 2607,
      ),
      _entry(
        workId: 'sub_manga_doraemon_1969',
        titleKo: '도라에몽',
        titleEn: 'Doraemon',
        titleJa: 'ドラえもん',
        category: 'manga',
        creator: '후지코 F. 후지오',
        year: 1969,
        description:
            '미래에서 온 고양이 로봇 도라에몽이 '
            '노진구를 도우며 겪는 일상과 모험.',
        tags: ['코미디', 'SF', '가족', '일상'],
        tmdbTvId: 65751,
      ),
      _entry(
        workId: 'sub_manga_made-in-abyss_2012',
        titleKo: '메이드 인 어비스',
        titleEn: 'Made in Abyss',
        titleJa: 'メイドインアビス',
        category: 'manga',
        creator: '츠쿠시 아키히토',
        year: 2012,
        description:
            '거대 구덩이 어비스를 탐험하는 리코와 레그가 '
            '미지의 세계와 저주를 마주하는 다크 판타지.',
        tags: ['판타지', '모험', '다크', '탐험'],
        tmdbTvId: 74112,
      ),
      _entry(
        workId: 'sub_manga_goblin-slayer_2016',
        titleKo: '고블린 슬레이어',
        titleEn: 'Goblin Slayer',
        titleJa: 'ゴブリンスレイヤー',
        category: 'manga',
        creator: '카가유 카우스',
        year: 2016,
        description:
            '고블린만을 죽이는 전사와 파티가 던전에서 '
            '생존과 복수를 이어가는 다크 판타지.',
        tags: ['판타지', '다크', '액션', '던전'],
        tmdbTvId: 82307,
      ),
      _entry(
        workId: 'sub_manga_overlord_2012',
        titleKo: '오버로드',
        titleEn: 'Overlord',
        titleJa: 'オーバーロード',
        category: 'manga',
        creator: '마루야마 쿠가네',
        year: 2012,
        description:
            '게임이 끝나지 않은 세계에 남은 모모onga가 '
            '언데드 마왕으로 군주가 되어가는 이세계 판타지.',
        tags: ['이세계', '판타지', '액션', '전략'],
        tmdbTvId: 64199,
      ),
      _entry(
        workId: 'sub_manga_konosuba_2014',
        titleKo: '이 멋진 세계에 축복을!',
        titleEn: 'KonoSuba',
        titleJa: 'この素晴らしい世界に祝福を！',
        category: 'manga',
        creator: '아카츠키 나츠메',
        year: 2014,
        description:
            '카즈마와 개그 넘치는 파티가 이세계에서 '
            '모험과 빚을 떠안는 코미디 판타지.',
        tags: ['이세계', '코미디', '판타지', '파티'],
        tmdbTvId: 70864,
      ),
      _entry(
        workId: 'sub_manga_seraph-of-the-end_2012',
        titleKo: '종말의 세라프',
        titleEn: 'Seraph of the End',
        titleJa: '終わりのセラフ',
        category: 'manga',
        creator: '카가미 타카히로',
        year: 2012,
        description:
            '바이러스로 인류가 사라진 뒤 뱀파이어와 싸우는 '
            '유우와 동료들의 다크 액션.',
        tags: ['다크', '액션', '뱀파이어', 'SF'],
        tmdbTvId: 62444,
      ),
      _entry(
        workId: 'sub_manga_fairy-tail-100-years-quest_2018',
        titleKo: '페어리 테일 100년 퀘스트',
        titleEn: 'Fairy Tail: 100 Years Quest',
        titleJa: 'FAIRY TAIL 100年クエスト',
        category: 'manga',
        creator: '마시마 히로',
        year: 2018,
        description:
            '나츠 일행이 백년 퀘스트를 수행하며 '
            '새로운 적과 마법 대륙을 마주하는 후속 모험.',
        tags: ['판타지', '마법', '모험', '우정'],
        tmdbTvId: 83121,
      ),
      _entry(
        workId: 'sub_manga_ascendance-of-a-bookworm_2013',
        titleKo: '책벌레의 하극상',
        titleEn: 'Ascendance of a Bookworm',
        titleJa: '本好きの下剋上',
        category: 'manga',
        creator: '미나츠키 미즈카',
        year: 2013,
        description:
            '책을 사랑한 소녀가 이세계 귀족 아기로 환생해 '
            '인쇄와 지식을 퍼뜨리려는 판타지.',
        tags: ['이세계', '판타지', '성장', '책'],
        tmdbTvId: 94664,
      ),
      _entry(
        workId: 'sub_manga_edens-zero_2018',
        titleKo: '에덴스 제로',
        titleEn: 'Edens Zero',
        titleJa: 'EDENS ZERO',
        category: 'manga',
        creator: '마시마 히로',
        year: 2018,
        description:
            '시키가 에덴스 제로 호를 타고 우주를 떠돌며 '
            '마블리와 친구들을 찾는 우주 모험.',
        tags: ['SF', '모험', '우주', '우정'],
        tmdbTvId: 97525,
      ),
      _entry(
        workId: 'sub_manga_captain-tsubasa_1981',
        titleKo: '캡틴 츠바사',
        titleEn: 'Captain Tsubasa',
        titleJa: 'キャプテン翼',
        category: 'manga',
        creator: '타카하시 요이치',
        year: 1981,
        description:
            '오자와 츠바사가 드리블과 슈팅으로 '
            '세계를 향해 성장하는 축구 만화.',
        tags: ['스포츠', '축구', '성장', '청춘'],
        tmdbTvId: 28248,
      ),
      _entry(
        workId: 'sub_manga_saint-seiya_1985',
        titleKo: '세인트 세이야',
        titleEn: 'Saint Seiya',
        titleJa: '聖闘士星矢',
        category: 'manga',
        creator: '쿠로다 마사미',
        year: 1985,
        description:
            '청소년 성斗士들이 성衣를 입고 '
            '황금십이궁과 싸우는 신화 액션.',
        tags: ['액션', '신화', '우정', '성장'],
        tmdbTvId: 42414,
      ),
      _entry(
        workId: 'sub_manga_noragami_2010',
        titleKo: '노라가미',
        titleEn: 'Noragami',
        titleJa: 'ノラガミ',
        category: 'manga',
        creator: '아다치로',
        year: 2010,
        description:
            '신이 되고 싶은 빈신 야토와 히요리가 '
            '요괴와 신들의 세계를 오가는 액션.',
        tags: ['액션', '신화', '코미디', '초자연'],
        tmdbTvId: 60865,
      ),
      _entry(
        workId: 'sub_manga_yona-of-the-dawn_2009',
        titleKo: '새벽의 연화',
        titleEn: 'Yona of the Dawn',
        titleJa: '暁のヨナ',
        category: 'manga',
        creator: '쿠스노다 미즈',
        year: 2009,
        description:
            '공주 요나가 멸망한 왕국을 되찾기 위해 '
            '전설의 사룡과 함께 여행하는 모험.',
        tags: ['모험', '역사', '로맨스', '성장'],
        tmdbTvId: 65003,
      ),
      _entry(
        workId: 'sub_manga_land-of-the-lustrous_2012',
        titleKo: '보석의 나라',
        titleEn: 'Land of the Lustrous',
        titleJa: '宝石の国',
        category: 'manga',
        creator: '이치카와 하루코',
        year: 2012,
        description:
            '보석로 변한 인간들이 월인과 싸우며 '
            '정체성과 기억을 잃어가는 독특한 SF 판타지.',
        tags: ['SF', '판타지', '다크', '철학'],
        tmdbTvId: 74204,
      ),
      _entry(
        workId: 'sub_manga_nodame-cantabile_2001',
        titleKo: '노다메 칸타빌레',
        titleEn: 'Nodame Cantabile',
        titleJa: 'のだめカンタービレ',
        category: 'manga',
        creator: '니시노 에무',
        year: 2001,
        description:
            '피아니스트 치아키와 천재지만 산만한 노다메가 '
            '음악과 사랑을 키워가는 로맨스 코미디.',
        tags: ['음악', '로맨스', '코미디', '성장'],
        tmdbTvId: 37856,
      ),
      _entry(
        workId: 'sub_manga_usagi-drop_2005',
        titleKo: '토끼 드롭스',
        titleEn: 'Bunny Drop',
        titleJa: 'うさぎドロップ',
        category: 'manga',
        creator: '우노 요미',
        year: 2005,
        description:
            '다이키치가 혼외손녀 리온을 키우며 '
            '가족의 의미를 배우는 힐링 드라마.',
        tags: ['힐링', '가족', '일상', '성장'],
        tmdbTvId: 42598,
      ),
    ];
