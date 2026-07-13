import 'package:akasha/models/browse_entity_scope.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/home_browse_search_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeBrowseSearchChrome', () {
    test('hasActiveFilters detects scope and category selections', () {
      expect(
        HomeBrowseSearchChrome.hasActiveFilters(
          categories: const {},
          workStatuses: const {},
          myStatuses: const {},
          entityScope: BrowseEntityScope.all,
        ),
        isFalse,
      );
      expect(
        HomeBrowseSearchChrome.hasActiveFilters(
          categories: {MediaCategory.manga},
          workStatuses: const {},
          myStatuses: const {},
          entityScope: BrowseEntityScope.all,
        ),
        isTrue,
      );
      expect(
        HomeBrowseSearchChrome.hasActiveFilters(
          categories: const {},
          workStatuses: const {},
          myStatuses: const {},
          entityScope: BrowseEntityScope.person,
        ),
        isTrue,
      );
    });

    testWidgets('shows search first and hides filter chips by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBrowseSearchChrome(
              onSearch: () {},
              selectedCategories: const {},
              selectedWorkStatuses: const {},
              selectedMyStatuses: const {},
              onToggleCategory: (_) {},
              onClearCategories: () {},
              onToggleWorkStatus: (_) {},
              onToggleMyStatus: (_) {},
              selectedEntityScope: BrowseEntityScope.all,
              onEntityScopeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.text(HomeBrowseSearchChrome.searchPlaceholder),
        findsOneWidget,
      );
      expect(find.text('Ctrl K'), findsOneWidget);
      expect(find.text('매체 전체'), findsNothing);
    });

    testWidgets('filter button expands entity and media chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBrowseSearchChrome(
              onSearch: () {},
              selectedCategories: const {},
              selectedWorkStatuses: const {},
              selectedMyStatuses: const {},
              onToggleCategory: (_) {},
              onClearCategories: () {},
              onToggleWorkStatus: (_) {},
              onToggleMyStatus: (_) {},
              selectedEntityScope: BrowseEntityScope.all,
              onEntityScopeChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('필터'));
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('매체 전체'), findsOneWidget);
    });

    testWidgets('compact layout hides Ctrl K hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: HomeBrowseSearchChrome(
                  onSearch: () {},
                  selectedCategories: const {},
                  selectedWorkStatuses: const {},
                  selectedMyStatuses: const {},
                  onToggleCategory: (_) {},
                  onClearCategories: () {},
                  onToggleWorkStatus: (_) {},
                  onToggleMyStatus: (_) {},
                  selectedEntityScope: BrowseEntityScope.all,
                  onEntityScopeChanged: (_) {},
                  compactBreakpoint: 720,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ctrl K'), findsNothing);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });
}
