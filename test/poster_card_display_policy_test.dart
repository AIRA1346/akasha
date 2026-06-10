import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_card.dart';
import 'package:akasha/widgets/poster_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard cards do not build poster section widgets', (tester) async {
    final item = createItem(
      workId: 'wk_test_dashboard',
      title: '대시보드 테스트',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      posterPath: 'https://example.com/poster.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 140,
            child: PosterCard(item: item, showPoster: false),
          ),
        ),
      ),
    );

    expect(find.byType(PosterImage), findsNothing);
    expect(find.byType(CategoryPosterPlaceholder), findsNothing);
    expect(find.text('대시보드 테스트'), findsOneWidget);
  });

  testWidgets('personal library cards build user poster images', (tester) async {
    final item = createItem(
      workId: 'wk_test_library',
      title: '나만의 서재 테스트',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      posterPath: 'https://example.com/poster.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 320,
            child: PosterCard(item: item),
          ),
        ),
      ),
    );

    expect(find.byType(PosterImage), findsOneWidget);
  });
}
