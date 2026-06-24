import 'package:akasha/models/enums.dart';
import 'package:akasha/features/workbench/presentation/work_detail_poster_layout.dart';
import 'package:akasha/features/workbench/presentation/work_detail_workspace.dart';
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
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
              onSaved: (_, {required bool silent, bool dirty = false}) {},
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
    // 좌측 패널 30% 예산·2:3 프레임 (기본 테스트 뷰포트 1400×900)
    expect(posterSize.height, greaterThan(100));
    expect(posterSize.height, lessThan(220));
    expect(posterSize.width, greaterThan(100));

    final poster = tester.widget<PosterImage>(posterFinder);
    expect(poster.fit, BoxFit.contain);
  });
}
