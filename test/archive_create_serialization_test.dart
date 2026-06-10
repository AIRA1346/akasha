import 'package:akasha/models/enums.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serialize stores synopsis and memo in dedicated body sections', () {
    final item = createItem(
      workId: 'sub_manga_create_2024',
      title: '생성 테스트',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      memorableQuotes: ['"테스트 명대사"'],
      description: '유저가 적은 시놉시스',
      review: '개인 메모 본문',
      rating: 4.0,
    );

    final serialized = MarkdownParser.serialize(item);
    expect(serialized, contains('# 📋 시놉시스'));
    expect(serialized, contains('유저가 적은 시놉시스'));
    expect(serialized, contains('# 📝 메모'));
    expect(serialized, contains('개인 메모 본문'));
    expect(serialized, contains('> "테스트 명대사"'));

    final restored = MarkdownParser.deserialize(serialized, 'fallback');
    expect(restored.description, '유저가 적은 시놉시스');
    expect(restored.review, '개인 메모 본문');
    expect(restored.memorableQuotes, contains('"테스트 명대사"'));
  });

  test('deserialize still reads legacy review section as memo', () {
    const legacy = '''
---
work_id: "sub_manga_legacy_2020"
title: "레거시"
category: manga
domain: subculture
poster: ""
rating: 3.5
work_status: "완결"
status: "전부 봄"
my_status: "전부 봄"
is_hall_of_fame: false
tags: []
added_at: "2024-01-01T00:00:00.000"
---

# 📖 감상문
옛날 감상문 형식
''';

    final restored = MarkdownParser.deserialize(legacy, 'fallback');
    expect(restored.review, '옛날 감상문 형식');
  });
}
