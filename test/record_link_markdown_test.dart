import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/services/record_link_markdown.dart';

void main() {
  group('RecordLinkMarkdown', () {
    test('preprocess converts wiki links to akasha-wiki href', () {
      const md = '참고 [[pe_u_abcd1234|작가]] 메모';
      final out = RecordLinkMarkdown.preprocessForDisplay(md);

      expect(out, contains('[작가](akasha-wiki:'));
      expect(out, isNot(contains('[[')));
    });

    test('linkFromTapHref round-trips explicit id with label', () {
      final md = RecordLinkMarkdown.preprocessForDisplay(
        '[[wk_000000001|에이티식스]]',
      );
      final match = RegExp(r'\((akasha-wiki:[^)]+)\)').firstMatch(md);
      expect(match, isNotNull);

      final link = RecordLinkMarkdown.linkFromTapHref(match!.group(1));
      expect(link, isNotNull);
      expect(link!.kind, RecordLinkKind.explicitId);
      expect(link.targetEntityId, 'wk_000000001');
      expect(link.displayLabel, '에이티식스');
    });

    test('linkFromTapHref round-trips title-only', () {
      final md = RecordLinkMarkdown.preprocessForDisplay('[[Tiger]]');
      final match = RegExp(r'\((akasha-wiki:[^)]+)\)').firstMatch(md);

      final link = RecordLinkMarkdown.linkFromTapHref(match!.group(1));
      expect(link?.kind, RecordLinkKind.titleOnly);
      expect(link?.targetTitle, 'Tiger');
    });

    test('preprocess does not alter plain markdown links', () {
      const md = '[Google](https://google.com)';
      expect(RecordLinkMarkdown.preprocessForDisplay(md), md);
    });
  });
}
