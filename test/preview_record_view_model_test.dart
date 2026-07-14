import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/views/preview_record_view_model.dart';
import 'package:akasha/screens/home/views/preview_work_panel_content.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviewRecordViewModel', () {
    test('work core info does not duplicate personal rating', () {
      final item = createItem(
        workId: 'wk_u_agnt0001',
        title: 'Agent Slice',
        category: MediaCategory.animation,
        rating: 4.5,
      );

      final model = PreviewRecordViewModel.fromWork(item);
      expect(model.coreInfoRows.map((row) => row.label), ['장르', '원작', '제작사']);
    });

    test('work hero uses a poster-shaped aspect ratio', () {
      final item = createItem(
        workId: 'wk_u_posterhero',
        title: 'Poster Hero',
        category: MediaCategory.manga,
      );

      final model = PreviewRecordViewModel.fromWork(item);

      expect(model.heroAspectRatio, closeTo(2 / 3, 0.001));
    });

    testWidgets('preview hero shows the whole poster without cropping', (
      tester,
    ) async {
      final item = createItem(
        workId: 'wk_u_previewhero',
        title: 'Preview Hero',
        category: MediaCategory.manga,
      );
      final model = PreviewRecordViewModel.fromWork(item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 320, child: PreviewRecordHero(model: model)),
          ),
        ),
      );

      final poster = tester.widget<PosterImage>(find.byType(PosterImage));
      expect(poster.fit, BoxFit.contain);
    });

    testWidgets(
      'compact preview hero keeps rail width but caps poster height',
      (tester) async {
        final item = createItem(
          workId: 'wk_u_compacthero',
          title: 'Compact Hero',
          category: MediaCategory.manga,
        );
        final model = PreviewRecordViewModel.fromWork(item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: PreviewRecordHero(model: model, compact: true),
              ),
            ),
          ),
        );

        final posterFinder = find.byType(PosterImage);
        final poster = tester.widget<PosterImage>(posterFinder);
        expect(poster.fit, BoxFit.cover);
        expect(tester.getSize(posterFinder), const Size(320, 300));
      },
    );
  });
}
