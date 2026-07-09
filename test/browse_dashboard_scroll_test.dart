import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/home_section_preferences.dart';
import 'package:akasha/screens/home/views/browse_view.dart';
import 'package:akasha/screens/home/views/personal_library_view.dart';
import 'package:akasha/utils/browse_grid_metrics.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BrowseCard _card(String workId, String title) => BrowseCard(
      item: createItem(
        workId: workId,
        title: title,
        category: MediaCategory.manga,
        myStatus: ContentMyStatus.finished.label,
        workStatus: ContentWorkStatus.completed.label,
      ),
    );

int _verticalScrollableCount(WidgetTester tester) {
  var count = 0;
  for (final element in find.byType(Scrollable).evaluate()) {
    final scrollable = element.widget as Scrollable;
    if (scrollable.axis == Axis.vertical) {
      count++;
    }
  }
  return count;
}

void main() {
  testWidgets('BrowseView hides yearly section and uses one vertical scroll',
      (tester) async {
    final cards = List.generate(6, (i) => _card('wk_dash_$i', '작품 $i'));
    final sectionPrefs = HomeSectionPreferences();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: BrowseView(
              filteredCards: cards,
              sectionPrefs: sectionPrefs,
              filterCategories: const {},
              isCatalogLoading: false,
              displayName: '테스터',
              posterCardBuilder: (card) => SizedBox(
                height: 120,
                child: Text(card.item.title),
              ),
              onStateChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('연도별 라이브러리'), findsNothing);
    expect(_verticalScrollableCount(tester), 1);
  });

  testWidgets('PersonalLibraryView keeps yearly section', (tester) async {
    final cards = [_card('wk_lib_1', '서재 작품')];
    final sectionPrefs = HomeSectionPreferences();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: PersonalLibraryView(
              filteredCards: cards,
              allItems: const [],
              vaultLinked: false,
              sectionPrefs: sectionPrefs,
              displayName: '테스터',
              isCuratedLibraryActive: false,
              activeLibrary: null,
              posterCardBuilder: (card) => SizedBox(
                height: 120,
                child: Text(card.item.title),
              ),
              onStateChanged: () {},
              onCuratedReorder: (_, _, _) async {},
              onSearch: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('연도별 라이브러리'), findsOneWidget);
  });

  test('browseCardStableKey prefers workId', () {
    final card = _card('wk_stable', '제목');
    expect(browseCardStableKey(card), 'wk_stable');
  });

  test('BrowseGridMetrics resolves consistent cross axis count', () {
    final metrics = BrowseGridMetrics.resolve(
      maxWidth: 1200,
      cardMinWidth: 176,
      childAspectRatio: 0.78,
    );
    expect(metrics.crossAxisCount, greaterThanOrEqualTo(2));
  });
}
