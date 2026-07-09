import 'package:akasha/utils/markdown_find_replace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('findNext locates query after offset', () {
    const text = 'alpha beta alpha';
    expect(
      MarkdownFindReplace.findNext(
        text: text,
        query: 'alpha',
        fromOffset: 1,
      ),
      11,
    );
  });

  test('replaceAll replaces every match', () {
    const text = 'foo bar foo';
    final patch = MarkdownFindReplace.replaceAll(
      text: text,
      query: 'foo',
      replacement: 'baz',
    );
    expect(patch.text, 'baz bar baz');
  });
}
