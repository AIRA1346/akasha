import 'package:akasha/utils/markdown_slash_commands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matchAtOffset finds slash on current line', () {
    const text = 'hello\n/시놉';
    final match = MarkdownSlashCommands.matchAtOffset(text, text.length);
    expect(match, isNotNull);
    expect(match!.query, '시놉');
    expect(match.candidates.any((c) => c.id == 'synopsis'), isTrue);
  });

  test('matchAtOffset returns null when line has space after command', () {
    const text = '/link foo';
    expect(MarkdownSlashCommands.matchAtOffset(text, 5), isNull);
  });

  test('matchAtOffset filters by partial query', () {
    const text = '/인';
    final match = MarkdownSlashCommands.matchAtOffset(text, text.length);
    expect(match, isNotNull);
    expect(
      match!.candidates.any((c) => c.id == 'quotes' || c.id == 'quote_line'),
      isTrue,
    );
  });
}
