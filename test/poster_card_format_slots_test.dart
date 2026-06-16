import 'package:akasha/models/enums.dart';
import 'package:akasha/models/format_slot.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/format_chip_row.dart';
import 'package:akasha/widgets/poster_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<FormatSlot> _manySlots() => [
      FormatSlot(
        workId: 'wk_manga',
        category: MediaCategory.manga,
        shortLabel: '만화',
        state: FormatSlotState.catalogOnly,
      ),
      FormatSlot(
        workId: 'wk_anime',
        category: MediaCategory.animation,
        shortLabel: '애니',
        state: FormatSlotState.catalogOnly,
      ),
      FormatSlot(
        workId: 'wk_ln',
        category: MediaCategory.book,
        shortLabel: '라노벨',
        state: FormatSlotState.catalogOnly,
      ),
      FormatSlot(
        workId: 'wk_game',
        category: MediaCategory.game,
        shortLabel: '게임',
        state: FormatSlotState.catalogOnly,
      ),
    ];

void main() {
  testWidgets('FormatChipRow keeps single line with +N overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: FormatChipRow(slots: _manySlots()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('만화'), findsOneWidget);
    expect(find.text('애니'), findsOneWidget);
    expect(find.text('라노벨'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(tester.getSize(find.byType(FormatChipRow)).height, FormatChipRow.rowHeight);
  });

  testWidgets('PosterCard fact layout does not overflow with many format slots',
      (tester) async {
    final item = createItem(
      workId: 'wk_franchise',
      title: 'Re:제로부터 시작하는 이세계 생활',
      category: MediaCategory.manga,
      creator: '長月達平',
      releaseYear: 2014,
      myStatus: ContentMyStatus.notStarted.label,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 176,
              height: 226,
              child: PosterCard(
                item: item,
                showPoster: false,
                formatSlots: _manySlots(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FormatChipRow), findsOneWidget);
  });

  testWidgets('PosterCard poster layout keeps rating and status on one row',
      (tester) async {
    final item = createItem(
      workId: 'wk_rezero',
      title: 'Re:제로부터 시작하는 이세계 생활',
      category: MediaCategory.manga,
      myStatus: ContentMyStatus.notStarted.label,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 176,
              height: 225,
              child: PosterCard(
                item: item,
                showPoster: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('⏳ 평가 대기'), findsOneWidget);
    expect(find.textContaining('볼 예정'), findsOneWidget);
    final ratingRow = tester.element(find.text('⏳ 평가 대기')).findAncestorWidgetOfExactType<Row>();
    final statusRow = tester
        .element(find.textContaining('볼 예정'))
        .findAncestorWidgetOfExactType<Row>();
    expect(ratingRow, isNotNull);
    expect(identical(ratingRow, statusRow), isTrue);
  });
}
