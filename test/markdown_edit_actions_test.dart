import 'package:akasha/services/markdown_body_merger.dart';
import 'package:akasha/utils/markdown_edit_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wrapSelection wraps highlighted text', () {
    const text = 'hello world';
    const selection = TextSelection(baseOffset: 0, extentOffset: 5);
    final patch = MarkdownEditActions.wrapSelection(
      text: text,
      selection: selection,
      left: '**',
      right: '**',
    );
    expect(patch.text, '**hello** world');
  });

  test('prefixLines adds blockquote to selected lines', () {
    const text = 'line one\nline two';
    const selection = TextSelection(baseOffset: 0, extentOffset: 13);
    final patch = MarkdownEditActions.prefixLines(
      text: text,
      selection: selection,
      prefix: '> ',
    );
    expect(patch.text, '> line one\n> line two');
  });

  test('insertSlotSection returns null when slot exists', () {
    const text = '# 📋 시놉시스\nalready';
    const selection = TextSelection.collapsed(offset: text.length);
    final patch = MarkdownEditActions.insertSlotSection(
      text: text,
      selection: selection,
      kind: MarkdownSlotKind.synopsis,
    );
    expect(patch, isNull);
  });

  test('insertSlotSection adds quotes with blockquote line', () {
    const text = '';
    const selection = TextSelection.collapsed(offset: 0);
    final patch = MarkdownEditActions.insertSlotSection(
      text: text,
      selection: selection,
      kind: MarkdownSlotKind.quotes,
    );
    expect(patch, isNotNull);
    expect(patch!.text, contains('# 🎬 명장면 & 명대사'));
    expect(patch.text, contains('> '));
  });

  test('bodyHasSlot detects memo headings', () {
    expect(
      MarkdownEditActions.bodyHasSlot(
        '# 📖 감상문\n내용',
        MarkdownSlotKind.memo,
      ),
      isTrue,
    );
    expect(
      MarkdownEditActions.bodyHasSlot(
        '# 🎵 OST 메모\n내용',
        MarkdownSlotKind.memo,
      ),
      isFalse,
    );
  });

  test('insertImage inserts markdown image syntax', () {
    const text = 'hello';
    const selection = TextSelection.collapsed(offset: 5);
    final patch = MarkdownEditActions.insertImage(
      text: text,
      selection: selection,
      imagePath: 'posters/test.jpg',
      alt: 'shot',
    );
    expect(patch.text, contains('![shot](posters/test.jpg)'));
  });
}
