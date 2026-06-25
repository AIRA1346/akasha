import 'package:akasha/services/markdown_body_merger.dart';
import 'package:akasha/services/sanctum_archive_completion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('archive completion counts five slots at 20% each', () {
    const body = '''
${MarkdownBodyMerger.castHeading}
- [[person_1|주인공]] role:주연

${MarkdownBodyMerger.synopsisHeading}
줄거리

${MarkdownBodyMerger.quotesHeading}
> 명대사
''';

    final report = SanctumArchiveCompletion.evaluate(bodyRaw: body);
    expect(report.percent, 60);
    expect(report.filledCount, 3);
    expect(report.totalCount, 5);
  });

  test('full slots yield 100%', () {
    const body = '''
${MarkdownBodyMerger.castHeading}
- [[person_1|A]]

${MarkdownBodyMerger.galleryHeading}
- ![](posters/a.jpg)

${MarkdownBodyMerger.synopsisHeading}
s

${MarkdownBodyMerger.quotesHeading}
> q

${MarkdownBodyMerger.memoHeading}
m
''';

    final report = SanctumArchiveCompletion.evaluate(bodyRaw: body);
    expect(report.percent, 100);
  });
}
