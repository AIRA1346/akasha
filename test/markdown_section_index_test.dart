import 'package:akasha/services/markdown_body_merger.dart';
import 'package:akasha/utils/markdown_section_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseHeadings collects H1 sections', () {
    const text = '''# 📋 시놉시스
요약

# 🎵 OST 메모
트랙''';

    final sections = MarkdownSectionIndex.parseHeadings(text);
    expect(sections, hasLength(2));
    expect(sections[0].label, contains('시놉시스'));
    expect(sections[0].slotKind, MarkdownSlotKind.synopsis);
    expect(sections[1].label, contains('OST'));
    expect(sections[1].slotKind, isNull);
  });

  test('lineNumberAtOffset counts from one', () {
    const text = 'a\nb\nc';
    expect(MarkdownSectionIndex.lineNumberAtOffset(text, 0), 1);
    expect(MarkdownSectionIndex.lineNumberAtOffset(text, 2), 2);
    expect(MarkdownSectionIndex.lineNumberAtOffset(text, 4), 3);
  });

  test('sectionAtOffset returns heading before cursor', () {
    const text = '''# Alpha
one

# Beta
two''';

    final betaOffset = text.indexOf('two');
    final section = MarkdownSectionIndex.sectionAtOffset(text, betaOffset);
    expect(section?.label, 'Beta');
  });
}
