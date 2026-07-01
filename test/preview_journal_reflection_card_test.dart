import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/views/preview_journal_reflection_card.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviewJournalReflectionCard', () {
    testWidgets('shows minimal agent memo record', (tester) async {
      final item = createItem(
        workId: 'wk_u_agnt0001',
        title: 'Agent Slice',
        category: MediaCategory.animation,
        review: 'Agent A1 create — 최소 기록.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PreviewJournalReflectionCard(item: item)),
        ),
      );

      expect(find.text('내 감상'), findsOneWidget);
      expect(find.text('평가 없음'), findsOneWidget);
      expect(find.textContaining('Agent A1 create'), findsOneWidget);
    });

    testWidgets('shows empty memo hint when review is blank', (tester) async {
      final item = createItem(
        workId: 'wk_u_agnt0001',
        title: 'Agent Slice',
        category: MediaCategory.animation,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PreviewJournalReflectionCard(item: item)),
        ),
      );

      expect(find.text('평가 없음'), findsOneWidget);
      expect(find.textContaining('아직 메모가 없습니다'), findsOneWidget);
    });

    testWidgets('shows rating status tags and memo for full slice', (
      tester,
    ) async {
      final item = createItem(
        workId: 'wk_u_agnt0001',
        title: 'Agent Slice',
        category: MediaCategory.animation,
        rating: 4.5,
        myStatus: '전부 봄',
        tags: ['재미있음', '감동'],
        review: '2화부터 몰입됐다. 엔딩 크레딧까지 울컥.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PreviewJournalReflectionCard(item: item)),
        ),
      );

      expect(find.textContaining('Finished'), findsOneWidget);
      expect(find.text('#재미있음'), findsOneWidget);
      expect(find.text('#감동'), findsOneWidget);
      expect(find.textContaining('2화부터 몰입'), findsOneWidget);
      expect(find.text('평가 없음'), findsNothing);
    });
  });
}
