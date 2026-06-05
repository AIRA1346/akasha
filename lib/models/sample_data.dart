import 'enums.dart';
import 'akasha_item.dart';
import '../services/works_registry.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 초기 샘플 데이터 (대분류 동적 도메인 속성 반영 버전)
// ════════════════════════════════════════════════════════════════

List<AkashaItem> buildSampleData() {
  final list = <AkashaItem>[
      // ── 서브컬처 (Subculture) ──

      ContentItem(
        workId: 'shigatsu_2011',
        title: '4월은 너의 거짓말',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '아라카와 나오시 (Naoshi Arakawa)',
        releaseYear: 2011,
        rating: 5.0,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        isHallOfFame: true,
        tags: ['감동', '음악', '청춘', '피아노'],
        description: '피아노를 포기한 천재 소년 아리마 코세이가 자유분방한 바이올리니스트 미야조노 카오리를 만나 다시 음악과 마주하게 되는 이야기.',
        memorableQuotes: [
          '"모차르트가 위에서 말하고 있어. \'여행을 떠나자\'라고." — 미야조노 카오리 / 바이올린 콩쿠르',
          '"봄이 오면 너를 찾으러 갈 테니까." — 미야조노 카오리 / 편지',
        ],
        review: '마지막 편지를 읽는 순간 눈물이 멈추지 않았다. 카오리의 거짓말이 무엇이었는지 알게 되었을 때의 충격과 감동은 평생 갈 것 같다.',
      ),

      ContentItem(
        workId: 'onepiece_1997',
        title: '원피스',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '오다 에이이치로 (Eiichiro Oda)',
        releaseYear: 1997,
        rating: 5.0,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.watching,
        isHallOfFame: true,
        tags: ['모험', '우정', '해적', '대하'],
        description: '해적왕을 꿈꾸는 소년 몽키 D. 루피가 동료들과 함께 위대한 항로(그랜드 라인)를 항해하며 겪는 대서사시.',
        memorableQuotes: [
          '"해적왕이 될 거야!" — 몽키 D. 루피',
          '"사람은 언제 죽는다고 생각하나? 사람에게 잊혀졌을 때다." — 닥터 히루루크',
        ],
        review: '오랜 연재 동안 흥미진진함을 유지하는 대단한 만화. 모험의 낭만이 가득하다.',
      ),

      ContentItem(
        workId: 'demonslayer_2016',
        title: '귀멸의 칼날',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '고토게 코요하루 (Koyoharu Gotouge)',
        releaseYear: 2016,
        rating: 5.0,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        isHallOfFame: true,
        tags: ['액션', '가족애', '귀신', '다이쇼'],
        description: '여동생을 인간으로 되돌리기 위해 귀살대에 입대하는 탄지로의 여정.',
        memorableQuotes: [
          '"마음은 뜨거우니까!" — 렌고쿠 쿄쥬로',
        ],
        review: '깔끔한 기승전결과 렌고쿠의 간지가 폭발한다.',
      ),

      ContentItem(
        workId: 'shingeki_2009',
        title: '진격의 거인',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '이사야마 하지메 (Hajime Isayama)',
        releaseYear: 2009,
        rating: 5.0,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        isHallOfFame: true,
        tags: ['SF', '전쟁', '자유', '반전'],
        description: '거대한 벽 안에서 살아가던 인류가 벽 너머의 거인과 맞서 싸우는 이야기.',
        memorableQuotes: [
          '"싸워. 싸우지 않으면 이길 수 없어." — 에렌 예거',
        ],
        review: '치밀한 세계관과 엄청난 연출, 반전이 돋보이는 역대급 다크 판타지.',
      ),

      ContentItem(
        workId: 'eightysix_2017',
        title: '86 -에이티식스-',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '아사토 아사토 (Asato Asato)',
        releaseYear: 2017,
        rating: 5.0,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.finished,
        tags: ['SF', '전쟁', '차별', '밀리터리'],
        description: '인간으로 취급받지 못하는 86구역 출신 소년병들의 전쟁과 연대.',
        review: '라노벨 원작 애니메이션 연출과 스토리가 모두 훌륭하다.',
      ),

      ContentItem(
        workId: 'conan_manga',
        title: '명탐정 코난',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '아오야마 고쇼 (Gosho Aoyama)',
        releaseYear: 1994,
        rating: 4.5,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.watching,
        tags: ['추리', '소년만화', '럽코', '장수작'],
        description: '검은 조직의 약물에 의해 어린아이가 되어버린 고등학생 명탐정 코난의 추리극.',
        memorableQuotes: [
          '"진실은 언제나 하나! (真実はいつもひとつ!)" — 에도가와 코난',
        ],
        review: '검은 조직 에피소드는 늘 흥미롭다. 란과의 로맨스 진전도 기대된다.',
      ),

      GameItem(
        workId: 'bluearchive_2021',
        title: '블루 아카이브',
        domain: AppDomain.subculture,
        creator: 'NEXON Games',
        releaseYear: 2021,
        rating: 5.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.playing,
        isHallOfFame: true,
        tags: ['학원물', '수집형RPG', '청춘', 'OST'],
        description: '학원 도시 키보토스의 선생님이 되어 미소녀 학생들을 이끄는 청춘 판타지 RPG.',
        memorableQuotes: [
          '"선생님, 늘 곁에 있어주실 거죠?" — 시로코',
          '"이 세계에는 기적이 존재하고, 그 열쇠는 늘 우리에게 있으니까." — 아로나',
        ],
        review: '감성 가득한 일러스트와 멋진 OST가 매력적. 에덴조약 스토리는 정말 역대급 전율이었다.',
      ),

      GameItem(
        workId: 'nikke_2022',
        title: '승리의 여신: 니케',
        domain: AppDomain.subculture,
        creator: 'Shift Up',
        releaseYear: 2022,
        rating: 4.5,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.playing,
        tags: ['포스트아포칼립스', '건슈팅', '수집형RPG', 'SF'],
        description: '외계 기계 병기에 맞서 싸우는 안드로이드 니케들과 사령관의 우울한 생존기.',
        memorableQuotes: [
          '"지상을 인류에게 돌려주기 전까지, 전 멈추지 않을 겁니다." — 마리안',
        ],
        review: '포스트 아포칼립스의 무겁고 암울한 스토리와 모바일 건슈팅 액션의 연동이 아주 훌륭하다.',
      ),

      // ── 일반 문화 (General Culture) ──

      ContentItem(
        workId: 'math_thief',
        title: '수학도둑',
        category: MediaCategory.manga,
        domain: AppDomain.generalCulture,
        creator: '송도수 / 서정은',
        releaseYear: 2006,
        rating: 4.0,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.finished,
        tags: ['학습만화', '모험', '수학', '메이플'],
        description: '메이플스토리 캐릭터들과 함께 수학적 개념을 익히는 학습만화의 전설.',
        memorableQuotes: [
          '"수학은 세상을 이해하는 비밀의 열쇠다!" — 도도',
        ],
        review: '단순 학습만화를 넘어 스토리도 깊이 있고 재미있어 어릴 때 정말 밤새워 읽었다.',
      ),

      GameItem(
        workId: 'minecraft_2011',
        title: '마인크래프트',
        domain: AppDomain.generalCulture,
        creator: 'Mojang Studios',
        releaseYear: 2011,
        rating: 5.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.playing,
        isHallOfFame: true,
        tags: ['샌드박스', '서바이벌', '크래프팅', '멀티플레이'],
        description: '자유롭게 세상을 건축하고 모험하는 궁극의 복셀 샌드박스 대중 게임.',
        review: '창의력을 무한히 발휘할 수 있는 역사적인 작품. 친구들과 멀티플레이하면 더 꿀잼.',
      ),

      GameItem(
        workId: 'lol_2009',
        title: '리그 오브 레전드',
        domain: AppDomain.generalCulture,
        creator: 'Riot Games',
        releaseYear: 2009,
        rating: 4.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.playing,
        tags: ['MOBA', 'PvP', 'e스포츠', '팀전'],
        description: '세계적인 대중성을 자랑하는 5v5 팀 대전 e스포츠 게임.',
        review: '이길 땐 재밌고 질 땐 화나지만 결국 다시 켜게 되는 마성의 게임.',
      ),

      GameItem(
        workId: 'eldenring_2022',
        title: '엘든 링',
        domain: AppDomain.generalCulture,
        creator: 'FromSoftware',
        releaseYear: 2022,
        rating: 5.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.cleared,
        isHallOfFame: true,
        tags: ['소울라이크', '오픈월드', 'RPG', '다크판타지'],
        description: '미야자키 히데타카의 오픈월드 다크 판타지 액션 AAA 대작 RPG 게임.',
        memorableQuotes: [
          '"나는 Malenia, 미켈라의 칼날. 지금까지 한번도 패배한 적이 없다." — Malenia',
        ],
        review: '소울 시리즈 역사상 최고의 완성도와 탐험 요소를 가진 대중적인 명작 RPG.',
      ),

      ContentItem(
        workId: 'laplace_novel',
        title: '라플라스의 마녀',
        category: MediaCategory.book,
        domain: AppDomain.generalCulture,
        creator: '히가시노 게이고 (Keigo Higashino)',
        releaseYear: 2015,
        rating: 4.5,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        tags: ['소설', '미스터리', 'SF', '히가시노게이고'],
        description: '물리 법칙을 완벽히 계산해 미래를 예측하는 마도카를 둘러싼 미스터리 소설.',
        memorableQuotes: [
          '"이 세상은 말이지, 누군가의 음모나 계획대로 움직이는 게 아니야." — 아오에 슈스케',
        ],
        review: '뇌과학과 기상물리학을 영리하게 결합한 히가시노 게이고 특유의 흡인력 있는 미스터리.',
      ),
  ];
  for (final item in list) {
    if (item.workId.isNotEmpty) {
      final registryWork = WorksRegistry.getWorkById(item.workId);
      if (registryWork != null) {
        item.posterPath ??= registryWork.posterPath;
      }
    }
  }
  return list;
}
