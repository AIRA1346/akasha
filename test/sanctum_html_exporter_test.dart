import 'package:akasha/models/enums.dart';
import 'package:akasha/models/sanctum_cast_entry.dart';
import 'package:akasha/models/sanctum_gallery_entry.dart';
import 'package:akasha/services/markdown_body_merger.dart';
import 'package:akasha/services/sanctum_html_exporter.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildHtml escapes user content and renders slots', () {
    final item = createItem(
      workId: 'wk_u_test01',
      title: '테스트 <작품>',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      creator: '작가 & 공동',
      releaseYear: 2024,
      rating: 4.5,
      posterPath: 'posters/cover.jpg',
    );

    const body = '''
${MarkdownBodyMerger.castHeading}
- [[pe_u_hero|주인공]] role:주연

${MarkdownBodyMerger.quotesHeading}
> "명대사 & 회상"
''';

    final html = SanctumHtmlExporter.buildHtml(
      title: item.title,
      item: item,
      bodyMarkdown: body,
    );

    expect(html, contains('&lt;작품&gt;'));
    expect(html, contains('작가 &amp; 공동'));
    expect(html, contains('class="wiki">주인공</span>'));
    expect(html, contains('&quot;명대사 &amp; 회상&quot;'));
    expect(html, contains('posters/cover.jpg'));
  });

  test('parseSlots round-trip matches gallery format in HTML', () {
    const galleryLine = SanctumGalleryEntry(
      imagePath: 'posters/scene.jpg',
      caption: '장면',
    ).toMarkdownLine();

    final slots = MarkdownBodyMerger.parseSlots('''
${MarkdownBodyMerger.galleryHeading}
$galleryLine
''');

    expect(slots.gallery, hasLength(1));
    expect(slots.gallery.first.imagePath, 'posters/scene.jpg');
  });
}
