import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/workbench/work_detail_workspace.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('infoPosterDisplayBounds', () {
    test('uses full allocated rectangle (no 2:3 crop box)', () {
      final bounds = infoPosterDisplayBounds(maxWidth: 280, maxHeight: 135);
      expect(bounds.width, 280);
      expect(bounds.height, 135);
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
    // flex 3:2 + 헤더 제외 시 포스터 영역은 ~300px 이상이어야 함 (구 ~130px 잘림 방지)
    expect(posterSize.height, greaterThan(200));
    expect(posterSize.width, greaterThan(200));

    final poster = tester.widget<PosterImage>(posterFinder);
    expect(poster.fit, BoxFit.contain);
  });
}
