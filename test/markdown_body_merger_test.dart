import 'package:akasha/features/workbench/presentation/work_detail_draft_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/sanctum_cast_entry.dart';
import 'package:akasha/models/sanctum_gallery_entry.dart';
import 'package:akasha/services/markdown_body_merger.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
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

# 🎬 명장면 & 명대사
> 슬로우 라이프

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

  test('parseSlots and mergeBody preserve trailing blank lines in memo', () {
    const body = '# 📝 메모\n내용\n\n\n';
    final slots = MarkdownBodyMerger.parseSlots(body);
    expect(slots.memo, '내용');

    final merged = MarkdownBodyMerger.mergeBody(
      bodyRaw: body,
      synopsis: slots.synopsis,
      quotes: slots.quotes,
      memo: slots.memo,
    );
    expect(merged, body);
  });

  test('serialize round-trip preserves trailing blank lines in memo slot', () {
    final item = createItem(
      workId: 'sub_manga_frieren_2020',
      title: '장송의 프리렌',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
    );
    item.bodyRaw = '# 📝 메모\n내용\n\n\n';
    WorkDetailDraftOps.syncBodyFromEditor(
      item,
      TextEditingController(text: item.bodyRaw),
    );

    final serialized = MarkdownParser.serialize(item);
    final restored = MarkdownParser.deserialize(serialized, 'fallback');

    expect(restored.bodyRaw, '# 📝 메모\n내용\n\n\n');
    expect(restored.review, '내용');
    expect(item.bodyRaw, '# 📝 메모\n내용\n\n\n');
  });

  test('serialize does not append extra trailing newline to body', () {
    final item = createItem(
      workId: 'wk_no_extra_nl',
      title: '줄바꿈',
      category: MediaCategory.manga,
    );
    item.bodyRaw = '# 📝 메모\n내용';

    final serialized = MarkdownParser.serialize(item);
    final bodyStart = serialized.indexOf('# 📝 메모');
    final body = serialized.substring(bodyStart).split('\n---').first;

    expect(body, '# 📝 메모\n내용');
    expect(MarkdownParser.deserialize(serialized, '줄바꿈').bodyRaw, '# 📝 메모\n내용');
  });

  group('MarkdownBodyMerger cast slot', () {
    test('parseSlots extracts cast entries with roles', () {
      const body = '''
# 👥 출연
- [[pe_u_alice|앨리스]] role:주인공
- [[pe_u_bob|밥]]

# 📝 메모
감상문
''';

      final slots = MarkdownBodyMerger.parseSlots(body);
      expect(slots.cast.length, 2);
      expect(slots.cast[0].entityId, 'pe_u_alice');
      expect(slots.cast[0].title, '앨리스');
      expect(slots.cast[0].role, '주인공');
      expect(slots.cast[1].entityId, 'pe_u_bob');
      expect(slots.memo, '감상문');
    });

    test('mergeBody round-trips cast without losing custom sections', () {
      const bodyRaw = '''
# 커스텀
메모 남김

# 👥 출연
- [[pe_u_alice|앨리스]] role:히로인
''';

      final merged = MarkdownBodyMerger.mergeBody(
        bodyRaw: bodyRaw,
        cast: const [
          SanctumCastEntry(
            entityId: 'pe_u_alice',
            title: '앨리스',
            role: '히로인',
          ),
          SanctumCastEntry(
            entityId: 'pe_u_bob',
            title: '밥',
          ),
        ],
        synopsis: '줄거리',
        quotes: const ['명대사'],
        memo: '감상',
      );

      final slots = MarkdownBodyMerger.parseSlots(merged);
      expect(slots.cast.length, 2);
      expect(slots.cast[1].title, '밥');
      expect(slots.synopsis, '줄거리');
      expect(slots.quotes, ['명대사']);
      expect(slots.memo, '감상');
      expect(merged, contains('# 커스텀'));
    });

    test('appends cast slot when missing', () {
      final merged = MarkdownBodyMerger.mergeBody(
        bodyRaw: '',
        cast: const [
          SanctumCastEntry(entityId: 'pe_u_x', title: '엑스'),
        ],
        synopsis: '',
        quotes: const [],
        memo: '',
      );

      expect(merged, contains(MarkdownBodyMerger.castHeading));
      expect(merged, contains('[[pe_u_x|엑스]]'));
    });
  });

  group('MarkdownBodyMerger gallery slot', () {
    test('parseSlots extracts gallery image lines', () {
      const body = '''
# 🖼 갤러리
- ![](posters/100_a.jpg)
- ![캡션](posters/200_b.png)

# 📝 메모
본문
''';

      final slots = MarkdownBodyMerger.parseSlots(body);
      expect(slots.gallery.length, 2);
      expect(slots.gallery[0].imagePath, 'posters/100_a.jpg');
      expect(slots.gallery[1].caption, '캡션');
      expect(slots.memo, '본문');
    });

    test('mergeBody round-trips gallery entries', () {
      final merged = MarkdownBodyMerger.mergeBody(
        bodyRaw: '',
        gallery: const [
          SanctumGalleryEntry(imagePath: 'posters/a.jpg'),
          SanctumGalleryEntry(
            imagePath: 'posters/b.jpg',
            caption: '장면',
          ),
        ],
        synopsis: '',
        quotes: const [],
        memo: '',
      );

      final slots = MarkdownBodyMerger.parseSlots(merged);
      expect(slots.gallery.length, 2);
      expect(slots.gallery[1].caption, '장면');
      expect(merged, contains(MarkdownBodyMerger.galleryHeading));
    });
  });
}
