import 'dart:convert';
import '../models/enums.dart';
import 'registry_sync_service.dart';

/// 공통 작품 사전 모델 (Tier 1 - Metadata)
class RegistryWork {
  final String workId;
  final String title;
  final MediaCategory category;
  final AppDomain domain;
  final String creator;
  final int? releaseYear;
  final String description;
  final List<String> tags;
  final String? posterPath; // 네트워크 URL 또는 로컬 이미지 에셋 경로

  const RegistryWork({
    required this.workId,
    required this.title,
    required this.category,
    required this.domain,
    this.creator = '',
    this.releaseYear,
    this.description = '',
    this.tags = const [],
    this.posterPath,
  });

  factory RegistryWork.fromJson(Map<String, dynamic> json) {
    final workId = json['workId']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    
    final categoryStr = json['category']?.toString() ?? 'manga';
    final category = MediaCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => MediaCategory.manga,
    );

    final domainStr = json['domain']?.toString() ?? 'subculture';
    final domain = AppDomain.values.firstWhere(
      (e) => e.name == domainStr,
      orElse: () => AppDomain.subculture,
    );

    return RegistryWork(
      workId: workId,
      title: title,
      category: category,
      domain: domain,
      creator: json['creator']?.toString() ?? '',
      releaseYear: int.tryParse(json['releaseYear']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      posterPath: json['posterPath']?.toString(),
    );
  }
}

/// 전 세계의 유명 작품 메타데이터를 들고 있는 내장 사전 레지스트리
class WorksRegistry {
  static final Map<String, RegistryWork> _registry = {
    // ── 만화 (manga) ──
    'shigatsu_2011': const RegistryWork(
      workId: 'shigatsu_2011',
      title: '4월은 너의 거짓말',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '아라카와 나오시 (Naoshi Arakawa)',
      releaseYear: 2011,
      description: '피아노를 포기한 천재 소년 아리마 코세이가 자유분방한 바이올리니스트 미야조노 카오리를 만나 다시 음악과 마주하게 되는 이야기. 음악과 청춘의 아름다움, 그리고 상실의 아픔을 섬세하게 그린 명작.',
      tags: ['감동', '음악', '청춘', '피아노'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx67707-srHFl9GBmfig.png',
    ),
    'onepiece_1997': const RegistryWork(
      workId: 'onepiece_1997',
      title: '원피스',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '오다 에이이치로 (Eiichiro Oda)',
      releaseYear: 1997,
      description: '해적왕을 꿈꾸는 소년 몽키 D. 루피가 동료들과 함께 위대한 항로(그랜드 라인)를 항해하며 겪는 대서사시.',
      tags: ['모험', '우정', '해적', '대하'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx30013-BeslEMqiPhlk.jpg',
    ),
    'demonslayer_2016': const RegistryWork(
      workId: 'demonslayer_2016',
      title: '귀멸의 칼날',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '고토게 코요하루 (Koyoharu Gotouge)',
      releaseYear: 2016,
      description: '가족을 귀신에게 잃고 유일하게 살아남은 여동생마저 귀신이 되어버린 소년 카마도 탄지로가 여동생을 인간으로 되돌리기 위해 귀살대에 입대하는 이야기.',
      tags: ['액션', '가족애', '귀신', '다이쇼'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx87216-c9bSNVD10UuD.png',
    ),
    'shingeki_2009': const RegistryWork(
      workId: 'shingeki_2009',
      title: '진격의 거인',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '이사야마 하지메 (Hajime Isayama)',
      releaseYear: 2009,
      description: '거대한 벽 안에서 살아가던 인류가 벽 너머의 거인과 맞서 싸우는 이야기. 후반부로 갈수록 드러나는 세계관의 스케일과 전복적 반전이 압도적.',
      tags: ['SF', '전쟁', '자유', '반전'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx53390-1RsuABC34P9D.jpg',
    ),
    'eightysix_2017': const RegistryWork(
      workId: 'eightysix_2017',
      title: '86 -에이티식스-',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '아사토 아사토 (Asato Asato)',
      releaseYear: 2017,
      description: '공화국의 전쟁에서 "사상자 제로"라는 프로파간다 뒤에 숨겨진 진실 — 인간으로 취급받지 못하는 86구역 출신 소년병들의 이야기.',
      tags: ['SF', '전쟁', '차별', '밀리터리'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/nx101606-3lMiy9HQjBgv.jpg',
    ),
    'gabriel_2013': const RegistryWork(
      workId: 'gabriel_2013',
      title: '가브릴 드롭아웃',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '우카미 (Ukami)',
      releaseYear: 2013,
      description: '천사학교를 수석 졸업한 가브릴이 인간 세계에 내려온 후 온라인 게임에 빠져 타락해가는 이야기. 천사인데 악마보다 악질인 일상 코미디.',
      tags: ['코미디', '일상', '천사', '악마'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21878-rfzDjP2gjxGR.jpg',
    ),
    'chainsawman_2018': const RegistryWork(
      workId: 'chainsawman_2018',
      title: '체인소 맨',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '후지모토 타츠키 (Tatsuki Fujimoto)',
      releaseYear: 2018,
      description: '가난한 소년 덴지가 체인소의 악마 포치타와 합체하여 체인소 맨이 되는 이야기. 예측불가의 전개와 파격적인 연출이 특징.',
      tags: ['액션', '다크', '악마', '카오스'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx105778-euxXZEIfDY2u.png',
    ),
    'naruto_1999': const RegistryWork(
      workId: 'naruto_1999',
      title: '나루토',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '키시모토 마사시 (Masashi Kishimoto)',
      releaseYear: 1999,
      description: '외톨이 닌자 소년 우즈마키 나루토가 마을 최고의 닌자 호카게가 되기 위해 성장해 나가는 이야기.',
      tags: ['액션', '닌자', '우정', '성장'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/nx30011-9yUF1dXWgDOx.jpg',
    ),
    'jujutsukaisen_2018': const RegistryWork(
      workId: 'jujutsukaisen_2018',
      title: '주술회전',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '아쿠타미 게게 (Gege Akutami)',
      releaseYear: 2018,
      description: '주술사와 저주의 세계를 그린 다크 판타지 배틀 만화. 시부야 사변 이후 급변하는 전개가 인상적.',
      tags: ['액션', '다크판타지', '주술', '배틀'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx101517-H3TdM3g5ZUe9.jpg',
    ),
    'conan_manga': const RegistryWork(
      workId: 'conan_manga',
      title: '명탐정 코난',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '아오야마 고쇼 (Gosho Aoyama)',
      releaseYear: 1994,
      description: '검은 조직의 약물에 의해 어린아이가 되어버린 고등학생 명탐정 쿠도 신이치가 에도가와 코난이라는 이름으로 여러 어려운 사건을 해결하며 검은 조직의 실체를 쫓는 이야기.',
      tags: ['추리', '소년만화', '럽코', '장수작'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/nx106015-yK0zreKP7RVs.jpg',
    ),
    'math_thief': const RegistryWork(
      workId: 'math_thief',
      title: '수학도둑',
      category: MediaCategory.manga,
      domain: AppDomain.generalCulture,
      creator: '송도수 / 서정은',
      releaseYear: 2006,
      description: '메이플스토리 아바타들이 펼치는 수학 학습만화의 전설적인 베스트셀러. 재미있는 스토리텔링 속에 수학적 지식과 논리적 사고력을 담아내어 어린이와 어른 모두에게 사랑받는 작품.',
      tags: ['학습만화', '모험', '수학', '메이플'],
      posterPath: 'https://image.yes24.com/goods/2301053/L',
    ),

    // ── 게임 (game) ──
    'minecraft_2011': const RegistryWork(
      workId: 'minecraft_2011',
      title: '마인크래프트',
      category: MediaCategory.game,
      domain: AppDomain.generalCulture,
      creator: 'Mojang Studios',
      releaseYear: 2011,
      description: '무한한 복셀 세계에서 자원을 채취하고 건축하며 자유롭게 모험하는 궁극의 샌드박스 게임. 전 세계에서 가장 많이 팔린 게임.',
      tags: ['샌드박스', '서바이벌', '크래프팅', '멀티플레이'],
      posterPath: 'https://images.justwatch.com/poster/11696472/s276',
    ),
    'lol_2009': const RegistryWork(
      workId: 'lol_2009',
      title: '리그 오브 레전드',
      category: MediaCategory.game,
      domain: AppDomain.generalCulture,
      creator: 'Riot Games',
      releaseYear: 2009,
      description: '5v5 팀 기반 전략 대전 게임. 전 세계 최대 규모의 e스포츠 종목 중 하나.',
      tags: ['MOBA', 'PvP', 'e스포츠', '팀전'],
      posterPath: 'https://steamcdn-a.akamaihd.net/steam/apps/1276790/header.jpg',
    ),
    'eldenring_2022': const RegistryWork(
      workId: 'eldenring_2022',
      title: '엘든 링',
      category: MediaCategory.game,
      domain: AppDomain.generalCulture,
      creator: 'FromSoftware',
      releaseYear: 2022,
      description: '미야자키 히데타카와 조지 R.R. 마틴의 세계관이 결합된 오픈월드 액션 RPG. 광대한 오픈월드 사이에 숨겨진 비밀과 도전이 가득.',
      tags: ['소울라이크', '오픈월드', 'RPG', '다크판타지'],
      posterPath: 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/1245620/library_600x900.jpg',
    ),
    'axiom_game': const RegistryWork(
      workId: 'axiom_game',
      title: '엑시옴',
      category: MediaCategory.game,
      domain: AppDomain.generalCulture,
      creator: '인디 제작사',
      releaseYear: 2024,
      description: '얼리액세스 단계의 공상과학 우주 테마 인디 메트로배니아 기대작.',
      tags: ['인디', '얼리액세스', 'SF'],
      posterPath: 'https://steamcdn-a.akamaihd.net/steam/apps/332200/header.jpg',
    ),
    'bluearchive_2021': const RegistryWork(
      workId: 'bluearchive_2021',
      title: '블루 아카이브',
      category: MediaCategory.game,
      domain: AppDomain.subculture,
      creator: 'NEXON Games',
      releaseYear: 2021,
      description: '학원 도시 키보토스의 선생님이 되어 매력적인 미소녀 학생들을 이끌고 도시의 평화를 지키는 서브컬처 수집형 RPG 게임.',
      tags: ['학원물', '수집형RPG', '청춘', 'OST'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/b172598-MynXMFF72Ha3.jpg',
    ),
    'nikke_2022': const RegistryWork(
      workId: 'nikke_2022',
      title: '승리의 여신: 니케',
      category: MediaCategory.game,
      domain: AppDomain.subculture,
      creator: 'Shift Up',
      releaseYear: 2022,
      description: '황폐해진 지상에서 외계 기계 병기에 맞서 싸우는 안드로이드 니케들과 사령관의 이야기를 다룬 서브컬처 건슈팅 RPG 게임.',
      tags: ['포스트아포칼립스', '건슈팅', '수집형RPG', 'SF'],
      posterPath: 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx186872-PecL686Sgicx.jpg',
    ),
    'laplace_novel': const RegistryWork(
      workId: 'laplace_novel',
      title: '라플라스의 마녀',
      category: MediaCategory.book,
      domain: AppDomain.generalCulture,
      creator: '히가시노 게이고 (Keigo Higashino)',
      releaseYear: 2015,
      description: '히가시노 게이고 작가의 데뷔 30주년 기념작. 자연현상의 기포 흐름 and 바람의 세기를 예측하는 소녀와 미스터리.',
      tags: ['소설', '미스터리', 'SF', '히가시노게이고'],
      posterPath: 'https://image.yes24.com/goods/18063773/L',
    ),
  };

  /// 특정 ID로 공통 작품 메타데이터를 가져옵니다.
  static RegistryWork? getWorkById(String workId) {
    return _registry[workId];
  }

  /// 제목 초성, 한글 포함 여부 등으로 통합 검색을 지원합니다.
  static List<RegistryWork> search(String query) {
    if (query.isEmpty) return _registry.values.toList();
    final q = query.toLowerCase().replaceAll(' ', '');
    return _registry.values.where((work) {
      final t = work.title.toLowerCase().replaceAll(' ', '');
      final c = work.creator.toLowerCase().replaceAll(' ', '');
      final tagsMatch = work.tags.any((tag) => tag.toLowerCase().contains(q));
      return t.contains(q) || c.contains(q) || tagsMatch;
    }).toList();
  }

  /// 전체 목록을 가져옵니다.
  static List<RegistryWork> get allWorks => _registry.values.toList();

  /// 특정 도메인 및 카테고리 필터가 가해진 사전 목록을 쿼리 (Phase 6 최적화)
  static List<RegistryWork> getFilteredWorks({
    AppDomain? domain,
    MediaCategory? category,
  }) {
    return _registry.values.where((work) {
      if (domain != null && work.domain != domain) return false;
      if (category != null && work.category != category) return false;
      return true;
    }).toList();
  }

  /// 로컬 캐시 사전을 디스크에서 읽어 메모리에 병합
  static Future<void> loadCachedRegistry() async {
    try {
      final jsonStr = await RegistrySyncService().readCachedRegistry();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(jsonStr);
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final incomingWork = RegistryWork.fromJson(value);
            final existingWork = _registry[key];
            if (existingWork != null) {
              // 만약 기존 하드코딩된 항목의 포스터가 변경된 새로운 주소(yes24, steamcdn 등)라면,
              // 온라인 캐시에서 온 구버전 JustWatch 주소로 덮어쓰지 않고 기존 포스터 주소를 보존합니다.
              final useExistingPoster = existingWork.posterPath != null && 
                  !existingWork.posterPath!.contains('justwatch.com');
              
              _registry[key] = RegistryWork(
                workId: incomingWork.workId,
                title: incomingWork.title,
                category: incomingWork.category,
                domain: incomingWork.domain,
                creator: incomingWork.creator,
                releaseYear: incomingWork.releaseYear,
                description: incomingWork.description,
                tags: incomingWork.tags,
                posterPath: useExistingPoster ? existingWork.posterPath : incomingWork.posterPath,
              );
            } else {
              _registry[key] = incomingWork;
            }
          }
        });
      }
    } catch (e) {
      print('Error merging cached works registry: $e');
    }
  }
}
