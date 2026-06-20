import 'package:akasha/utils/entity_body_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityBodyPreview', () {
    test('returns trimmed body when within 120 chars', () {
      expect(EntityBodyPreview.format('  hello world  '), 'hello world');
      expect(EntityBodyPreview.format('a' * 120), 'a' * 120);
    });

    test('truncates to 120 chars with ellipsis', () {
      final long = 'b' * 150;
      final preview = EntityBodyPreview.format(long);
      expect(preview.length, 121);
      expect(preview, '${'b' * 120}…');
    });

    test('empty and whitespace-only bodies become empty', () {
      expect(EntityBodyPreview.format(''), '');
      expect(EntityBodyPreview.format('   \n  '), '');
    });
  });
}
