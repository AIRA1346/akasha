import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/services/record_link_parser.dart';

void main() {
  group('RecordLinkParser', () {
    test('parses explicit id with label', () {
      const md = '감상: [[wk_000000001|에이티식스]] 재미있음';
      final links = RecordLinkParser.parseFromMarkdown(md);

      expect(links.length, 1);
      expect(links.first.kind, RecordLinkKind.explicitId);
      expect(links.first.targetEntityId, 'wk_000000001');
      expect(links.first.displayLabel, '에이티식스');
    });

    test('parses explicit id without label', () {
      const md = '참고 [[pe_u_abcd1234]]';
      final links = RecordLinkParser.parseFromMarkdown(md);

      expect(links.length, 1);
      expect(links.first.kind, RecordLinkKind.explicitId);
      expect(links.first.targetEntityId, 'pe_u_abcd1234');
      expect(links.first.displayLabel, isNull);
    });

    test('parses title-only wiki link', () {
      const md = 'Concept [[Tiger]] 메모';
      final links = RecordLinkParser.parseFromMarkdown(md);

      expect(links.length, 1);
      expect(links.first.kind, RecordLinkKind.titleOnly);
      expect(links.first.targetTitle, 'Tiger');
      expect(links.first.targetEntityId, isNull);
    });

    test('parses title-only with display label', () {
      const md = '[[Tiger|호랑이]]';
      final links = RecordLinkParser.parseFromMarkdown(md);

      expect(links.length, 1);
      expect(links.first.kind, RecordLinkKind.titleOnly);
      expect(links.first.targetTitle, 'Tiger');
      expect(links.first.displayLabel, '호랑이');
    });

    test('parses legacy work id as explicit', () {
      const md = '[[sub_manga_kimetsu-no-yaiba_2019]]';
      final links = RecordLinkParser.parseFromMarkdown(md);

      expect(links.length, 1);
      expect(links.first.kind, RecordLinkKind.explicitId);
      expect(links.first.targetEntityId, 'sub_manga_kimetsu-no-yaiba_2019');
    });

    test('ignores wiki links inside fenced code blocks', () {
      const md = '''
```md
[[pe_u_hidden01]]
```
본문 [[co_u_visible1]] OK
''';
      final links = RecordLinkParser.parseFromMarkdown(md);
      expect(links.length, 1);
      expect(links.first.targetEntityId, 'co_u_visible1');
    });

    test('parseFromRecordContent skips frontmatter', () {
      const content = '''---
entity_type: concept
entity_id: "co_u_front001"
record_kind: entityJournal
title: "Tiger"
added_at: "2026-06-19T10:00:00.000"
---
본문 [[pe_u_body0001|작가]]
''';

      final links = RecordLinkParser.parseFromRecordContent(content);
      expect(links.length, 1);
      expect(links.first.targetEntityId, 'pe_u_body0001');
    });

    test('parses multiple links in order', () {
      const md = '[[wk_000000001]] and [[Tiger]]';
      final links = RecordLinkParser.parseFromMarkdown(md);

      expect(links.length, 2);
      expect(links[0].kind, RecordLinkKind.explicitId);
      expect(links[1].kind, RecordLinkKind.titleOnly);
    });
  });
}
