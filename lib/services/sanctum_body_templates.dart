import '../models/enums.dart';
import 'markdown_body_merger.dart';

/// Sanctum 본문 시작 템플릿 — 슬롯 헤딩 골격만 (기존 md 문법).
class SanctumBodyTemplate {
  const SanctumBodyTemplate({
    required this.id,
    required this.label,
    required this.description,
    required this.bodyMarkdown,
    this.categories = const [],
  });

  final String id;
  final String label;
  final String description;
  final String bodyMarkdown;
  final List<MediaCategory> categories;

  bool matchesCategory(MediaCategory category) {
    if (categories.isEmpty) return true;
    return categories.contains(category);
  }
}

abstract final class SanctumBodyTemplates {
  static const _blank = SanctumBodyTemplate(
    id: 'blank',
    label: '빈 기록',
    description: '출연·갤러리·시놉시스·명장면·감상 슬롯만 준비합니다.',
    bodyMarkdown: '''
${MarkdownBodyMerger.castHeading}

${MarkdownBodyMerger.galleryHeading}

${MarkdownBodyMerger.synopsisHeading}


${MarkdownBodyMerger.quotesHeading}
> 

${MarkdownBodyMerger.memoHeading}


''',
  );

  static const _anime = SanctumBodyTemplate(
    id: 'anime',
    label: '애니·영상',
    description: '출연·감상·명대사 중심 템플릿',
    categories: [MediaCategory.animation, MediaCategory.movie, MediaCategory.drama],
    bodyMarkdown: '''
${MarkdownBodyMerger.castHeading}

${MarkdownBodyMerger.galleryHeading}

${MarkdownBodyMerger.synopsisHeading}
한 줄 시놉시스를 적어 보세요.

${MarkdownBodyMerger.quotesHeading}
> 인상 깊었던 대사

${MarkdownBodyMerger.memoHeading}
감상·연출·음악 메모


''',
  );

  static const _manga = SanctumBodyTemplate(
    id: 'manga',
    label: '만화·웹툰',
    description: '회차·작화·캐릭터 메모용',
    categories: [MediaCategory.manga, MediaCategory.webtoon],
    bodyMarkdown: '''
${MarkdownBodyMerger.castHeading}

${MarkdownBodyMerger.synopsisHeading}
줄거리·설정 메모

${MarkdownBodyMerger.quotesHeading}
> 명장면 한 컷

${MarkdownBodyMerger.memoHeading}
연재 감상·회차 메모


''',
  );

  static const _game = SanctumBodyTemplate(
    id: 'game',
    label: '게임',
    description: '플레이 기록·공략 메모용',
    categories: [MediaCategory.game],
    bodyMarkdown: '''
${MarkdownBodyMerger.galleryHeading}

${MarkdownBodyMerger.synopsisHeading}
세계관·플랫폼·플레이 시간

${MarkdownBodyMerger.quotesHeading}
> 기억에 남는 장면

${MarkdownBodyMerger.memoHeading}
공략·엔딩·난이도 메모


''',
  );

  static const _novel = SanctumBodyTemplate(
    id: 'novel',
    label: '소설·책',
    description: '독서 감상 중심',
    categories: [MediaCategory.book],
    bodyMarkdown: '''
${MarkdownBodyMerger.synopsisHeading}
줄거리 요약 (스포 주의)

${MarkdownBodyMerger.quotesHeading}
> 인상 깊은 문장

${MarkdownBodyMerger.memoHeading}
독서 감상·추천 대상


''',
  );

  static const all = [_blank, _anime, _manga, _game, _novel];

  static List<SanctumBodyTemplate> forCategory(MediaCategory category) {
    final matched = all.where((t) => t.matchesCategory(category)).toList();
    if (matched.isEmpty) return [_blank];
    if (!matched.any((t) => t.id == 'blank')) {
      return [_blank, ...matched];
    }
    return matched;
  }

  static SanctumBodyTemplate? byId(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }
}
