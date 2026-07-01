import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_continue_section.dart';
import 'package:akasha/services/recent_exploration_resolver.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserCatalog implements UserCatalogPort {
  @override
  List<UserCatalogEntity> get all => const [];

  @override
  Stream<void> get onChanged => const Stream.empty();

  @override
  Future<void> load() async {}

  @override
  UserCatalogEntity? getById(String entityId) => null;

  @override
  Future<void> remove(String entityId) async {}

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) => const [];

  @override
  Future<void> upsert(UserCatalogEntity entity) async {}
}

List<AkashaItem> _sampleItems(int count) {
  return List.generate(
    count,
    (index) => createItem(
      workId: 'wk_continue_$index',
      title: '작품 $index',
      category: MediaCategory.animation,
      domain: AppDomain.subculture,
    ),
  );
}

Widget _wrap({required List<AkashaItem> items, double width = 480}) {
  return MaterialApp(
    theme: AkashaTheme.dark(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: HomeDashboardContinueSection(
            recentExploreItems: items,
            selectedPreviewItem: null,
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('resolveRecentExplorationItems defaults to home display limit', () {
    final keys = List.generate(20, (index) => 'work:wk_continue_$index');
    final vault = _sampleItems(20);

    final resolved = resolveRecentExplorationItems(
      itemKeys: keys,
      vaultItems: vault,
      userCatalog: _FakeUserCatalog(),
    );

    expect(resolved.length, homeContinueExploreDisplayLimit);
  });

  group('HomeDashboardContinueSection', () {
    testWidgets('shows up to twelve cards and can scroll to the last one', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(items: _sampleItems(12), width: 480));
      await tester.pumpAndSettle();

      expect(find.text('작품 0'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);

      var nextButton = find.byTooltip('다음');
      while (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        nextButton = find.byTooltip('다음');
      }

      expect(find.text('작품 11'), findsAtLeastNWidgets(1));
      expect(find.byTooltip('다음'), findsNothing);
      expect(find.byTooltip('이전'), findsOneWidget);
    });

    testWidgets('hides scroll buttons when all cards fit', (tester) async {
      await tester.pumpWidget(_wrap(items: _sampleItems(3), width: 900));
      await tester.pumpAndSettle();

      expect(find.byTooltip('다음'), findsNothing);
      expect(find.byTooltip('이전'), findsNothing);
    });

    testWidgets('shows next button when cards overflow', (tester) async {
      await tester.pumpWidget(_wrap(items: _sampleItems(8), width: 480));
      await tester.pumpAndSettle();

      expect(find.byTooltip('다음'), findsOneWidget);
      expect(find.byTooltip('이전'), findsNothing);
    });

    testWidgets('next button scrolls rail and reveals previous button', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(items: _sampleItems(8), width: 480));
      await tester.pumpAndSettle();

      final listFinder = find.byType(Scrollable).first;
      final scrollable = tester.widget<Scrollable>(listFinder);
      final controller = scrollable.controller!;
      expect(controller.offset, 0);

      await tester.tap(find.byTooltip('다음'));
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0));
      expect(find.byTooltip('이전'), findsOneWidget);
    });
  });
}
