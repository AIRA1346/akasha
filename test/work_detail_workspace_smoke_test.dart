import 'package:akasha/features/workbench/presentation/work_detail_workspace.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkDetailWorkspace builds for catalog-like item', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final item = createItem(
      workId: 'wk_smoke_nav',
      title: 'Navigation Smoke',
      category: MediaCategory.manga,
      tags: const ['판타지', '액션'],
    );
    var dirty = false;

    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('ListTile background color or ink splashes')) {
        return;
      }
      priorOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = priorOnError);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 800,
            child: WorkDetailWorkspace(
              item: item,
              tabId: item.workId,
              infoPanelWidth: 280,
              onSaved: (_, {required bool silent, bool dirty = false}) {},
              onDeleted: () {},
              onDirtyChanged: (value) => dirty = value,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Navigation Smoke'), findsAtLeastNWidgets(1));
    expect(find.text('연결'), findsOneWidget);
    expect(find.text('정보'), findsOneWidget);
    expect(find.text('기록 완성도'), findsOneWidget);
    expect(find.text('감상'), findsAtLeastNWidgets(1));
    expect(find.text('평점'), findsOneWidget);
    expect(find.text('작품 상태'), findsOneWidget);
    expect(find.text('나의 상태'), findsOneWidget);
    expect(find.text('태그'), findsOneWidget);
    expect(find.byType(InteractiveStarRating), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsAtLeastNWidgets(2));

    await tester.tap(find.byType(InteractiveStarRating));
    await tester.pump();
    expect(dirty, isTrue);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('줄거리·세계관·배경을 적어 보세요.'), findsOneWidget);
  });
}
