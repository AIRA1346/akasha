import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/views/preview_record_view_model.dart';
import 'package:akasha/screens/home/views/preview_work_panel_content.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviewRecordViewModel', () {
    test('work core info rating uses five-point scale', () {
      final item = createItem(
        workId: 'wk_u_agnt0001',
        title: 'Agent Slice',
        category: MediaCategory.animation,
        rating: 4.5,
      );

      final model = PreviewRecordViewModel.fromWork(item);
      final ratingRow = model.coreInfoRows.last;

      expect(ratingRow.label, '평점');
      expect(ratingRow.valueWidget, isNotNull);
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

    testWidgets('core info rating row shows / 5 not / 10', (tester) async {
      final row = PreviewCoreInfoRow.rating(4.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PreviewRecordCoreInfoSection(rows: [row])),
        ),
      );

      expect(find.text(' / 5'), findsOneWidget);
      expect(find.text(' / 10'), findsNothing);
      expect(find.text('4.5'), findsOneWidget);
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
  });
}
