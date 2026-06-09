// ignore_for_file: avoid_print
/// Batch 5: 애니·만화 엄선 추가 (AM1, +45작 목표)
/// Policy: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)
/// · 메타·설명 수동 작성 · 포스터 TMDB URL만 (cache/수동 path)
/// · IP당 1 workId · 시즌 정보는 extensions.seasons
///
/// Usage:
///   dart run tool/seed_expansion_batch5.dart
///   dart run tool/seed_expansion_batch5.dart --fetch-posters --apply

import 'dart:convert';
import 'dart:io';

import 'poster_url_policy.dart';
import 'pre_insert_dedupe_gate.dart';
import 'registry_hash_utils.dart';

const _tmdbImageBase = 'https://image.tmdb.org/t/p/w500';
const _posterCacheFile = 'akasha-db/tmdb_poster_cache.json';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final fetchPosters = args.contains('--fetch-posters');
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final existingIds = _collectExistingWorkIds(shardsRoot);
  final dedupeGate = PreInsertDedupeGate.load(projectRoot);
  final maxAdd = int.tryParse(_argValue(args, '--max-add') ?? '') ?? 999999;
  final posterCache = _loadPosterCache(projectRoot);

  if (fetchPosters) {
    await _warmPosterCacheForSeeds(posterCache, _batch5Seeds());
    _savePosterCache(projectRoot, posterCache);
  }

  var added = 0;
  var skipped = 0;
  var blocked = 0;
  var noPoster = 0;

  for (final seed in _batch5Seeds()) {
    if (added >= maxAdd) break;

    final workId = seed['workId'] as String;
    if (existingIds.contains(workId)) {
      skipped++;
      continue;
    }

    final conflicts = dedupeGate.check(seed);
    if (conflicts.isNotEmpty) {
      print('BLOCK $workId: ${conflicts.first}');
      blocked++;
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

    final category = seed['category'] as String;
    final hex = shardHexForWorkId(workId);
    final shardPath = '${shardsRoot.path}/$category/$hex.json';
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

  print(
    'Done: $added added, $skipped skipped, $blocked blocked, '
    '$noPoster without poster',
  );
  if (!apply) print('Dry-run. Pass --apply to write shards.');
}

String? _argValue(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i < 0 || i + 1 >= args.length) return null;
  return args[i + 1];
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
  final uri = Uri.parse('https://www.themoviedb.org/$type/$id');
  try {
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'AkashaRegistryBuilder/1.0');
    final response = await request.close();
    if (response.statusCode != 200) return;
    final html = await response.transform(utf8.decoder).join();
    final og = RegExp(
      r'property="og:image" content="https://media\.themoviedb\.org/t/p/w500([^"]+)"',
    ).firstMatch(html);
    if (og != null) {
      cache[id] = '/${og.group(1)!}';
      return;
    }
    final ld = RegExp(r'"poster_path":"(/[^"]+)"').firstMatch(html);
    if (ld != null) cache[id] = ld.group(1)!;
  } catch (_) {}
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
  Map<String, String>? externalIds,
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
    if (externalIds != null) 'externalIds': externalIds,
    'extensions': extensions,
    '_tmdbTvId': tmdbTvId ?? 0,
  };
}

List<Map<String, dynamic>> _batch5Seeds() {
  return [
    ..._animationSeeds(),
    ..._mangaSeeds(),
  ];
}

List<Map<String, dynamic>> _animationSeeds() => [
      _entry(
        workId: 'sub_animation_dungeon-meshi_2024',
        titleKo: '던전밥',
        titleEn: 'Delicious in Dungeon',
        titleJa: 'ダンジョン飯',
        romaji: 'Dungeon Meshi',
        category: 'animation',
        creator: '오오토마 록코',
        year: 2024,
        description:
            '라이오스 일행이 던전 속에서 몬스터를 요리해 생존하는 판타지 모험 이야기. '
            '식재료 탐구와 파티 케미가 돋보이는 작품이다.',
        tags: ['판타지', '코미디', '모험', '요리'],
        seasons: [
          {'label': '1기', 'year': 2024, 'episodes': 24},
        ],
        tmdbTvId: 207332,
      ),
      _entry(
        workId: 'sub_animation_apothecary-diaries_2023',
        titleKo: '약사의 혼잣말',
        titleEn: 'The Apothecary Diaries',
        titleJa: '薬屋のひとりごと',
        category: 'animation',
        creator: '히나타 네코',
        year: 2023,
        description:
            '궁중에서 일하는 약사 소녀 마오마오가 미스터리와 권력 다툼 속에서 '
            '지식으로 사건을 풀어가는 이야기.',
        tags: ['미스터리', '역사', '궁중', '약학'],
        seasons: [
          {'label': '1기', 'year': 2023, 'episodes': 24},
          {'label': '2기', 'year': 2025, 'episodes': 24},
        ],
        tmdbTvId: 220542,
      ),
      _entry(
        workId: 'sub_animation_zom-100_2023',
        titleKo: '좀비랜드 사가',
        titleEn: 'Zom 100: Bucket List of the Dead',
        titleJa: 'ゾンビ100～ゾンビになるまでにしたい100のこと～',
        category: 'animation',
        creator: '하루코사와 아쿠',
        year: 2023,
        description:
            '좀비 아포칼립스가 시작된 뒤 오히려 자유를 만끽하려는 '
            '아마노 아키라의 버킷리스트 서사.',
        tags: ['좀비', '코미디', '액션', '성장'],
        seasons: [
          {'label': '1기', 'year': 2023, 'episodes': 12},
        ],
        tmdbTvId: 103504,
      ),
      _entry(
        workId: 'sub_animation_mashle_2023',
        titleKo: '마슐',
        titleEn: 'Mashle: Magic and Muscles',
        titleJa: 'マッシュル-MASHLE-',
        category: 'animation',
        creator: '코마도 타케시',
        year: 2023,
        description:
            '마법이 없는 마시 번의 근육 파워로 마법 학교를 제패하는 '
            '코미디 액션 판타지.',
        tags: ['코미디', '액션', '학원', '판타지'],
        seasons: [
          {'label': '1기', 'year': 2023, 'episodes': 12},
          {'label': '2기', 'year': 2024, 'episodes': 12},
        ],
        tmdbTvId: 122286,
      ),
      _entry(
        workId: 'sub_animation_solo-leveling_2024',
        titleKo: '나 혼자만 레벨업',
        titleEn: 'Solo Leveling',
        titleJa: '俺だけレベルアップな件',
        category: 'animation',
        creator: '추성원·장성락',
        year: 2024,
        description:
            '최약 헌터 성진우가 유일하게 레벨업할 수 있는 능력을 얻고 '
            '던전을 정복해 나가는 성장 서사.',
        tags: ['액션', '판타지', '헌터', '성장'],
        seasons: [
          {'label': '1기', 'year': 2024, 'episodes': 12},
          {'label': '2기', 'year': 2025, 'episodes': 13},
        ],
        tmdbTvId: 127532,
      ),
      _entry(
        workId: 'sub_animation_kaiju-no-8_2024',
        titleKo: '괴수 8호',
        titleEn: 'Kaiju No. 8',
        titleJa: '怪獣8号',
        category: 'animation',
        creator: '마츠모토 나오야',
        year: 2024,
        description:
            '청소부 카프카가 괴수와 융합한 뒤 일본 방위대에서 괴수와 싸우는 이야기.',
        tags: ['괴수', '액션', '밀리터리', '성장'],
        seasons: [
          {'label': '1기', 'year': 2024, 'episodes': 12},
          {'label': '2기', 'year': 2025, 'episodes': 12},
        ],
        tmdbTvId: 114226,
      ),
      _entry(
        workId: 'sub_animation_sakamoto-days_2025',
        titleKo: '사카모토 데이즈',
        titleEn: 'Sakamoto Days',
        titleJa: 'SAKAMOTO DAYS',
        category: 'animation',
        creator: '스즈키 유우토',
        year: 2025,
        description:
            '전설의 킬러 사카모토가 가게 주인으로 은퇴했지만 '
            '과거의 적들이 다시 나타나는 액션 코미디.',
        tags: ['액션', '코미디', '킬러', '가족'],
        seasons: [
          {'label': '1기', 'year': 2025, 'episodes': 11},
        ],
        tmdbTvId: 241002,
      ),
      _entry(
        workId: 'sub_animation_undead-unluck_2023',
        titleKo: '언데드 언럭',
        titleEn: 'Undead Unluck',
        titleJa: 'アンデッドアンラック',
        category: 'animation',
        creator: '하라 와카토',
        year: 2023,
        description:
            '불사의 앤디와 언럭 능력의 푸코가 겪는 초능력 액션과 '
            '운명에 맞서는 여정.',
        tags: ['액션', '초능력', '코미디', 'SF'],
        seasons: [
          {'label': '1기', 'year': 2023, 'episodes': 24},
        ],
        tmdbTvId: 211079,
      ),
      _entry(
        workId: 'sub_animation_wind-breaker_2024',
        titleKo: '윈드 브레이커',
        titleEn: 'Wind Breaker',
        titleJa: 'WIND BREAKER',
        category: 'animation',
        creator: '나츠키 코타',
        year: 2024,
        description:
            '학원 도시에서 바람을 지키는 학생들의 싸움과 우정을 그린 '
            '학원 액션 작품.',
        tags: ['학원', '액션', '우정', '성장'],
        seasons: [
          {'label': '1기', 'year': 2024, 'episodes': 13},
        ],
        tmdbTvId: 246246,
      ),
      _entry(
        workId: 'sub_animation_danmachi_2015',
        titleKo: '던전에서 만남을 추구하면 안 되는걸까',
        titleEn: 'Is It Wrong to Try to Pick Up Girls in a Dungeon?',
        titleJa: 'ダンジョンに出会いを求めるのは間違っているだろうか',
        romaji: 'DanMachi',
        category: 'animation',
        creator: '오모리 후지',
        year: 2015,
        description:
            '오르에오가 라벤 패밀리아에 들어가 던전을 탐험하며 성장하는 '
            '판타지 모험 이야기.',
        tags: ['판타지', '던전', '모험', '하렘'],
        seasons: [
          {'label': '1기', 'year': 2015, 'episodes': 13},
          {'label': '2기', 'year': 2019, 'episodes': 12},
          {'label': '3기', 'year': 2020, 'episodes': 12},
          {'label': '4기', 'year': 2022, 'episodes': 22},
        ],
        tmdbTvId: 64495,
      ),
      _entry(
        workId: 'sub_animation_sword-art-online_2012',
        titleKo: '소드 아트 온라인',
        titleEn: 'Sword Art Online',
        titleJa: 'ソードアート・オンライン',
        romaji: 'SAO',
        category: 'animation',
        creator: '가와하라 레키',
        year: 2012,
        description:
            'VRMMORPG에 갇힌 플레이어들의 생존과 키리토의 모험을 그린 '
            '게임 판타지 애니메이션.',
        tags: ['게임', 'VR', '판타지', '액션'],
        seasons: [
          {'label': '아인크라드편', 'year': 2012, 'episodes': 25},
          {'label': 'フェアリィ・ダンス', 'year': 2014, 'episodes': 24},
          {'label': 'アリシゼーション', 'year': 2018, 'episodes': 47},
        ],
        tmdbTvId: 37890,
      ),
      _entry(
        workId: 'sub_animation_classroom-of-the-elite_2017',
        titleKo: '실력 지상주의 교실',
        titleEn: 'Classroom of the Elite',
        titleJa: 'ようこそ実力至上主義の教室へ',
        category: 'animation',
        creator: '시무라 킨고',
        year: 2017,
        description:
            '실력 지상주의 학교에서 아야노코지가 전략과 능력으로 '
            '학급 전쟁에 개입하는 학원 드라마.',
        tags: ['학원', '심리', '전략', '드라마'],
        seasons: [
          {'label': '1기', 'year': 2017, 'episodes': 12},
          {'label': '2기', 'year': 2022, 'episodes': 13},
          {'label': '3기', 'year': 2024, 'episodes': 13},
        ],
        tmdbTvId: 76703,
      ),
      _entry(
        workId: 'sub_animation_kaguya-sama_2019',
        titleKo: '카구야님은 고백받고 싶어',
        titleEn: 'Kaguya-sama: Love Is War',
        titleJa: 'かぐや様は告らせたい',
        category: 'animation',
        creator: '아카사카 아카',
        year: 2019,
        description:
            '학생회장과 부회장이 고백을 피하려 두뇌 싸움을 벌이는 '
            '로맨틱 코미디.',
        tags: ['로맨스', '코미디', '학원', '심리'],
        seasons: [
          {'label': '1기', 'year': 2019, 'episodes': 12},
          {'label': '2기', 'year': 2020, 'episodes': 12},
          {'label': '3기', 'year': 2022, 'episodes': 13},
        ],
        tmdbTvId: 83121,
      ),
      _entry(
        workId: 'sub_animation_horimiya_2021',
        titleKo: '호리미야',
        titleEn: 'Horimiya',
        titleJa: 'ホリミヤ',
        category: 'animation',
        creator: '하기와라 히로',
        year: 2021,
        description:
            '학교와 집에서 다른 모습을 보이는 호리와 미야무라의 '
            '일상 로맨스.',
        tags: ['로맨스', '학원', '일상', '성장'],
        seasons: [
          {'label': '1기', 'year': 2021, 'episodes': 13},
          {'label': '피스', 'year': 2023, 'episodes': 13},
        ],
        tmdbTvId: 112112,
      ),
      _entry(
        workId: 'sub_animation_skip-and-loafer_2023',
        titleKo: '스킵과 로퍼',
        titleEn: 'Skip and Loafer',
        titleJa: 'スキップとローファー',
        category: 'animation',
        creator: '타케모토 아유',
        year: 2023,
        description:
            '시골에서 도쿄의 명문 학교로 진학한 미츠미의 성장과 '
            '친구들과의 청춘 이야기.',
        tags: ['청춘', '학원', '일상', '성장'],
        seasons: [
          {'label': '1기', 'year': 2023, 'episodes': 12},
        ],
        tmdbTvId: 203488,
      ),
      _entry(
        workId: 'sub_animation_haikyuu_2014',
        titleKo: '하이큐!!',
        titleEn: 'Haikyu!!',
        titleJa: 'ハイキュー!!',
        category: 'animation',
        creator: '후루다테 하루이치',
        year: 2014,
        description:
            '작은 체구의 히나타가 배구를 통해 팀과 함께 성장하는 '
            '스포츠 청춘 드라마.',
        tags: ['스포츠', '배구', '청춘', '팀워크'],
        seasons: [
          {'label': '1기', 'year': 2014, 'episodes': 25},
          {'label': '2기', 'year': 2015, 'episodes': 25},
          {'label': '3기', 'year': 2016, 'episodes': 10},
          {'label': '4기', 'year': 2020, 'episodes': 25},
        ],
        tmdbTvId: 60863,
      ),
      _entry(
        workId: 'sub_animation_blue-lock_2022',
        titleKo: '블루 록',
        titleEn: 'Blue Lock',
        titleJa: 'ブルーロック',
        category: 'animation',
        creator: '칸에도 쇼운',
        year: 2022,
        description:
            '일본 대표 스트라이커를 뽑기 위한 극한의 공격수 육성 '
            '프로그램 블루 록의 이야기.',
        tags: ['스포츠', '축구', '심리', '경쟁'],
        seasons: [
          {'label': '1기', 'year': 2022, 'episodes': 24},
          {'label': '2기', 'year': 2024, 'episodes': 14},
        ],
        tmdbTvId: 131041,
      ),
      _entry(
        workId: 'sub_animation_hells-paradise_2023',
        titleKo: '지옥락',
        titleEn: 'Hell\'s Paradise',
        titleJa: '地獄楽',
        category: 'animation',
        creator: '카지 켄지',
        year: 2023,
        description:
            '닌자 가부마루가 불사의 꽃을 찾기 위해 신비한 섬에 '
            '파견되는 다크 판타지 액션.',
        tags: ['닌자', '액션', '판타지', '다크'],
        seasons: [
          {'label': '1기', 'year': 2023, 'episodes': 13},
          {'label': '2기', 'year': 2026, 'episodes': 12},
        ],
        tmdbTvId: 117465,
      ),
      _entry(
        workId: 'sub_animation_dr-stone_2019',
        titleKo: 'Dr.STONE',
        titleEn: 'Dr. Stone',
        titleJa: 'Dr.STONE',
        category: 'animation',
        creator: '이노우에 료',
        year: 2019,
        description:
            '석화에서 깨어난 센쿠가 과학의 힘으로 문명을 재건하는 '
            '포스트 아포칼립스 SF.',
        tags: ['SF', '과학', '모험', '코미디'],
        seasons: [
          {'label': '1기', 'year': 2019, 'episodes': 24},
          {'label': '2기', 'year': 2021, 'episodes': 11},
          {'label': '3기', 'year': 2023, 'episodes': 22},
        ],
        tmdbTvId: 83867,
      ),
      _entry(
        workId: 'sub_animation_fire-force_2019',
        titleKo: '불꽃 소방대',
        titleEn: 'Fire Force',
        titleJa: '炎炎ノ消防隊',
        category: 'animation',
        creator: '아츠시 오쿠보',
        year: 2019,
        description:
            '인간 발화 현상과 싸우는 특수 소방대의 액션과 '
            '세계의 비밀을 파헤치는 이야기.',
        tags: ['액션', '초능력', 'SF', '미스터리'],
        seasons: [
          {'label': '1기', 'year': 2019, 'episodes': 24},
          {'label': '2기', 'year': 2020, 'episodes': 24},
          {'label': '3기', 'year': 2025, 'episodes': 12},
        ],
        tmdbTvId: 88046,
      ),
      _entry(
        workId: 'sub_animation_black-clover_2017',
        titleKo: '블랙 클로버',
        titleEn: 'Black Clover',
        titleJa: 'ブラッククローバー',
        category: 'animation',
        creator: '타바타 유키',
        year: 2017,
        description:
            '마법이 없는 아스타가 마법 기사단에서 성장하며 '
            '마왕을 향해 나아가는 판타지 액션.',
        tags: ['판타지', '마법', '액션', '우정'],
        seasons: [
          {'label': '1기', 'year': 2017, 'episodes': 170},
        ],
        tmdbTvId: 77236,
      ),
      _entry(
        workId: 'sub_animation_my-hero-academia_2016',
        titleKo: '나의 히어로 아카데미아',
        titleEn: 'My Hero Academia',
        titleJa: '僕のヒーローアカデミア',
        category: 'animation',
        creator: '호리코시 코헤이',
        year: 2016,
        description:
            '쿼크 없이 태어난 이즈쿠가 최고의 히어로를 꿈꾸며 '
            '유에이 고등학교에서 성장하는 이야기.',
        tags: ['히어로', '학원', '액션', '성장'],
        seasons: [
          {'label': '1기', 'year': 2016, 'episodes': 13},
          {'label': '2기', 'year': 2017, 'episodes': 25},
          {'label': '3기', 'year': 2018, 'episodes': 25},
          {'label': '4기', 'year': 2019, 'episodes': 25},
          {'label': '5기', 'year': 2021, 'episodes': 25},
          {'label': '6기', 'year': 2022, 'episodes': 25},
          {'label': '7기', 'year': 2024, 'episodes': 21},
        ],
        tmdbTvId: 65931,
      ),
    ];

List<Map<String, dynamic>> _mangaSeeds() => [
      _entry(
        workId: 'sub_manga_one-punch-man_2012',
        titleKo: '원펀맨',
        titleEn: 'One-Punch Man',
        titleJa: 'ワンパンマン',
        category: 'manga',
        creator: 'ONE·무라타 유스케',
        year: 2012,
        description:
            '한 방에 적을 쓰러뜨리는 히어로 사이타마의 일상과 '
            '진정한 상대를 찾는 여정.',
        tags: ['액션', '코미디', '히어로', '패러디'],
        tmdbTvId: 63926,
      ),
      _entry(
        workId: 'sub_manga_dungeon-meshi_2014',
        titleKo: '던전밥',
        titleEn: 'Delicious in Dungeon',
        titleJa: 'ダンジョン飯',
        category: 'manga',
        creator: '오오토마 록코',
        year: 2014,
        description:
            '던전에서 몬스터를 요리해 생존하는 라이오스 일행의 '
            '판타지 모험 만화.',
        tags: ['판타지', '요리', '모험', '코미디'],
        tmdbTvId: 207332,
      ),
      _entry(
        workId: 'sub_manga_apothecary-diaries_2016',
        titleKo: '약사의 혼잣말',
        titleEn: 'The Apothecary Diaries',
        titleJa: '薬屋のひとりごと',
        category: 'manga',
        creator: '히나타 네코',
        year: 2016,
        description:
            '궁중 약사 마오마오가 지식과 관찰력으로 미스터리를 '
            '풀어가는 역사 드라마 만화.',
        tags: ['미스터리', '역사', '궁중', '약학'],
        tmdbTvId: 220542,
      ),
      _entry(
        workId: 'sub_manga_mashle_2018',
        titleKo: '마슐',
        titleEn: 'Mashle: Magic and Muscles',
        titleJa: 'マッシュル-MASHLE-',
        category: 'manga',
        creator: '코마도 타케시',
        year: 2018,
        description:
            '마법 없는 마시 번이 근육으로 마법 학교를 휘저는 '
            '코미디 액션 만화.',
        tags: ['코미디', '액션', '학원', '판타지'],
        tmdbTvId: 122286,
      ),
      _entry(
        workId: 'sub_manga_frieren_2020',
        titleKo: '장송의 프리렌',
        titleEn: 'Frieren: Beyond Journey\'s End',
        titleJa: '葬送のフリーレン',
        category: 'manga',
        creator: '야마다 케노',
        year: 2020,
        description:
            '마왕 토베 후 엘프 마법사 프리렌이 시간과 이별을 배우며 '
            '여행하는 판타지.',
        tags: ['판타지', '모험', '감동', '엘프'],
        tmdbTvId: 209867,
      ),
      _entry(
        workId: 'sub_manga_gachiakuta_2022',
        titleKo: '가치아쿠타',
        titleEn: 'Gachiakuta',
        titleJa: 'ガチアクタ',
        category: 'manga',
        creator: '하시리 오케',
        year: 2022,
        description:
            '누명을 쓴 루도가 쓰레기장 세계에서 살아남으며 '
            '진실을 찾는 다크 액션.',
        tags: ['액션', '다크', '생존', '미스터리'],
        tmdbTvId: 250058,
      ),
      _entry(
        workId: 'sub_manga_wind-breaker_2021',
        titleKo: '윈드 브레이커',
        titleEn: 'Wind Breaker',
        titleJa: 'WIND BREAKER',
        category: 'manga',
        creator: '나츠키 코타',
        year: 2021,
        description:
            '학원 도시에서 바람을 지키는 학생들의 싸움과 우정을 '
            '그린 학원 액션 만화.',
        tags: ['학원', '액션', '우정', '성장'],
        tmdbTvId: 246246,
      ),
      _entry(
        workId: 'sub_manga_assassination-classroom_2012',
        titleKo: '암살교실',
        titleEn: 'Assassination Classroom',
        titleJa: '暗殺教室',
        category: 'manga',
        creator: '마츠이 유세이',
        year: 2012,
        description:
            '달을 파괴한 문어 선생님을 암살하라는 미션을 받은 '
            '3-E반 학생들의 이야기.',
        tags: ['학원', '액션', '코미디', '감동'],
        tmdbTvId: 60854,
      ),
      _entry(
        workId: 'sub_manga_shokugeki-no-soma_2012',
        titleKo: '식극의 소마',
        titleEn: 'Food Wars!: Shokugeki no Soma',
        titleJa: '食戟のソーマ',
        category: 'manga',
        creator: '츠쿠다 유토',
        year: 2012,
        description:
            '요리 천재 소마가 토츠키 요리학교에서 경쟁하며 '
            '성장하는 요리 배틀 만화.',
        tags: ['요리', '학원', '경쟁', '코미디'],
        tmdbTvId: 61669,
      ),
      _entry(
        workId: 'sub_manga_cells-at-work_2015',
        titleKo: '일하는 세포',
        titleEn: 'Cells at Work!',
        titleJa: 'はたらく細胞',
        category: 'manga',
        creator: '시미즈 하루카',
        year: 2015,
        description:
            '인체 속 세포들이 질병과 싸우는 모습을 의인화한 '
            '교육·코미디 만화.',
        tags: ['교육', '코미디', 'SF', '의학'],
        tmdbTvId: 73209,
      ),
      _entry(
        workId: 'sub_manga_grand-blue_2014',
        titleKo: '그랜드 블루',
        titleEn: 'Grand Blue Dreaming',
        titleJa: 'ぐらんぶる',
        category: 'manga',
        creator: '이노우에 켄지',
        year: 2014,
        description:
            '다이빙 동아리에 들어간 이오리의 대학 생활과 '
            '과장된 코미디 일상.',
        tags: ['코미디', '대학', '다이빙', '일상'],
        tmdbTvId: 82682,
      ),
      _entry(
        workId: 'sub_manga_komi-san_2016',
        titleKo: '코미는, 커뮤니케이션이 어렵다',
        titleEn: 'Komi Can\'t Communicate',
        titleJa: '古見さんは、コミュ症です。',
        category: 'manga',
        creator: '오다 토모히토',
        year: 2016,
        description:
            '교류장애 소녀 코미의 친구 100명 만들기 프로젝트를 '
            '돕는 학원 코미디.',
        tags: ['학원', '코미디', '로맨스', '일상'],
        tmdbTvId: 89901,
      ),
      _entry(
        workId: 'sub_manga_rent-a-girlfriend_2017',
        titleKo: '여친, 빌리겠습니다',
        titleEn: 'Rent-a-Girlfriend',
        titleJa: '彼女、お借りします',
        category: 'manga',
        creator: '미야지마 레이지',
        year: 2017,
        description:
            '렌탈 여친 서비스를 이용한 카즈야의 연애와 '
            '성장을 그린 로맨틱 코미디.',
        tags: ['로맨스', '코미디', '대학', '연애'],
        tmdbTvId: 96374,
      ),
      _entry(
        workId: 'sub_manga_nagatoro_2017',
        titleKo: '이런 걸 좋아하시는 건가요, 나가토르양?',
        titleEn: 'Don\'t Toy with Me, Miss Nagatoro',
        titleJa: 'イジらないで、長瀬さん',
        category: 'manga',
        creator: '나노무라 774',
        year: 2017,
        description:
            '후배 나가토르가 선배 나오토를 장난치며 두 사람의 '
            '관계가 변하는 학원 로맨스.',
        tags: ['로맨스', '학원', '코미디', '성장'],
        tmdbTvId: 88924,
      ),
      _entry(
        workId: 'sub_manga_toilet-bound-hanako-kun_2014',
        titleKo: '화장실의 하니코 군',
        titleEn: 'Toilet-Bound Hanako-kun',
        titleJa: '地縛少年花子くん',
        category: 'manga',
        creator: '아이다이로',
        year: 2014,
        description:
            '학교의 신 하니코 군과 야시로 네네가 초자연적 사건을 '
            '해결하는 오컬트 학원 이야기.',
        tags: ['오컬트', '학원', '미스터리', '코미디'],
        tmdbTvId: 95897,
      ),
      _entry(
        workId: 'sub_manga_world-trigger_2006',
        titleKo: '월드 트리거',
        titleEn: 'World Trigger',
        titleJa: 'ワールドトリガー',
        category: 'manga',
        creator: '아시하라 다이스케',
        year: 2006,
        description:
            '이웃이라는 차원 침략자에 맞서 국경 방위기관이 '
            '싸우는 SF 액션 만화.',
        tags: ['SF', '액션', '전략', '학원'],
        tmdbTvId: 60851,
      ),
      _entry(
        workId: 'sub_manga_dgray-man_2004',
        titleKo: 'D.Gray-man',
        titleEn: 'D.Gray-man',
        titleJa: 'ディー・グレイマン',
        category: 'manga',
        creator: '호시노 카츠라',
        year: 2004,
        description:
            '엑소시스트 알렌 워커가 아크와 싸우며 세계를 '
            '구하는 다크 판타지 액션.',
        tags: ['액션', '판타지', '다크', '악마'],
        tmdbTvId: 62117,
      ),
      _entry(
        workId: 'sub_manga_soul-eater_2004',
        titleKo: '소울 이터',
        titleEn: 'Soul Eater',
        titleJa: 'ソウルイーター',
        category: 'manga',
        creator: '오카베 아츠시',
        year: 2004,
        description:
            '무기와 마스터가 팀을 이뤄 마녀와 싸우는 '
            '학원 액션 판타지.',
        tags: ['액션', '판타지', '학원', '호러'],
        tmdbTvId: 16652,
      ),
      _entry(
        workId: 'sub_manga_inuyasha_1996',
        titleKo: '이누야샤',
        titleEn: 'Inuyasha',
        titleJa: '犬夜叉',
        category: 'manga',
        creator: '타카하시 루미코',
        year: 1996,
        description:
            '현대에서 온 히구라시 카구ome와 반요 이누야샤가 '
            '사혼의 구슬을 둘러싼 모험.',
        tags: ['판타지', '액션', '로맨스', '시대극'],
        tmdbTvId: 30659,
      ),
      _entry(
        workId: 'sub_manga_nichijou_2006',
        titleKo: '일상',
        titleEn: 'Nichijou - My Ordinary Life',
        titleJa: '日常',
        category: 'manga',
        creator: '아라와 케이이치로',
        year: 2006,
        description:
            '고등학생들의 기묘하고 과장된 일상을 그린 '
            '개그 학원 코미디.',
        tags: ['코미디', '일상', '학원', '개그'],
        tmdbTvId: 46262,
      ),
      _entry(
        workId: 'sub_manga_barakamon_2009',
        titleKo: '바라카몬',
        titleEn: 'Barakamon',
        titleJa: 'ばらかもん',
        category: 'manga',
        creator: '스기모토 요시노',
        year: 2009,
        description:
            '서울 캘리그래퍼 세이가 고도 후쿠오에 내려가 마을 사람들과 '
            '성장하는 힐링 이야기.',
        tags: ['힐링', '일상', '성장', '캘리그래피'],
        tmdbTvId: 61524,
      ),
      _entry(
        workId: 'sub_manga_silver-spoon_2011',
        titleKo: '실버 스푼',
        titleEn: 'Silver Spoon',
        titleJa: '銀の匙',
        category: 'manga',
        creator: '아라카와 히로미',
        year: 2011,
        description:
            '농업 고등학교에서 농업과 음식의 소중함을 배우는 '
            '청춘 성장 드라마.',
        tags: ['농업', '청춘', '성장', '코미디'],
        tmdbTvId: 60835,
      ),
      _entry(
        workId: 'sub_manga_yotsubato_2003',
        titleKo: '요츠바랑!',
        titleEn: 'Yotsuba&!',
        titleJa: 'よつばと!',
        category: 'manga',
        creator: '아자마 케이야',
        year: 2003,
        description:
            '초록 머리 소녀 요츠바의 호기심 가득한 일상을 그린 '
            '힐링 코미디.',
        tags: ['일상', '코미디', '힐링', '가족'],
        tmdbTvId: 0,
      ),
    ];
