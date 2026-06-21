import 'package:akasha/features/workbench/presentation/work_detail_workspace.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkDetailWorkspace builds for catalog-like item', (tester) async {
    final item = createItem(
      workId: 'wk_smoke_nav',
      title: 'Navigation Smoke',
      category: MediaCategory.manga,
      tags: const ['판타지', '액션'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 800,
            child: WorkDetailWorkspace(
              item: item,
              tabId: item.workId,
              infoPanelWidth: 280,
              onSaved: (_) {},
              onDeleted: () {},
              onDirtyChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Navigation Smoke'), findsAtLeastNWidgets(1));
    expect(find.text('태그'), findsOneWidget);
    expect(find.text('판타지'), findsOneWidget);
  });
}
