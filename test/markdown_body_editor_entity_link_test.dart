import 'package:akasha/models/entity_link_selection.dart';
import 'package:akasha/widgets/markdown_body_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _expectedCanonical = '[[pe_u_natsuki1|나츠키 스바루]]';

void main() {
  testWidgets('Entity 연결 toolbar inserts canonical wiki token', (tester) async {
    const bodyText = '주인공';
    const expected = _expectedCanonical;
    final controller = TextEditingController(text: bodyText);
    addTearDown(controller.dispose);

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);

    var changed = false;
    String? capturedQuery;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: MarkdownBodyEditor(
              controller: controller,
              onChanged: () => changed = true,
              onRequestEntityLink: (context, selectedText) async {
                capturedQuery = selectedText;
                return const EntityLinkSelection(
                  entityId: 'pe_u_natsuki1',
                  title: '나츠키 스바루',
                  entityType: 'person',
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Entity 연결'));
    await tester.pumpAndSettle();

    expect(capturedQuery, bodyText);
    expect(controller.text, expected);
    expect(changed, isTrue);
  });

  testWidgets('Entity 연결 passes empty query when selection collapsed', (
    tester,
  ) async {
    const bodyText = 'hello ';
    final controller = TextEditingController(text: bodyText);
    addTearDown(controller.dispose);

    controller.selection = TextSelection.collapsed(offset: bodyText.length);

    String? capturedQuery;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: MarkdownBodyEditor(
              controller: controller,
              onChanged: () {},
              onRequestEntityLink: (context, selectedText) async {
                capturedQuery = selectedText;
                return const EntityLinkSelection(
                  entityId: 'pe_u_natsuki1',
                  title: '나츠키 스바루',
                  entityType: 'person',
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Entity 연결'));
    await tester.pumpAndSettle();

    expect(capturedQuery, '');
    expect(controller.text, 'hello $_expectedCanonical');
  });
}
