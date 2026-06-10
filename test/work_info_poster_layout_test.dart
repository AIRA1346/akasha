import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/workbench/work_detail_workspace.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('infoPosterDisplayBounds', () {
    test('fits 2:3 frame within max (width-first)', () {
      final bounds = infoPosterDisplayBounds(maxWidth: 280, maxHeight: 500);
      expect(bounds.width, 280);
      expect(bounds.height, 420);
    });

    test('clamps height and narrows width when vertical budget is tight', () {
      final bounds = infoPosterDisplayBounds(maxWidth: 280, maxHeight: 300);
      expect(bounds.height, 300);
      expect(bounds.width, closeTo(200, 0.01));
    });

    test('returns zero for non-positive constraints', () {
      final bounds = infoPosterDisplayBounds(maxWidth: 0, maxHeight: 100);
      expect(bounds.width, 0);
      expect(bounds.height, 0);
    });
  });

  testWidgets('work info panel reserves flex-weighted poster height', (tester) async {
    final item = createItem(
      workId: 'wk_test_poster_layout',
      title: '포스터 레이아웃 테스트',
      category: MediaCategory.animation,
      domain: AppDomain.subculture,
      posterPath: 'https://example.com/wide-key-visual.jpg',
      creator: 'Studio',
      releaseYear: 2022,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 700,
            child: WorkDetailWorkspace(
              item: item,
              tabId: 'tab-poster-layout',
              infoPanelWidth: 280,
              onSaved: (_) {},
              onDeleted: () {},
              onDirtyChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final posterFinder = find.byType(PosterImage);
    expect(posterFinder, findsOneWidget);

    final posterSize = tester.getSize(posterFinder);
    // 55% 예산·2:3 프레임 — 잘리지 않으면서 과도한 세로 여백 없음
    expect(posterSize.height, greaterThan(180));
    expect(posterSize.height, lessThan(400));
    expect(posterSize.width, greaterThan(180));

    final poster = tester.widget<PosterImage>(posterFinder);
    expect(poster.fit, BoxFit.contain);
  });
}
