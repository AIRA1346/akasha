// ignore_for_file: avoid_print
/// Batch 2 seed expansion: 32 → 100 works
/// Usage: dart run tool/seed_expansion.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final projectRoot = _findProjectRoot();
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final seeds = _batch2Seeds();

  var added = 0;
  var skipped = 0;

  for (final seed in seeds) {
    final workId = seed['workId'] as String;
    final shardId = _shardIdFor(workId);
    final category = seed['category'] as String;
    final shardPath =
        '${shardsRoot.path}/$category/${shardId}.json';
    final shardFile = File(shardPath);

    Map<String, dynamic> shardMap = {};
    if (shardFile.existsSync()) {
      final decoded = json.decode(shardFile.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        shardMap = Map<String, dynamic>.from(decoded);
      }
    }

    if (shardMap.containsKey(workId)) {
      print('SKIP duplicate: $workId');
      skipped++;
      continue;
    }

    shardMap[workId] = seed;
    shardFile.parent.createSync(recursive: true);
    shardFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(shardMap)}\n',
    );
    print('ADD $workId → $category/$shardId.json');
    added++;
  }

  print('\nDone: $added added, $skipped skipped (target total ~${32 + added})');
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

  if (category == 'manga' && RegExp(r'^\d').hasMatch(identifier)) {
    return 'manga_numeric';
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

String _ani(int id, {bool anime = false}) {
  final kind = anime ? 'anime' : 'manga';
  return 'https://s4.anilist.co/file/anilistcdn/media/$kind/cover/large/bx$id.jpg';
}

String _steam(int appId) =>
    'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/library_600x900.jpg';

String _tmdb(String path) => 'https://image.tmdb.org/t/p/w500$path';

String _openLib(String isbn) =>
    'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';

String _igdb(String hash) =>
    'https://images.igdb.com/igdb/image/upload/t_cover_big/$hash.jpg';

List<Map<String, dynamic>> _batch2Seeds() => [
      // ── MANGA (+18) ──
      _w('sub_manga_spy-x-family_2018', '스파이 패밀리', 'manga', 'subculture',
          '타카야 스기타', 2018,
          '스파이와 암살자 부부가 입양한 초능력 아이를 둘러싼 가족 코미디.',
          ['코미디', '스파이', '가족', '액션'], _ani(108725)),
      _w('sub_manga_my-hero-academia_2014', '나의 히어로 아카데미아', 'manga',
          'subculture', '호리코시 코헤이', 2014,
          '초능력 사회에서 무력한 소년이 최고의 히어로를 꿈꾸는 이야기.',
          ['히어로', '학원', '성장', '액션'], _ani(85486)),
      _w('sub_manga_death-note_2003', '데스노트', 'manga', 'subculture',
          '오바 타케시', 2003,
          '이름이 적히면 죽는 노트를 손에 넣은 천재 소년의 심리 스릴러.',
          ['스릴러', '초자연', '정의', '다크'], _ani(30042)),
      _w('sub_manga_fullmetal-alchemist_2001', '강철의 연금술사', 'manga',
          'subculture', '아라카와 히로', 2001,
          '연금술사 형제가 잃은 몸을 되찾기 위해 필사적으로 여행하는 대서사.',
          ['판타지', '연금술', '전쟁', '형제'], _ani(30040)),
      _w('sub_manga_hunter-x-hunter_1998', '헌터×헌터', 'manga', 'subculture',
          '토가시 요시히로', 1998,
          '아버지를 찾기 위해 헌터 시험에 도전하는 소년의 모험.',
          ['모험', '배틀', '우정', '판타지'], _ani(30002)),
      _w('sub_manga_vagabond_1998', '바감동', 'manga', 'subculture',
          '이노우에 다케히코', 1998,
          '미야모토 무사시의 일생을 그린 사무라이 무도 서사시.',
          ['사무라이', '무도', '역사', '성장'], _ani(30745)),
      _w('sub_manga_berserk_1989', '베르세르크', 'manga', 'subculture',
          '미우라 켄트', 1989,
          '거대한 검을 휘두르는 전사 가츠의 복수와 어두운 판타지 세계.',
          ['다크판타지', '복수', '중세', '잔혹'], _ani(30015)),
      _w('sub_manga_mob-psycho-100_2012', '모브 사이코 100', 'manga',
          'subculture', 'ONE', 2012,
          '강력한 초능력을 가진 평범해 보이는 소년의 성장 이야기.',
          ['초능력', '코미디', '성장', '액션'], _ani(70345)),
      _w('sub_manga_rezero_2014', 'Re:제로부터 시작하는 이세계 생활', 'manga',
          'subculture', '나가츠키 탓페이', 2014,
          '이세계로 소환된 소년이 죽음을 반복하며 운명을 바꾸려는 이야기.',
          ['이세계', '루프', '판타지', '드라마'], _ani(85934)),
      _w('sub_manga_haikyuu_2012', '하이큐!!', 'manga', 'subculture',
          '후루다테 하루이치', 2012,
          '작은 키의 소년이 배구를 통해 성장하는 청춘 스포츠 만화.',
          ['스포츠', '배구', '청춘', '팀워크'], _ani(65795)),
      _w('sub_manga_blue-lock_2018', '블루 록', 'manga', 'subculture',
          '무인치 혼', 2018,
          '일본 최고의 스트라이커를 뽑기 위한 극한의 축구 서바이벌.',
          ['스포츠', '축구', '서바이벌', '성장'], _ani(104613)),
      _w('sub_manga_kaiju-no-8_2020', '괴수 8호', 'manga', 'subculture',
          '마츠모토 나오야', 2020,
          '청소부가 괴수와 융합하며 일본 방위대에 입대하는 이야기.',
          ['괴수', '액션', '밀리터리', '코미디'], _ani(114043)),
      _w('sub_manga_dr-stone_2017', 'Dr.STONE', 'manga', 'subculture',
          '보이치', 2017,
          '인류가 석화된 뒤 과학으로 문명을 재건하려는 소년의 모험.',
          ['SF', '과학', '서바이벌', '개그'], _ani(98416)),
      _w('sub_manga_tokyo-revengers_2017', '도쿄 리벤저스', 'manga', 'subculture',
          '와카모토 켄', 2017,
          '과거로 돌아가 양아치 조직과 운명을 바꾸려는 소년의 이야기.',
          ['시간여행', '갱', '청춘', '액션'], _ani(97810)),
      _w('sub_manga_dandadan_2021', '단다단', 'manga', 'subculture',
          '타츠타 유키', 2021,
          '오컬트와 로봇이 뒤섞인 기묘한 청춘 배틀 코미디.',
          ['오컬트', '코미디', '액션', '로맨스'], _ani(128703)),
      _w('sub_manga_fire-force_2015', '불꽃 소방대', 'manga', 'subculture',
          '오바 다카히로', 2015,
          '인간이 불타는 현상을 진압하는 특수 소방대의 활약.',
          ['액션', '초능력', '소방', '다크'], _ani(85130)),
      _w('sub_manga_solo-leveling_2018', '나 혼자만 레벨업', 'manga', 'subculture',
          '추공 / DUBU', 2018,
          '최약 헌터가 유일하게 레벨업할 수 있게 된 판타지 액션.',
          ['판타지', '헌터', '성장', '액션'], _ani(101517)),
      _w('sub_manga_bleach_2001', '블리치', 'manga', 'subculture',
          '쿠보 타이토', 2001,
          '소년이 영혼을 보는 사신 대행으로서 사후 세계를 지키는 이야기.',
          ['액션', '사신', '초자연', '우정'], _ani(30016)),

      // ── ANIMATION (+10) ──
      _w('sub_animation_spy-x-family_2022', '스파이 패밀리', 'animation',
          'subculture', 'WIT STUDIO / CloverWorks', 2022,
          '가짜 가족이 각자의 임무 속에서 진짜 유대를 쌓아가는 스파이 코미디.',
          ['코미디', '스파이', '가족', '액션'], _ani(140960, anime: true)),
      _w('sub_animation_jujutsu-kaisen_2020', '주술회전', 'animation',
          'subculture', 'MAPPA', 2020,
          '저주받은 물건을 삼킨 소년이 주술사가 되어 저주와 맞서는 이야기.',
          ['액션', '초자연', '학원', '다크'], _ani(21459, anime: true)),
      _w('sub_animation_chainsaw-man_2022', '체인소 맨', 'animation',
          'subculture', 'MAPPA', 2022,
          '악마의 힘이 각인된 소년 덴지의 혼돈스러운 액션 드라마.',
          ['액션', '다크', '악마', '카오스'], _ani(127230, anime: true)),
      _w('sub_animation_steinsgate_2011', '슈타인즈 게이트', 'animation',
          'subculture', 'WHITE FOX', 2011,
          '타임머신 실험이 비극적 미래를 초래하며 반복되는 시간여행 SF.',
          ['SF', '시간여행', '서스펜스', '감동'], _ani(11757, anime: true)),
      _w('sub_animation_code-geass_2006', '코드 기어스', 'animation',
          'subculture', 'SUNRISE', 2006,
          '기사단의 힘으로 일본 해방을 꿈꾸는 왕자의 전략 로봇 대전.',
          ['메카', '전략', '반란', 'SF'], _ani(1575, anime: true)),
      _w('gen_animation_cowboy-bebop_1998', '카우보이 비밥', 'animation',
          'generalCulture', 'SUNRISE', 1998,
          '우주 현상금 사냥꾼들의 느와르풍 SF 액션.',
          ['SF', '느와르', '재즈', '액션'], _ani(1, anime: true)),
      _w('sub_animation_neon-genesis-evangelion_1995', '신세기 에반게리온',
          'animation', 'subculture', 'GAINAX / khara', 1995,
          '소년이 거대 생체 로봇 EVA를 조종해 사도와 싸우는 SF 명작.',
          ['메카', 'SF', '심리', '명작'], _ani(30, anime: true)),
      _w('sub_animation_fullmetal-alchemist-brotherhood_2009',
          '강철의 연금술사 BROTHERHOOD', 'animation', 'subculture', 'BONES', 2009,
          '연금술사 형제가 잃은 것을 되찾기 위한 여정을 그린 애니메이션.',
          ['판타지', '연금술', '형제', '명작'], _ani(5114, anime: true)),
      _w('sub_animation_violet-evergarden_2018', '바이올렛 에버가든', 'animation',
          'subculture', 'Kyoto Animation', 2018,
          '전쟁 고아가 대필사가 되며 사랑의 의미를 배우는 감동 드라마.',
          ['감동', '드라마', '성장', '힐링'], _ani(21827, anime: true)),
      _w('sub_animation_demon-slayer_2019', '귀멸의 칼날', 'animation',
          'subculture', 'ufotable', 2019,
          '귀살대 소년 탄지로가 동생을 구하고 귀신과 맞서는 액션 판타지.',
          ['액션', '귀신', '가족', '명작'], _ani(101922, anime: true)),

      // ── GAME (+14) ──
      _w('gen_game_appid570_2013', '도타 2', 'game', 'generalCulture',
          'Valve', 2013,
          '전 세계적으로 사랑받는 5대5 MOBA 대전 게임.',
          ['MOBA', 'PvP', 'e스포츠', '전략'], _steam(570)),
      _w('gen_game_appid730_2012', '카운터 스트라이크 2', 'game',
          'generalCulture', 'Valve', 2012,
          '전술 FPS의 대표작으로 팀워크와 에임이 승부를 가른다.',
          ['FPS', 'PvP', 'e스포츠', '전술'], _steam(730)),
      _w('gen_game_appid1172470_2020', '에이펙스 레전드', 'game',
          'generalCulture', 'Respawn Entertainment', 2020,
          '영웅 기반 능력을 활용하는 배틀로얄 슈터.',
          ['배틀로얄', 'FPS', '팀플레이', 'SF'], _steam(1172470)),
      _w('gen_game_appid271590_2013', '그랜드 테프트 오토 V', 'game',
          'generalCulture', 'Rockstar Games', 2013,
          '로스 산토스를 배경으로 한 오픈월드 액션 어드벤처.',
          ['오픈월드', '액션', '범죄', '멀티'], _steam(271590)),
      _w('gen_game_appid1091500_2020', '사이버펑크 2077', 'game',
          'generalCulture', 'CD PROJEKT RED', 2020,
          '나이트 시티에서 벌어지는 오픈월드 SF RPG.',
          ['SF', '오픈월드', 'RPG', '사이버펑크'], _steam(1091500)),
      _w('gen_game_appid367520_2017', '홀로우 나이트', 'game', 'generalCulture',
          'Team Cherry', 2017,
          '버섯 왕국을 탐험하는 2D 메트로바니아 액션.',
          ['메트로바니아', '인디', '다크판타지', '액션'], _steam(367520)),
      _w('gen_game_appid1145360_2020', '하데스', 'game', 'generalCulture',
          'Supergiant Games', 2020,
          '저승에서 탈출을 시도하는 로그라이크 액션 RPG.',
          ['로그라이크', '액션', '인디', '그리스신화'], _steam(1145360)),
      _w('gen_game_appid1174180_2018', '레드 데드 리뎀션 2', 'game',
          'generalCulture', 'Rockstar Games', 2018,
          '서부 시대를 배경으로 한 오픈월드 서사 액션.',
          ['오픈월드', '서부', '액션', '스토리'], _steam(1174180)),
      _w('gen_game_appid105600_2011', '테라리아', 'game', 'generalCulture',
          'Re-Logic', 2011,
          '2D 샌드박스에서 탐험·건축·보스전을 즐기는 인디 명작.',
          ['샌드박스', '2D', '인디', '협동'], _steam(105600)),
      _w('gen_game_appid252490_2013', '러스트', 'game', 'generalCulture',
          'Facepunch Studios', 2013,
          '야생 서버에서 생존·기지 건설·PvP가 공존하는 하드코어 서바이벌.',
          ['서바이벌', 'PvP', '샌드박스', '하드코어'], _steam(252490)),
      _w('gen_game_appid236390_2013', '워프레임', 'game', 'generalCulture',
          'Digital Extremes', 2013,
          '우주 닌자가 되어 협동 미션을 수행하는 F2P 액션.',
          ['F2P', '협동', 'SF', '액션'], _steam(236390)),
      _w('sub_game_honkai-star-rail_2023', '붕괴: 스타레일', 'game',
          'subculture', 'HoYoverse', 2023,
          '우주를 여행하며 벌어지는 턴제 RPG 어드벤처.',
          ['턴제', 'SF', '수집형RPG', '서브컬처'], _igdb('co5s52')),
      _w('gen_game_appid1593500_2022', '갓 오브 워', 'game', 'generalCulture',
          'Santa Monica Studio', 2022,
          '크라토스와 아트레우스의 북유럽 신화 여정을 그린 액션 어드벤처.',
          ['액션', '신화', '스토리', '명작'], _steam(1593500)),
      _w('gen_game_appid1085660_2019', '데스티니 가디언즈', 'game',
          'generalCulture', 'Bungie', 2019,
          '우주 SF 세계관의 루트 슈터 MMO 액션.',
          ['루트슈터', 'MMO', 'SF', '협동'], _steam(1085660)),

      // ── BOOK (+9) ──
      _w('gen_book_lord-of-the-rings-fellowship_1954', '반지의 제왕: 반지 원정대',
          'book', 'generalCulture', 'J.R.R. 톨킨', 1954,
          '반지를 파괴하기 위한 호빗과 동료들의 대장정.',
          ['판타지', '모험', '서사', '명작'], _openLib('9780618640157')),
      _w('gen_book_1984_1949', '1984', 'book', 'generalCulture',
          '조지 오웰', 1949,
          '전체주의 감시 사회를 그린 디스토피아 소설의 고전.',
          ['디스토피아', '정치', '고전', '소설'], _openLib('9780451524935')),
      _w('gen_book_murder-on-orient-express_1934', '오리엔트 특급 살인',
          'book', 'generalCulture', '아가사 크리스티', 1934,
          '설원 속 열차에서 벌어진 살인 사건을 추리하는 포와로의 활약.',
          ['추리', '미스터리', '고전', '포와로'], _openLib('9780062073495')),
      _w('gen_book_da-vinci-code_2003', '다빈치 코드', 'book', 'generalCulture',
          '댄 브라운', 2003,
          '루브르 살인 사건을 통해 밝혀지는 음모와 종교의 미스터리.',
          ['미스터리', '스릴러', '음모', '베스트셀러'], _openLib('9780307474278')),
      _w('gen_book_norwegian-wood_1987', '노르웨이의 숲', 'book',
          'generalCulture', '무라카미 하루키', 1987,
          '1960년대 도쿄를 배경으로 한 청춘의 사랑과 상실.',
          ['청춘', '로맨스', '문학', '일본'], _openLib('9780375704024')),
      _w('gen_book_hunger-games_2008', '헝거 게임', 'book',
          'generalCulture', '수잔 콜린스', 2008,
          '서바이벌 게임에 참가한 소녀가 체제에 맞서는 디스토피아 SF.',
          ['SF', '서바이벌', '청소년', '반란'], _openLib('9780439023481')),
      _w('gen_book_percy-jackson_2005', '퍼시 잭슨과 번개 도둑', 'book',
          'generalCulture', '릭 리오던', 2005,
          '그리스 신화가 현대에 되살아난 세계의 소년 영웅 모험.',
          ['판타지', '신화', '청소년', '모험'], _openLib('9780786838653')),
      _w('gen_book_ready-player-one_2011', '아이언 레디 플레이어 원', 'book',
          'generalCulture', '언스트 어니스트 클라인', 2011,
          'VR 오아시스의 유산을 둘러싼 레트로 게임 퀘스트.',
          ['SF', '게임', 'VR', '레트로'], _openLib('9780307887443')),
      _w('sub_book_rezero-light-novel_2014', 'Re:제로 라이트노벨', 'book',
          'subculture', '나가츠키 탓페이', 2014,
          '이세계에서 죽음을 반복하는 소년의 라이트노벨 원작.',
          ['라이트노벨', '이세계', '판타지', '서브컬처'], _ani(84847)),

      // ── MOVIE (+10) ──
      _w('gen_movie_inception_2010', '인셉션', 'movie', 'generalCulture',
          '크리스토퍼 놀란', 2010,
          '꿈 속에 잠입해 정보를 훔치는 도둑의 마지막 임무.',
          ['SF', '스릴러', '꿈', '액션'], _tmdb('/9o7OZCqtqbcz1DtgZg40WkZVfbu.jpg')),
      _w('gen_movie_parasite_2019', '기생충', 'movie', 'generalCulture',
          '봉준호', 2019,
          '반지하 가족과 부유층 가족의 운명이 얽히는 블랙코미디 스릴러.',
          ['스릴러', '사회비판', '한국영화', '아카데미'], _tmdb('/7IiTTgloJzvGI1EAYYykw9yaqIs.jpg')),
      _w('gen_movie_avengers-endgame_2019', '어벤져스: 엔드게임', 'movie',
          'generalCulture', '루소 형제', 2019,
          '어벤져스가 타노스에 맞서 우주의 운명을 건 최후의 전투.',
          ['히어로', '액션', 'SF', 'MCU'], _tmdb('/or06FN3Dka5tukK0e9uctCSoaH.jpg')),
      _w('gen_movie_the-dark-knight_2008', '다크 나이트', 'movie',
          'generalCulture', '크리스토퍼 놀란', 2008,
          '배트맨과 조커의 대결을 그린 다크 히어로 걸작.',
          ['히어로', '범죄', '스릴러', '명작'], _tmdb('/qJ2tW6WMUDux911r6m7RMax3aGw.jpg')),
      _w('gen_movie_pulp-fiction_1994', '펄프 픽션', 'movie', 'generalCulture',
          '쿠엔틴 타란티노', 1994,
          '비선형 서사로 엮인 LA 범죄자들의 블랙코미디.',
          ['범죄', '코미디', '명작', '비선형'], _tmdb('/d5iIlFn5s0ImsztdW5XKp0ijhQp.jpg')),
      _w('gen_movie_fight-club_1999', '파이트 클럽', 'movie', 'generalCulture',
          '데이비드 핀처', 1999,
          '불면증에 시달리는 남자가 비밀 결투 클럽에 빠져드는 이야기.',
          ['스릴러', '심리', '반항', '명작'], _tmdb('/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg')),
      _w('gen_movie_forrest-gump_1994', '포레스트 검프', 'movie',
          'generalCulture', '로버트 저메키스', 1994,
          '순수한 소년이 미국 현대사를 관통하며 살아가는 감동 드라마.',
          ['드라마', '감동', '역사', '명작'], _tmdb('/arw2vcZweWUW3oy8Xsd0Ym5Q9SY.jpg')),
      _w('gen_movie_lord-of-the-rings-fellowship_2001', '반지의 제왕: 반지 원정대',
          'movie', 'generalCulture', '피터 잭슨', 2001,
          '호빗 프로도가 반지를 파괴하기 위해 떠나는 판타지 대서사.',
          ['판타지', '모험', '명작', '서사'], _tmdb('/6oom5QYQ2yQTMJIbnvbkH9UKpaM.jpg')),
      _w('gen_movie_the-godfather_1972', '대부', 'movie', 'generalCulture',
          '프란시스 포드 코폴라', 1972,
          '마피아 콜레오네 가문의 흥망성쇠를 그린 범죄 서사시.',
          ['범죄', '가족', '명작', '드라마'], _tmdb('/3bhkrj58Vtu7enSsRlawKtKzX5.jpg')),
      _w('gen_movie_toy-story_1995', '토이 스토리', 'movie', 'generalCulture',
          '존 래시터', 1995,
          '장난감들이 살아 움직이는 세계를 그린 픽사 애니메이션.',
          ['애니메이션', '가족', '우정', '픽사'], _tmdb('/uXDfjJbdP4ijW5hWRPhgcpGm2EZ.jpg')),

      // ── DRAMA (+7) ──
      _w('gen_drama_game-of-thrones_2011', '왕좌의 게임', 'drama',
          'generalCulture', 'DB Weiss / David Benioff', 2011,
          '일곱 왕국의 왕좌를 둘러싼 판타지 정치 드라마.',
          ['판타지', '정치', '전쟁', '서사'], _tmdb('/u3bZgnVQ9opdIn2fwkqjy4tK44.jpg')),
      _w('gen_drama_breaking-bad_2008', '브레이킹 배드', 'drama',
          'generalCulture', '빈스 길리건', 2008,
          '화학 교사가 마약 제조자로 변모하는 범죄 드라마.',
          ['범죄', '스릴러', '드라마', '명작'], _tmdb('/ggFHVNu6YYi5NYi69jNgnB9osm.jpg')),
      _w('gen_drama_the-witcher_2019', '위쳐', 'drama', 'generalCulture',
          'Lauren Schmidt Hissrich', 2019,
          '괴물 사냥꾼 게롤트의 판타지 세계를 그린 넷플릭스 시리즈.',
          ['판타지', '액션', '넷플릭스', '모험'], _tmdb('/7vjaCdKQm3w8pvmr46Qauztx8B2.jpg')),
      _w('gen_drama_extraordinary-attorney-woo_2022', '이상한 변호사 우영우',
          'drama', 'generalCulture', '유인식', 2022,
          '자폐 스펙트럼 변호사가 법정에서 성장하는 휴먼 법정 드라마.',
          ['법정', '휴먼', '한국드라마', '성장'], _tmdb('/7bEbBjBHqKj1G0hGxQNhJ1sF3Vj.jpg')),
      _w('gen_drama_true-detective_2014', '트루 디텍티브', 'drama',
          'generalCulture', 'Nic Pizzolatto', 2014,
          '앤솔러지 형식으로 풀어가는 미스터리 형사 드라마.',
          ['미스터리', '범죄', '스릴러', '앤솔러지'], _tmdb('/aowr4xpLP5sRCL50TkuADBWALG.jpg')),
      _w('gen_drama_chernobyl_2019', '체르노빌', 'drama', 'generalCulture',
          'Craig Mazin', 2019,
          '체르노빌 원전 폭발과 그 이후를 다룬 리얼리티 드라마.',
          ['역사', '재난', '드라마', '미니시리즈'], _tmdb('/hlLDE2JZQ3mGmIFbjIpws6Jf7uq.jpg')),
      _w('gen_drama_kingdom_2019', '킹덤', 'drama', 'generalCulture',
          '김성훈 / 김은희', 2019,
          '조선 시대 좀비 역병 속 권력 다툼을 그린 사극 스릴러.',
          ['사극', '좀비', '스릴러', '한국드라마'], _tmdb('/4uDspK4Vfjw0UjorurYf2BV5x9Y.jpg')),
    ];

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
