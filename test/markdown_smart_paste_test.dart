import 'package:akasha/utils/markdown_smart_paste.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeForBody strips yaml frontmatter', () {
    const raw = '''---
title: "테스트"
---

# 📝 메모
본문만''';

    final normalized = MarkdownSmartPaste.normalizeForBody(raw);
    expect(normalized, contains('# 📝 메모'));
    expect(normalized, isNot(contains('title:')));
  });

  test('normalizeForBody normalizes line endings', () {
    expect(
      MarkdownSmartPaste.normalizeForBody('a\r\nb\rc'),
      'a\nb\nc',
    );
  });
}
