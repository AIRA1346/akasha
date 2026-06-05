import 'enums.dart';
import 'akasha_item.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 초기 샘플 데이터 (옵시디언 스크린샷 기반 - workId 필드 추가)
// ════════════════════════════════════════════════════════════════

List<AkashaItem> buildSampleData() => [
      // ── 만화 ──────────────────────────────

      ContentItem(
        workId: 'shigatsu_2011',
        title: '4월은 너의 거짓말',
        category: MediaCategory.manga,
        creator: '아라카와 나오시 (Naoshi Arakawa)',
        releaseYear: 2011,
        rating: 5.0,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        isHallOfFame: true,
        tags: ['감동', '음악', '청춘', '피아노'],
        description: '피아노를 포기한 천재 소년 아리마 코세이가 자유분방한 바이올리니스트 미야조노 카오리를 만나 다시 음악과 마주하게 되는 이야기. 음악과 청춘의 아름다움, 그리고 상실의 아픔을 섬세하게 그린 명작.',
        memorableQuotes: [
          '"모차르트가 위에서 말하고 있어. \'여행을 떠나자\'라고." — 미야조노 카오리 / 바이올린 콩쿠르',
          '"봄이 오면 너를 찾으러 갈 테니까." — 미야조노 카오리 / 편지',
          '"나는 너가 있었기에 여기까지 올 수 있었어." — 아리마 코세이',
        ],
        review: '단순한 음악 만화라 생각하고 시작했지만, 마지막 편지를 읽는 순간 눈물이 멈추지 않았다. 카오리의 거짓말이 무엇이었는지 알게 되었을 때의 충격 and 감동은 아직도 가슴 한켠에 남아있다.',
      ),

      ContentItem(
        workId: 'onepiece_1997',
        title: '원피스',
        category: MediaCategory.manga,
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
          '"살고 싶다!!!!" — 니코 로빈 / 에니에스 로비',
        ],
        review: '27년이 넘는 연재 기간 동안 한 번도 식지 않은 열정. 모든 복선이 연결되는 순간의 쾌감은 어떤 작품에서도 느낄 수 없다.',
      ),

      ContentItem(
        workId: 'demonslayer_2016',
        title: '귀멸의 칼날',
        category: MediaCategory.manga,
        creator: '고토게 코요하루 (Koyoharu Gotouge)',
        releaseYear: 2016,
        rating: 5.0,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        isHallOfFame: true,
        tags: ['액션', '가족애', '귀신', '다이쇼'],
        description: '가족을 귀신에게 잃고 유일하게 살아남은 여동생마저 귀신이 되어버린 소년 카마도 탄지로가 여동생을 인간으로 되돌리기 위해 귀살대에 입대하는 이야기.',
        memorableQuotes: [
          '"생살여탈의 권을 쥐고 있는 건 항상 나다!" — 키부츠지 무잔',
          '"머리가 안 좋으니까 설명을 못하지만, 마음은 뜨거우니까!" — 렌고쿠 쿄쥬로',
        ],
        review: '애니메이션 ufo table의 작화와 함께 사회현상급 인기를 끌었던 작품. 무한열차편은 극장에서 3번 울었다.',
      ),

      ContentItem(
        workId: 'shingeki_2009',
        title: '진격의 거인',
        category: MediaCategory.manga,
        creator: '이사야마 하지메 (Hajime Isayama)',
        releaseYear: 2009,
        rating: 5.0,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        isHallOfFame: true,
        tags: ['SF', '전쟁', '자유', '반전'],
        description: '거대한 벽 안에서 살아가던 인류가 벽 너머의 거인과 맞서 싸우는 이야기. 후반부로 갈수록 드러나는 세계관의 스케일과 전복적 반전이 압도적.',
        memorableQuotes: [
          '"그날, 인류는 떠올렸다. 그들에게 지배당했던 공포를... 새장 속에 갇혀 있었던 굴욕을..." — 내레이션 / 1화',
          '"싸워. 싸우지 않으면 이길 수 없어." — 에렌 예거',
        ],
        review: '처음엔 단순한 거인 vs 인류 구도인 줄 알았는데, 마레 편부터 완전히 다른 이야기가 되었다. 역대급 스토리텔링.',
      ),

      ContentItem(
        workId: 'eightysix_2017',
        title: '86 -에이티식스-',
        category: MediaCategory.manga,
        creator: '아사토 아사토 (Asato Asato)',
        releaseYear: 2017,
        rating: 5.0,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.finished,
        tags: ['SF', '전쟁', '차별', '밀리터리'],
        description: '공화국의 전쟁에서 "사상자 제로"라는 프로파간다 뒤에 숨겨진 진실 — 인간으로 취급받지 못하는 86구역 출신 소년병들의 이야기.',
        memorableQuotes: [
          '"우리는 사람이야. 돼지가 아니야. 우리에겐 이름이 있어." — 신에이 노우젠',
        ],
        review: '라이트 노벨 원작의 무거운 주제 의식이 돋보이는 작품. 애니메이션의 연출도 압도적.',
      ),

      ContentItem(
        workId: 'gabriel_2013',
        title: '가브릴 드롭아웃',
        category: MediaCategory.manga,
        creator: '우카미 (Ukami)',
        releaseYear: 2013,
        rating: 4.0,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.finished,
        tags: ['코미디', '일상', '천사', '악마'],
        description: '천사학교를 수석 졸업한 가브릴이 인간 세계에 내려온 후 온라인 게임에 빠져 타락해가는 이야기. 천사인데 악마보다 악질인 일상 코미디.',
        memorableQuotes: [
          '"공부하기 싫어... 게임하고 싶어..." — 텐마 가브릴 화이트',
        ],
        review: '머리 비우고 보기 딱 좋은 힐링 코미디. 사타니치아가 너무 귀여움.',
      ),

      ContentItem(
        workId: 'chainsawman_2018',
        title: '체인소 맨',
        category: MediaCategory.manga,
        creator: '후지모토 타츠키 (Tatsuki Fujimoto)',
        releaseYear: 2018,
        rating: 4.5,
        workStatus: ContentWorkStatus.serializing,
        myStatus: ContentMyStatus.watching,
        tags: ['액션', '다크', '악마', '카오스'],
        description: '가난한 소년 덴지가 체인소의 악마 포치타와 합체하여 체인소 맨이 되는 이야기. 예측불가의 전개와 파격적인 연출이 특징.',
        memorableQuotes: [
          '"나의 꿈은... 여자 껴안는 거야!" — 덴지',
        ],
        review: '후지모토 타츠키의 천재성이 폭발하는 작품. 1부 마지막은 진짜 입이 벌어졌다.',
      ),

      ContentItem(
        workId: 'naruto_1999',
        title: '나루토',
        category: MediaCategory.manga,
        creator: '키시모토 마사시 (Masashi Kishimoto)',
        releaseYear: 1999,
        rating: 4.5,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        tags: ['액션', '닌자', '우정', '성장'],
        description: '외톨이 닌자 소년 우즈마키 나루토가 마을 최고의 닌자 호카게가 되기 위해 성장해 나가는 이야기.',
        memorableQuotes: [
          '"나는 말이야, 절대 내 닌자도를 굽히지 않아. 그것이 나의 닌자도니까!" — 우즈마키 나루토',
          '"이 눈에는... 잘 보인다고." — 우치하 이타치',
        ],
        review: '어린 시절의 추억이 가득한 작품. 이타치의 진실 편은 소년만화 역사상 최고의 반전.',
      ),

      ContentItem(
        workId: 'jujutsukaisen_2018',
        title: '주술회전',
        category: MediaCategory.manga,
        creator: '아쿠타미 게게 (Gege Akutami)',
        releaseYear: 2018,
        rating: 4.5,
        workStatus: ContentWorkStatus.completed,
        myStatus: ContentMyStatus.finished,
        tags: ['액션', '다크판타지', '주술', '배틀'],
        description: '주술사와 저주의 세계를 그린 다크 판타지 배틀 만화. 시부야 사변 이후 급변하는 전개가 인상적.',
        memorableQuotes: [
          '"괜찮아. 나는 가장 강하니까." — 고조 사토루',
        ],
        review: '고조 사토루라는 캐릭터 하나로 문화가 된 작품. 전투 장면의 연출이 압도적.',
      ),

      // ── 게임 ──────────────────────────────

      GameItem(
        workId: 'minecraft_2011',
        title: '마인크래프트',
        creator: 'Mojang Studios',
        releaseYear: 2011,
        rating: 5.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.playing,
        isHallOfFame: true,
        tags: ['샌드박스', '서바이벌', '크래프팅', '멀티플레이'],
        description: '무한한 복셀 세계에서 자원을 채취하고 건축하며 자유롭게 모험하는 궁극의 샌드박스 게임. 전 세계에서 가장 많이 팔린 게임.',
        memorableQuotes: [
          '"The End?" — 엔더 드래곤 처치 후 엔딩 크레딧',
        ],
        review: '끝이 없는 게임. 친구들과 멀티플레이 서버에서 보낸 수백 시간이 내 최고의 게이밍 메모리.',
      ),

      GameItem(
        workId: 'lol_2009',
        title: '리그 오브 레전드',
        creator: 'Riot Games',
        releaseYear: 2009,
        rating: 4.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.playing,
        tags: ['MOBA', 'PvP', 'e스포츠', '팀전'],
        description: '5v5 팀 기반 전략 대전 게임. 전 세계 최대 규모의 e스포츠 종목 중 하나.',
        review: '사랑과 증오가 공존하는 게임. 이기면 인생게임, 지면 삭제 예정.',
      ),

      GameItem(
        workId: 'axiom_game',
        title: '엑시옴',
        creator: '인디 제작사',
        workStatus: GameWorkStatus.earlyAccess,
        myStatus: GameMyStatus.backlog,
        tags: ['인디', '얼리액세스'],
        description: '얼리액세스 단계의 기대작.',
      ),

      GameItem(
        workId: 'eldenring_2022',
        title: '엘든 링',
        creator: 'FromSoftware',
        releaseYear: 2022,
        rating: 5.0,
        workStatus: GameWorkStatus.released,
        myStatus: GameMyStatus.cleared,
        isHallOfFame: true,
        tags: ['소울라이크', '오픈월드', 'RPG', '다크판타지'],
        description: '미야자키 히데타카와 조지 R.R. 마틴의 세계관이 결합된 오픈월드 액션 RPG. 광대한 사이 사이에 숨겨진 비밀과 도전이 가득.',
        memorableQuotes: [
          '"나는 Malenia, 미켈라의 칼날. 지금까지 한번도 패배한 적이 없다." — Malenia',
        ],
        review: '소울 시리즈의 정수를 오픈월드에 완벽하게 녹여냈다. 첫 플레이 170시간, DLC 포함 250시간.',
      ),
    ];
