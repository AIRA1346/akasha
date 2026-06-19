import 'enums.dart';
import 'akasha_item.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 볼트 미연결 시 데모 샘플 (2작)
// ════════════════════════════════════════════════════════════════

List<AkashaItem> buildSampleData() {
  return [
    ContentItem(
      workId: 'sub_manga_shigatsu-wa-kimi-no-uso_2011',
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
      description:
          '피아노를 포기한 천재 소년 아리마 코세이가 자유분방한 바이올리니스트 미야조노 카오리를 만나 다시 음악과 마주하게 되는 이야기.',
      memorableQuotes: [
        '"모차르트가 위에서 말하고 있어. \'여행을 떠나자\'라고." — 미야조노 카오리 / 바이올린 콩쿠르',
        '"봄이 오면 너를 찾으러 갈 테니까." — 미야조노 카오리 / 편지',
      ],
      review:
          '마지막 편지를 읽는 순간 눈물이 멈추지 않았다. 카오리의 거짓말이 무엇이었는지 알게 되었을 때의 충격과 감동은 평생 갈 것 같다.',
    ),
    ContentItem(
      workId: 'sub_manga_86-eighty-six_2017',
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
  ];
}
