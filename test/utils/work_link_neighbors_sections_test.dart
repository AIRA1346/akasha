import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/utils/work_link_neighbors.dart';
import 'package:akasha/widgets/work_link_neighbors_sections.dart';

void main() {
  testWidgets('WorkLinkNeighborsSections shows empty CTA for each section', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkLinkNeighborsSections(
            neighbors: WorkLinkNeighbors(),
          ),
        ),
      ),
    );

    expect(find.text('주요 인물'), findsOneWidget);
    expect(find.text('연결된 작품'), findsOneWidget);
    expect(find.text('관련 사건'), findsOneWidget);
    expect(find.text('관련 개념'), findsOneWidget);
    expect(find.textContaining('아직'), findsNWidgets(4));
  });
}
