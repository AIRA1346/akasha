import 'package:akasha/models/enums.dart';
import 'package:akasha/services/markdown_body_merger.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergeBody preserves custom sections between slots', () {
    const bodyRaw = '''
# 📋 시놉시스
원본 시놉

# 🎵 OST 메모
- 1기 OP: YOASOBI

# 📝 메모
원본 메모
''';

    final merged = MarkdownBodyMerger.mergeBody(
      bodyRaw: bodyRaw,
      synopsis: '갱신된 시놉',
      quotes: const ['"명대사"'],
      memo: '갱신된 메모',
    );

    expect(merged, contains('# 🎵 OST 메모'));
    expect(merged, contains('YOASOBI'));
    expect(merged, contains('갱신된 시놉'));
    expect(merged, contains('갱신된 메모'));
    expect(merged, contains('> "명대사"'));
  });

  test('serialize round-trip keeps custom section after app save', () {
    final item = createItem(
      workId: 'sub_manga_frieren_2020',
      title: '장송의 프리렌',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      description: '시놉',
      review: '메모',
      memorableQuotes: const ['슬로우 라이프'],
    );
    item.bodyRaw = '''
# 📋 시놉시스
시놉

# 🎵 OST 메모
커스텀 섹션 유지

# 📝 메모
메모
''';

    final serialized = MarkdownParser.serialize(item);
    expect(serialized, contains('# 🎵 OST 메모'));
    expect(serialized, contains('커스텀 섹션 유지'));

    final restored = MarkdownParser.deserialize(serialized, 'fallback');
    expect(restored.bodyRaw, contains('커스텀 섹션 유지'));
    expect(restored.description, '시놉');
    expect(restored.review, '메모');
    expect(restored.memorableQuotes, contains('슬로우 라이프'));
  });

  test('parseSlots reads legacy review heading as memo', () {
    const body = '''
# 📖 감상문
옛날 감상문
''';
    final slots = MarkdownBodyMerger.parseSlots(body);
    expect(slots.memo, '옛날 감상문');
  });

  test('appends missing slot sections when bodyRaw empty', () {
    final merged = MarkdownBodyMerger.mergeBody(
      bodyRaw: '',
      synopsis: '새 시놉',
      quotes: const ['인용'],
      memo: '새 메모',
    );
    expect(merged, contains('# 📋 시놉시스'));
    expect(merged, contains('# 🎬 명장면 & 명대사'));
    expect(merged, contains('# 📝 메모'));
  });
}
